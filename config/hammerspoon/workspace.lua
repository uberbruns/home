--[[
  Hyper-key driven app launcher with automatic tiling.

  The system resolves each hyper keystroke to a shorthand — either an app
  or a split. When the same app appears consecutively, the system merges
  those shorthands into one and sums their weights. A split shorthand
  breaks this merging but does not produce a tile itself.

  While hyper is held, shorthands accumulate in a queue without any
  activation or tiling. The system processes the full queue when the
  user releases hyper.

  On hyper release with a combo (multiple apps or repeated shorthand):
  - The system memorizes the combo and tiles all participants.
  - Windows are raised back to front to establish z-order, with the
    finally focused app receiving keyboard input.

  On hyper release with a single shorthand (a poke):
  - If the poked app belongs to the current combo and is already focused,
    the system cycles its windows without retiling.
  - If the poked app belongs to the current combo but is not focused,
    the system activates it without retiling.
  - If the poked app is a leader of another memorized combo (priority 1),
    the system replays that combo — pruning any apps no longer in
    the app stack before tiling.
  - If the poked app is a peer in another memorized combo (priority 2),
    the system replays that combo with the poked app finally focused.
  - If the most-front app matches the poke, the system cycles
    through its windows by focusing the backmost one.
  - Otherwise the system activates the poked app without tiling.

  Tiling layout:
  - The system selects the target screen from the leader app's main
    window, falling back to the initially focused window, then the main screen.
  - Each tile receives one of its app's windows. The last tile for
    each app collects any remaining windows.
  - The system drops tiles whose app has no available windows.
  - The system positions tiles left to right, then activates apps from
    last to leader. The finally focused app activates last to receive
    keyboard input. The finally focused app is the first tiled app that
    was not initially focused, or the leader as fallback.

  Glossary:
  - app stack: a z-ordered list of bundle IDs derived from visible windows
  - combo: a memorized list of merged shorthands that tile horizontally
  - combo stack: an ordered list of memorized combos (most recent last)
  - current combo: the most recently tiled or replayed combo; its members
    are activated directly without triggering a combo replay
  - keystroke: a single hyper key-press that produces an unresolved shorthand
  - leader app: the first app in a combo
  - peer app: a non-leader app in a combo
  - poke: a single-app activation produced by one shorthand on hyper release
  - shorthand: a resolved intent carrying a type, bundle ID, and weight
  - tile: a shorthand bound to an app and its assigned windows
  - weight: a proportional share of screen width
]]

--------------------------------------------------
-- Requirements
--------------------------------------------------

local hyperkey = require("hyperkey")

--------------------------------------------------
-- Configuration
--------------------------------------------------

local HYPER_MODIFIERS = { "cmd", "alt", "ctrl", "shift" }

local ShorthandType = {
  app = "app",
  unresolved = "unresolved",
  split = "split",
}

--------------------------------------------------
-- Logging
--------------------------------------------------

local function log(msg)
  print("[workspace] " .. msg)
end

local function appName(bundleID)
  if not bundleID then return "nil" end
  return bundleID:match("%.([^%.]+)$") or bundleID
end

local function windowDesc(window)
  if not window then return "nil" end
  local title = window:title() or ""
  if #title > 25 then title = title:sub(1, 22) .. "..." end
  return string.format("#%d(%s)", window:id() or 0, title)
end

local function windowListDesc(windows)
  local parts = {}
  for _, w in ipairs(windows) do table.insert(parts, windowDesc(w)) end
  return "[" .. table.concat(parts, ", ") .. "]"
end

local function shorthandDesc(shorthand)
  if shorthand.type == ShorthandType.split then return "|" end
  return appName(shorthand.id) .. "×" .. shorthand.weight
end

local function shorthandListDesc(shorthands)
  local parts = {}
  for _, s in ipairs(shorthands) do table.insert(parts, shorthandDesc(s)) end
  return table.concat(parts, " ")
end

--------------------------------------------------
-- State
--------------------------------------------------

local buildFocusedWindow = nil -- focused window captured at start of combo building
local comboStack = {}          -- ordered list of memorized combos (most recent last)
local currentCombo = nil       -- the most recently tiled or replayed combo
local registeredApps = {}
local registeredKeystrokes = {}
local shorthandQueue = {}

--------------------------------------------------
-- App Helpers
--------------------------------------------------

-- Returns the z-ordered list of bundle IDs from all visible windows (front to back).
local function appStack()
  local stack = {}
  local seen = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    local bundleID = window:application():bundleID()
    if bundleID and not seen[bundleID] then
      seen[bundleID] = true
      table.insert(stack, bundleID)
    end
  end
  return stack
end

-- Cycles through an app's windows by focusing its backmost window.
local function cycleWindows(ctx)
  local appWindows = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    if window:application() == ctx.poke.app then
      table.insert(appWindows, window)
    end
  end
  log("cycleWindows: " .. appName(ctx.poke.app:bundleID()) .. " windows=" .. windowListDesc(appWindows))
  if #appWindows > 1 then
    log("cycleWindows: focusing backmost " .. windowDesc(appWindows[#appWindows]))
    appWindows[#appWindows]:focus()
  end
end

-- Returns the app for a bundle ID, launching and unhiding it if needed.
local function launchOrGetApp(bundleID)
  local app = hs.application.get(bundleID)
  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
    app = hs.application.get(bundleID)
  end
  if app and app:isHidden() then
    app:unhide()
  end
  return app
end

--------------------------------------------------
-- Shorthand Resolution
--------------------------------------------------

-- Resolves consecutive unresolved shorthands into app shorthands by longest-prefix matching.
-- Splits pass through unchanged since they are already resolved.
local function resolveShorthands(shorthands)
  local resolved = {}
  local index = 1

  while index <= #shorthands do
    local shorthand = shorthands[index]

    if shorthand.type ~= ShorthandType.unresolved then
      table.insert(resolved, shorthand)
      index = index + 1
    else
      -- Collect consecutive keystrokes
      local letters = ""
      for i = index, #shorthands do
        if shorthands[i].type ~= ShorthandType.unresolved then break end
        letters = letters .. shorthands[i].id
      end

      -- Match longest prefix against registered apps
      local matched = false
      for tryLength = #letters, 1, -1 do
        local registration = registeredApps[letters:sub(1, tryLength)]
        if registration then
          table.insert(resolved, {
            id = registration.bundleID,
            type = ShorthandType.app,
            weight = registration.defaultWeight,
          })
          index = index + tryLength
          matched = true
          break
        end
      end

      if not matched then
        index = index + 1
      end
    end
  end

  return resolved
end

-- Merges consecutive shorthands with the same type and ID, summing weights.
local function mergeShorthands(shorthands)
  if #shorthands == 0 then return {} end

  local merged = {}
  local current = {
    id = shorthands[1].id,
    type = shorthands[1].type,
    weight = shorthands[1].weight,
  }

  for i = 2, #shorthands do
    local shorthand = shorthands[i]
    local isMergeable = current.type ~= ShorthandType.split
        and shorthand.type ~= ShorthandType.split
        and shorthand.type == current.type
        and shorthand.id == current.id

    if isMergeable then
      current.weight = current.weight + shorthand.weight
    else
      table.insert(merged, current)
      current = { id = shorthand.id, type = shorthand.type, weight = shorthand.weight }
    end
  end

  table.insert(merged, current)
  return merged
end

--------------------------------------------------
-- Tiling
--------------------------------------------------

-- Converts merged shorthands into tiles, launching apps as needed.
local function buildTiles(mergedShorthands)
  local tiles = {}
  for _, shorthand in ipairs(mergedShorthands) do
    if shorthand.type ~= ShorthandType.split then
      local app = launchOrGetApp(shorthand.id)
      if app then
        table.insert(tiles, { app = app, weight = shorthand.weight })
      end
    end
  end
  return tiles
end

-- Distributes each app's standard windows across its tiles (last tile gets remaining).
local function assignWindowsToTiles(tiles)
  -- Collect windows and count tiles per app
  local windowsByBundle = {}
  local tileCountByBundle = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    if not windowsByBundle[bundleID] then
      local windows = {}
      for _, w in ipairs(tile.app:allWindows()) do
        if w:isStandard() then table.insert(windows, w) end
      end
      windowsByBundle[bundleID] = windows
    end
    tileCountByBundle[bundleID] = (tileCountByBundle[bundleID] or 0) + 1
  end

  -- Assign windows: one per tile, last tile gets remaining
  local result = {}
  local nextIndexByBundle = {}
  local assignedCountByBundle = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    local windows = windowsByBundle[bundleID]
    local nextIndex = nextIndexByBundle[bundleID] or 1
    local assignedCount = (assignedCountByBundle[bundleID] or 0) + 1
    assignedCountByBundle[bundleID] = assignedCount

    if nextIndex <= #windows then
      local isLastTile = assignedCount == tileCountByBundle[bundleID]
      local tileWindows = {}
      if isLastTile then
        for i = nextIndex, #windows do
          table.insert(tileWindows, windows[i])
        end
        nextIndexByBundle[bundleID] = #windows + 1
      else
        table.insert(tileWindows, windows[nextIndex])
        nextIndexByBundle[bundleID] = nextIndex + 1
      end

      table.insert(result, {
        app = tile.app,
        weight = tile.weight,
        windows = tileWindows,
      })
    end
  end

  return result
end

-- Positions tiles left-to-right, dividing screen width by weight.
local function positionTiles(screenFrame, tiles)
  local totalWeight = 0
  for _, tile in ipairs(tiles) do
    totalWeight = totalWeight + tile.weight
  end

  local offset = 0
  for _, tile in ipairs(tiles) do
    local normalizedWeight = tile.weight / totalWeight

    for _, window in ipairs(tile.windows) do
      local width = screenFrame.w * normalizedWeight
      local x = screenFrame.x + screenFrame.w * offset
      window:setFrame(hs.geometry.rect(x, screenFrame.y, width, screenFrame.h), 0)
    end

    offset = offset + normalizedWeight
  end
end

-- Resolves which app should be finally focused after tiling.
local function resolveFinallyFocusedApp(tiles, initialFocusedWindow, finallyFocusedBundleID)
  -- Explicit target: find the matching app
  if finallyFocusedBundleID then
    for _, tile in ipairs(tiles) do
      if tile.app:bundleID() == finallyFocusedBundleID then
        return tile.app
      end
    end
  end

  -- Default: first app that differs from the initially focused one
  local initialFocusedBundleID = initialFocusedWindow and initialFocusedWindow:application():bundleID()
  for _, tile in ipairs(tiles) do
    if tile.app:bundleID() ~= initialFocusedBundleID then
      return tile.app
    end
  end

  -- Fall back to leader app if all belong to the initially focused app
  if #tiles > 0 then return tiles[1].app end
end

-- Resolves the target screen from tiles or falls back to the currently focused/main screen.
local function resolveTargetScreen(tiles)
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then return mainWindow:screen() end
  end

  local currentlyFocusedWindow = hs.window.focusedWindow()
  if currentlyFocusedWindow then return currentlyFocusedWindow:screen() end

  return hs.screen.mainScreen()
end

-- Assigns windows to tiles and positions them proportionally on the target screen.
-- Activates apps from last to leader; the finally focused app activates last.
local function applyTiling(ctx)
  local targetScreen = resolveTargetScreen(ctx.tiles)
  local screenFrame = targetScreen:frame()

  local tilesWithWindows = assignWindowsToTiles(ctx.tiles)
  if #tilesWithWindows == 0 then
    log("applyTiling: no tiles with windows")
    return
  end

  local finallyFocusedApp = resolveFinallyFocusedApp(tilesWithWindows, ctx.initialFocusedWindow,
    ctx.finallyFocusedBundleID)

  -- Log tile assignments
  for i, tile in ipairs(tilesWithWindows) do
    log("applyTiling: tile " .. i .. " " .. appName(tile.app:bundleID())
      .. " weight=" .. tile.weight .. " windows=" .. windowListDesc(tile.windows))
  end
  log("applyTiling: finallyFocusedApp=" .. (finallyFocusedApp and appName(finallyFocusedApp:bundleID()) or "nil")
    .. " initialFocusedWindow=" .. windowDesc(ctx.initialFocusedWindow))

  -- Position windows in their tile frames
  positionTiles(screenFrame, tilesWithWindows)

  -- Activate apps from last to leader to establish z-order; the finally focused app
  -- activates last so it ends up on top with keyboard input.
  for i = #tilesWithWindows, 1, -1 do
    local tile = tilesWithWindows[i]
    if not finallyFocusedApp or tile.app:bundleID() ~= finallyFocusedApp:bundleID() then
      log("applyTiling: activating " .. appName(tile.app:bundleID()))
      tile.app:activate(true)
      hs.timer.usleep(16000 * 3)
    end
  end
  if finallyFocusedApp then
    log("applyTiling: finally activating " .. appName(finallyFocusedApp:bundleID()))
    finallyFocusedApp:activate(true)
  end
end

--------------------------------------------------
-- Combo Stack
--------------------------------------------------

-- Returns the bundle ID of the first app shorthand (the leader), or nil.
local function leaderBundleID(combo)
  for _, shorthand in ipairs(combo) do
    if shorthand.type == ShorthandType.app and shorthand.id then
      return shorthand.id
    end
  end
end

-- Returns the set of all app bundle IDs in a combo.
local function collectBundleIDs(combo)
  local ids = {}
  for _, shorthand in ipairs(combo) do
    if shorthand.type == ShorthandType.app and shorthand.id then
      ids[shorthand.id] = true
    end
  end
  return ids
end

-- Pushes a combo onto the stack, removing any existing combo with the same leader.
local function memorizeCombo(ctx)
  local leader = leaderBundleID(ctx.shorthands)
  if not leader then return end

  -- Prune existing combos with the same leader
  local pruned = {}
  for _, combo in ipairs(comboStack) do
    if leaderBundleID(combo) ~= leader then
      table.insert(pruned, combo)
    end
  end

  table.insert(pruned, ctx.shorthands)
  comboStack = pruned
end

-- Searches the combo stack for a combo matching the given bundle ID.
-- Returns the combo and its stack index, checking leader matches (priority 1)
-- before peer matches (priority 2). Searches from top of stack (most recent).
local function findComboForBundle(bundleID)
  -- Priority 1: leader match (most recent first)
  for i = #comboStack, 1, -1 do
    if leaderBundleID(comboStack[i]) == bundleID then
      return comboStack[i], i
    end
  end

  -- Priority 2: peer match (most recent first)
  for i = #comboStack, 1, -1 do
    local ids = collectBundleIDs(comboStack[i])
    if ids[bundleID] then
      return comboStack[i], i
    end
  end
end

--------------------------------------------------
-- Combo Replay
--------------------------------------------------

-- Replays a memorized combo from a single-app keystroke on hyper release.
-- Tiles all combo participants and focuses the triggering app.
-- Prunes apps that are no longer present in the app stack.
local function replayCombo(ctx)
  local combo = ctx.poke.associatedCombo
  log("replayCombo: bundleID=" .. appName(ctx.poke.bundleID)
    .. " combo=[" .. shorthandListDesc(combo) .. "]")

  -- Prune apps no longer in the app stack (always keep the triggering app)
  local currentStack = appStack()
  local stackSet = {}
  for _, id in ipairs(currentStack) do stackSet[id] = true end

  local prunedCombo = {}
  for _, shorthand in ipairs(combo) do
    if shorthand.type == ShorthandType.split or shorthand.id == ctx.poke.bundleID or stackSet[shorthand.id] then
      table.insert(prunedCombo, shorthand)
    end
  end

  local tiles = buildTiles(prunedCombo)
  local isStillCombo = #tiles >= 2 or (#tiles == 1 and tiles[1].weight > 1)

  log("replayCombo: pruned=[" .. shorthandListDesc(prunedCombo) .. "] tiles=" .. #tiles .. " isStillCombo=" .. tostring(isStillCombo))

  -- Update or remove the combo from the stack
  if isStillCombo then
    comboStack[ctx.poke.associatedComboIndex] = prunedCombo
  else
    table.remove(comboStack, ctx.poke.associatedComboIndex)
    log("replayCombo: removed combo from stack")
  end

  -- Fall back to simple activation if the combo is no longer meaningful
  if not isStillCombo then
    log("replayCombo: → fallback activate " .. appName(ctx.poke.bundleID))
    local app = launchOrGetApp(ctx.poke.bundleID)
    if app then app:activate(true) end
    return
  end

  -- Tile the combo with focus on the triggering app
  currentCombo = prunedCombo
  log("replayCombo: → tiling " .. #tiles .. " tiles, focused=" .. appName(ctx.poke.bundleID))
  applyTiling({
    tiles                  = tiles,
    initialFocusedWindow   = ctx.initialFocusedWindow,
    finallyFocusedBundleID = ctx.poke.bundleID,
  })
end

--------------------------------------------------
-- Queue Processing
--------------------------------------------------

-- Resolves the shorthand queue and the initially focused window into a context
-- that captures all facts needed to decide what action to perform.
--
-- Fields:
--   initialFocusedWindow  — the window that held focus when the first shorthand was enqueued
--   initialFocusedBundleID — the bundle ID of the initially focused window's application, or nil
--   shorthands            — the resolved and merged shorthand list
--   combo                 — combo details when a combo was formed, otherwise nil
--     .tiles              — the tiles built from the shorthands
--   poke                  — poke details when isPoke is true, otherwise nil
--     .app                — the app being poked
--     .bundleID           — the bundle ID of poke.app
--     .isInCurrentCombo   — true when the poked app belongs to the most recently tiled combo
--     .associatedCombo      — the memorized combo containing the poked app, or nil
--     .associatedComboIndex — the index of poke.associatedCombo in the combo stack, or nil
local function buildContext(shorthands, initialFocusedWindow)
  local mergedShorthands = mergeShorthands(resolveShorthands(shorthands))
  local tiles = buildTiles(mergedShorthands)
  local isCombo = #tiles >= 2 or (#tiles == 1 and tiles[1].weight > 1)
  local pokeApp = nil
  if not isCombo and #tiles == 1 then pokeApp = tiles[1].app end
  local pokeBundleID = pokeApp and pokeApp:bundleID() or nil
  local pokeCombo, pokeComboIndex = findComboForBundle(pokeBundleID)

  return {
    initialFocusedWindow   = initialFocusedWindow,
    initialFocusedBundleID = initialFocusedWindow and initialFocusedWindow:application():bundleID() or nil,
    shorthands             = mergedShorthands,
    combo                  = isCombo and {
      tiles = tiles,
    } or nil,
    poke                   = pokeApp and {
      app                  = pokeApp,
      bundleID             = pokeBundleID,
      isInCurrentCombo     = pokeBundleID and currentCombo and collectBundleIDs(currentCombo)[pokeBundleID] or false,
      associatedCombo      = pokeCombo,
      associatedComboIndex = pokeComboIndex,
    } or nil,
  }
end

-- Cycles through the poked app's windows when it is already focused.
-- The system restores the combo because the user is staying within it.
local function pokeFocusedAppInCurrentCombo(ctx)
  currentCombo = ctx.poke.associatedCombo
  cycleWindows(ctx)
end

-- Activates the poked app when it is not yet focused, without retiling.
-- The system restores the combo because the user is moving between its apps.
local function pokeUnfocusedAppInCurrentCombo(ctx)
  currentCombo = ctx.poke.associatedCombo
  ctx.poke.app:activate(true)
end

-- Pokes an app: focuses it within the current combo, replays a memorized
-- combo, cycles its windows, or activates it directly.
local function pokeApp(ctx)
  if ctx.poke.isInCurrentCombo then
    if ctx.poke.bundleID == ctx.initialFocusedBundleID then
      log("pokeApp: → cycle windows in current combo")
      pokeFocusedAppInCurrentCombo(ctx)
    else
      log("pokeApp: → activate unfocused app in current combo")
      pokeUnfocusedAppInCurrentCombo(ctx)
    end
  elseif ctx.poke.associatedCombo then
    log("pokeApp: → replay memorized combo")
    replayCombo(ctx)
  elseif ctx.poke.bundleID == ctx.initialFocusedBundleID then
    log("pokeApp: → cycle app windows")
    cycleWindows(ctx)
  else
    log("pokeApp: → activate app")
    ctx.poke.app:activate(true)
  end
end

-- Processes the shorthand queue on hyper release or immediate (non-hyper) input.
-- Handles combos (memorize + tile), single-app pokes, window cycling, and activation.
local function processQueue()
  local initialFocusedWindow = buildFocusedWindow or hs.window.focusedWindow()
  buildFocusedWindow = nil

  if #shorthandQueue == 0 then return end

  -- Invalidate the current combo if the initially focused app is no longer a member.
  if currentCombo then
    local initialBundleID = initialFocusedWindow and initialFocusedWindow:application():bundleID()
    if not initialBundleID or not collectBundleIDs(currentCombo)[initialBundleID] then
      currentCombo = nil
    end
  end

  -- Snapshot and clear queue, then build the context for this activation.
  local shorthands = shorthandQueue
  shorthandQueue = {}
  local ctx = buildContext(shorthands, initialFocusedWindow)
  currentCombo = nil

  local combo = ctx.combo
  local poke = ctx.poke
  log("processQueue: shorthands=[" .. shorthandListDesc(ctx.shorthands) .. "]"
    .. " tiles=" .. (combo and #combo.tiles or 0)
    .. " isCombo=" .. tostring(combo ~= nil)
    .. " poke=" .. appName(poke and poke.bundleID)
    .. " initialFocusedBundleID=" .. appName(ctx.initialFocusedBundleID)
    .. " pokeIsInCurrentCombo=" .. tostring(poke and poke.isInCurrentCombo or false)
    .. " comboMatch=" .. (poke and poke.associatedCombo and ("stack[" .. poke.associatedComboIndex .. "]") or "nil"))

  if combo then
    memorizeCombo(ctx)
    currentCombo = ctx.shorthands
    log("processQueue: → tiling combo")
    applyTiling({ tiles = combo.tiles, initialFocusedWindow = ctx.initialFocusedWindow })
  elseif ctx.poke then
    pokeApp(ctx)
  end
end

-- Appends a shorthand to the queue and starts polling for hyper release.
-- The system always defers processing to the release callback to ensure
-- modifier keys are fully released before activating apps.
local function enqueueShorthand(shorthand)
  table.insert(shorthandQueue, shorthand)
  log("enqueueShorthand: " .. shorthandDesc(shorthand) .. " queueSize=" .. #shorthandQueue)

  hyperkey.startPolling()
  if #shorthandQueue == 1 then
    buildFocusedWindow = hs.window.focusedWindow()
    log("enqueueShorthand: captured buildFocusedWindow=" .. windowDesc(buildFocusedWindow))
  end
end

--------------------------------------------------
-- Public API
--------------------------------------------------

local M = {}

--- Registers an app shortcut for multi-keystroke tiling activation.
--- Each letter in the shortcut is bound as a hyper hotkey.
function M.registerApp(shortcut, bundleID, defaultWeight)
  registeredApps[shortcut] = { bundleID = bundleID, defaultWeight = defaultWeight or 1 }

  for i = 1, #shortcut do
    local letter = shortcut:sub(i, i)

    if not registeredKeystrokes[letter] then
      registeredKeystrokes[letter] = true

      hs.hotkey.bind(HYPER_MODIFIERS, letter, function()
        enqueueShorthand({ id = letter, type = ShorthandType.unresolved, weight = 1 })
      end)
    end
  end
end

--- Binds a hyper key to insert a split into the shorthand queue.
--- Splits prevent merging of adjacent app shorthands.
function M.setSplitKey(key)
  hs.hotkey.bind(HYPER_MODIFIERS, key, function()
    enqueueShorthand({ id = nil, type = ShorthandType.split, weight = 1 })
  end)
end

--------------------------------------------------
-- Initialization
--------------------------------------------------

hyperkey.onRelease(function() processQueue() end)

return M
