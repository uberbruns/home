--[[
  Hyper-key driven app launcher with automatic tiling.

  The system resolves each hyper keystroke to a shorthand — either an app
  or a split. When the same app appears consecutively, the system merges
  those shorthands into one and sums their weights. A split shorthand
  breaks this merging but does not produce a tile itself.

  The system handles input in two phases, depending on when hyper
  is released:

  While hyper is held (combo building):
  - The first shorthand preactivates its app for responsiveness.
  - A repeated shorthand or multiple distinct shorthands form a combo.
    The system memorizes the combo and tiles its apps immediately.
  - Each additional shorthand causes the system to update the combo
    memorized under the leader app and re-tile all apps. Forming a
    combo does not affect other memorized combos.
  - When the user finally releases hyper, nothing further happens
    because tiling already occurred.

  On hyper release with a single shorthand (combo replay):
  - If the app is a peer of the last activated combo, the system
    focuses it without replaying any combo — even if the app is a
    leader of another combo.
  - If the app is a leader of a memorized combo, the system replays
    the combo — pruning any apps no longer in the app stack before
    tiling.
  - If the app is already focused and not a leader, the system
    cycles through its windows by focusing the backmost one.
  - Otherwise the system activates the app without tiling.
  - Combo replay is the only path that restores a memorized combo
    from a single keystroke.

  Tiling layout:
  - The system selects the target screen from the leader app's main
    window, falling back to the focused window, then the main screen.
  - Each tile receives one of its app's windows. The last tile for
    each app collects any remaining windows.
  - The system drops tiles whose app has no available windows.
  - The system raises individual tile windows back-to-front to establish
    z-order, then activates only the focused app for keyboard input.
    This avoids intermediate app activations whose windows would cover
    peer app tiles.
  - Focus returns to the initially focused window if it was tiled.
    Otherwise the leader app receives focus.

  Glossary:
  - app stack: a z-ordered list of bundle IDs derived from visible windows
  - combo: a memorized list of merged shorthands, keyed by leader app, that tile horizontally
  - keystroke: a single hyper key-press that produces an unresolved shorthand
  - leader app: the first app in a combo
  - peer app: a non-leader app in a combo
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

local HYPER_MODIFIERS = {"cmd", "alt", "ctrl", "shift"}

local ShorthandType = {
  app = "app",
  unresolved = "unresolved",
  split = "split",
}

--------------------------------------------------
-- State
--------------------------------------------------

local buildFocusedWindow = nil   -- focused window captured at start of combo building
local buildPhase = nil           -- nil | "preactivated" | "tiled"
local lastActivatedPeers = {}    -- set of peer bundle IDs from the last activated combo
local memorizedCombos = {}       -- list of combos, each a list of merged shorthands
local registeredApps = {}
local registeredKeystrokes = {}
local shorthandQueue = {}

--------------------------------------------------
-- App Helpers
--------------------------------------------------

-- Cycles through an app's windows by focusing its backmost window.
local function cycleWindows(app)
  local appWindows = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    if window:application() == app then
      table.insert(appWindows, window)
    end
  end
  if #appWindows > 1 then
    appWindows[#appWindows]:focus()
  end
end

-- Returns the app for a bundle ID, launching it if not running.
local function launchOrGetApp(bundleID)
  local app = hs.application.get(bundleID)
  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
    app = hs.application.get(bundleID)
  end
  return app
end

-- Returns true if all hyper modifier keys are currently pressed.
local function isHyperHeld()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.alt and flags.cmd and flags.ctrl and flags.shift
end

-- Returns all standard windows for an app.
local function standardWindows(app)
  local windows = {}
  for _, window in ipairs(app:allWindows()) do
    if window:isStandard() then
      table.insert(windows, window)
    end
  end
  return windows
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
      windowsByBundle[bundleID] = standardWindows(tile.app)
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

    if nextIndex > #windows then goto continue end

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

    ::continue::
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

-- Resolves which app should receive focus after tiling.
local function resolveFocussedApp(tiles, initialFocusedWindow, focussedBundleID)
  -- Explicit target: find the matching app
  if focussedBundleID then
    for _, tile in ipairs(tiles) do
      if tile.app:bundleID() == focussedBundleID then
        return tile.app
      end
    end
  end

  -- Default: first app that differs from the initially focused one
  local initialBundleID = initialFocusedWindow and initialFocusedWindow:application():bundleID()
  for _, tile in ipairs(tiles) do
    if tile.app:bundleID() ~= initialBundleID then
      return tile.app
    end
  end

  -- Fall back to leader app if all belong to the initially focused app
  if #tiles > 0 then return tiles[1].app end
end

-- Resolves the target screen from tiles or falls back to focused/main screen.
local function resolveTargetScreen(tiles)
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then return mainWindow:screen() end
  end

  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow then return focusedWindow:screen() end

  return hs.screen.mainScreen()
end

-- Assigns windows to tiles and positions them proportionally on the target screen.
-- Raises individual tile windows back-to-front to establish z-order without
-- activating entire apps, then activates only the focused app for keyboard input.
local function applyTiling(tiles, initialFocusedWindow, opts)
  local targetScreen = resolveTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  local tilesWithWindows = assignWindowsToTiles(tiles)
  if #tilesWithWindows == 0 then return end

  local focussedBundleID = opts and opts.focussedBundleID
  local focussedApp = resolveFocussedApp(tilesWithWindows, initialFocusedWindow, focussedBundleID)

  positionTiles(screenFrame, tilesWithWindows)

  hs.timer.doAfter(0.01, function()
    -- Raise tile windows back-to-front so each tile sits above the next
    for i = #tilesWithWindows, 1, -1 do
      for _, window in ipairs(tilesWithWindows[i].windows) do
        window:raise()
      end
    end

    -- Activate only the focused app for keyboard input
    if focussedApp then focussedApp:activate(true) end
  end)
end

--------------------------------------------------
-- Combo Memorization
--------------------------------------------------

-- Returns the memorized combo for which bundleID is the leader, or nil.
-- Peer apps do not trigger combo replay.
local function findCombo(bundleID)
  return memorizedCombos[bundleID]
end

-- Extracts the set of peer (non-leader) bundle IDs from a combo.
local function peerBundleIDs(combo)
  local peers = {}
  local isLeader = true
  for _, shorthand in ipairs(combo) do
    if shorthand.type == ShorthandType.app and shorthand.id then
      if isLeader then
        isLeader = false
      else
        peers[shorthand.id] = true
      end
    end
  end
  return peers
end

-- Memorizes a combo keyed by its leader app's bundle ID.
-- Forming a new combo does not modify other memorized combos.
local function memorizeCombo(newCombo)
  for _, shorthand in ipairs(newCombo) do
    if shorthand.type == ShorthandType.app and shorthand.id then
      memorizedCombos[shorthand.id] = newCombo
      return
    end
  end
end

--------------------------------------------------
-- App Stack
--------------------------------------------------

-- Returns the app stack: z-ordered list of bundle IDs from all visible windows (front to back).
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

--------------------------------------------------
-- Combo Replay
--------------------------------------------------

-- Replays a memorized combo from a single-app keystroke on hyper release.
-- Tiles all combo participants and focuses the triggering app.
-- Prunes apps that are no longer present in the app stack.
local function replayCombo(combo, bundleID, initialFocusedWindow)
  -- Prune apps no longer in the app stack (always keep the triggering app)
  local currentStack = appStack()
  local stackSet = {}
  for _, id in ipairs(currentStack) do stackSet[id] = true end

  local prunedCombo = {}
  for _, shorthand in ipairs(combo) do
    if shorthand.type == ShorthandType.split or shorthand.id == bundleID or stackSet[shorthand.id] then
      table.insert(prunedCombo, shorthand)
    end
  end

  -- Find leader from the original combo and count remaining apps
  local leaderID = nil
  for _, shorthand in ipairs(combo) do
    if shorthand.type == ShorthandType.app and shorthand.id then
      leaderID = shorthand.id
      break
    end
  end

  local appCount = 0
  for _, shorthand in ipairs(prunedCombo) do
    if shorthand.type == ShorthandType.app then appCount = appCount + 1 end
  end

  -- Update or remove the stored combo
  if leaderID then
    if appCount >= 2 then
      memorizedCombos[leaderID] = prunedCombo
    else
      memorizedCombos[leaderID] = nil
    end
  end

  -- Fall back to simple activation if the combo is no longer meaningful
  if appCount < 2 then
    local app = launchOrGetApp(bundleID)
    if app then
      hs.timer.doAfter(0.1, function() app:activate(true) end)
    end
    return
  end

  -- Tile the combo with the triggering app focussed
  lastActivatedPeers = peerBundleIDs(prunedCombo)
  local tiles = buildTiles(prunedCombo)
  hs.timer.doAfter(0.1, function()
    applyTiling(tiles, initialFocusedWindow, {
      focussedBundleID = bundleID,
    })
  end)
end

--------------------------------------------------
-- Combo Building
--------------------------------------------------

-- Builds a combo while hyper is held (called on each new input).
-- Single app without prior phase: preactivates for responsiveness.
-- Combo (repeated keystroke or multiple apps): memorizes and tiles immediately.
local function updateComboBuilding()
  local resolved = resolveShorthands(shorthandQueue)
  local mergedShorthands = mergeShorthands(resolved)
  local tiles = buildTiles(mergedShorthands)
  local isCombo = #tiles >= 2 or (#tiles == 1 and tiles[1].weight > 1)

  if isCombo then
    memorizeCombo(mergedShorthands)
    lastActivatedPeers = peerBundleIDs(mergedShorthands)
    applyTiling(tiles, buildFocusedWindow)
    buildPhase = "tiled"
  elseif #tiles == 1 and not buildPhase then
    tiles[1].app:activate()
    buildPhase = "preactivated"
  end
end

--------------------------------------------------
-- Queue Processing
--------------------------------------------------

-- Processes the shorthand queue on hyper release or immediate (non-hyper) input.
-- Combos built while held are already tiled; this handles single-app replay or activation.
local function processQueue()
  -- Reset combo building session
  local initialFocusedWindow = buildFocusedWindow or hs.window.focusedWindow()
  local wasTiled = buildPhase == "tiled"
  buildFocusedWindow = nil
  buildPhase = nil

  if #shorthandQueue == 0 then return end

  -- Snapshot and clear queue
  local shorthands = shorthandQueue
  shorthandQueue = {}

  -- Combo was already tiled during combo building
  if wasTiled then return end

  -- Single app: cycle windows if already focused, replay combo, or activate
  local mergedShorthands = mergeShorthands(resolveShorthands(shorthands))
  local tiles = buildTiles(mergedShorthands)

  if #tiles == 1 then
    local app = tiles[1].app
    local bundleID = app:bundleID()
    local initialBundleID = initialFocusedWindow and initialFocusedWindow:application():bundleID()

    if lastActivatedPeers[bundleID] then
      hs.timer.doAfter(0.1, function()
        app:activate(true)
      end)
    else
      local combo = findCombo(bundleID)
      if combo then
        replayCombo(combo, bundleID, initialFocusedWindow)
      elseif bundleID == initialBundleID then
        cycleWindows(app)
      else
        hs.timer.doAfter(0.1, function()
          app:activate(true)
        end)
      end
    end
  end
end

-- Appends a shorthand (unresolved or split) to the queue. While hyper is
-- held, the system builds the combo. On release (or without hyper), the
-- system drains the queue via processQueue.
local function enqueueShorthand(shorthand)
  table.insert(shorthandQueue, shorthand)

  if isHyperHeld() then
    hyperkey.startPolling()
    if not buildFocusedWindow then
      buildFocusedWindow = hs.window.focusedWindow()
    end
    updateComboBuilding()
  else
    processQueue()
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
