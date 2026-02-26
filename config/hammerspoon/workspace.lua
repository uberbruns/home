--[[
  Hyper-key driven app launcher with automatic tiling layout.

  Queuing Rules:
  - Actions accumulate while hyper is held
  - Actions process immediately when hyper is not held
  - Consecutive actions with same bundle ID merge, summing weights
  - Split actions break merging without producing tiles

  Layout Rules:
  - Single action on release: replay memorized action sequence containing the app
    if available, otherwise raise all windows; the activated app retains focus
  - Repeated shorthand: creates a single-app action sequence with the summed weight
  - Multiple actions while held: memorize action sequence and tile immediately;
    each additional action re-memorizes and re-tiles
  - Hyper release after action sequence layout is a no-op
  - Target screen: first app's main window > focused window > main screen
  - Windows distribute one per tile; last tile receives remaining windows
  - Tiles with no available windows are dropped
  - Focus restores to the initially focused window if tiled,
    otherwise the first app's main window receives focus

  Memorization Rules:
  - Multi-app layouts are memorized as action sequences
  - Each action sequence stores merged actions including splits

  Glossary:
  - action: queued intent with a type, bundle ID, and weight
  - action sequence: memorized merged actions (including splits) that are tiled horizontally
  - tile: resolved action bound to an app and its assigned windows
  - weight: proportional share of screen width
]]

--------------------------------------------------
-- Requirements
--------------------------------------------------

local hyperkey = require("hyperkey")

--------------------------------------------------
-- Configuration
--------------------------------------------------

local HYPER_MODIFIERS = {"cmd", "alt", "ctrl", "shift"}

local ActionType = {
  focusOrLayout = "focusOrLayout",
  letter = "letter",
  split = "split",
}

--------------------------------------------------
-- State
--------------------------------------------------

local actionQueue = {}
local eagerFocusedWindow = nil  -- focused window captured at start of hyper session
local eagerPhase = nil           -- nil | "preactivated" | "laid_out"
local memorizedActionSequences = {}    -- list of action sequences, each a list of merged actions
local registeredApps = {}
local registeredLetters = {}

--------------------------------------------------
-- Action Sequence Memorization
--------------------------------------------------

-- Returns the memorized action sequence containing bundleID, or nil.
local function findActionSequence(bundleID)
  for _, actionSequence in ipairs(memorizedActionSequences) do
    for _, action in ipairs(actionSequence) do
      if action.id == bundleID then
        return actionSequence
      end
    end
  end
end

-- Memorizes a new action sequence, removing its participants from existing sequences.
local function memorizeActionSequence(newActionSequence)
  local participating = {}
  for _, action in ipairs(newActionSequence) do
    if action.id then
      participating[action.id] = true
    end
  end

  local pruned = {}
  for _, actionSequence in ipairs(memorizedActionSequences) do
    local filtered = {}
    for _, action in ipairs(actionSequence) do
      if not action.id or not participating[action.id] then
        table.insert(filtered, action)
      end
    end
    if #filtered > 0 then
      table.insert(pruned, filtered)
    end
  end

  table.insert(pruned, newActionSequence)
  memorizedActionSequences = pruned
end

--------------------------------------------------
-- App Management
--------------------------------------------------

-- Returns the app for a bundle ID, launching it if not running.
local function ensureApp(bundleID)
  local app = hs.application.get(bundleID)
  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
    app = hs.application.get(bundleID)
  end
  return app
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

-- Returns true if all hyper modifier keys are currently pressed.
local function isHyperHeld()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.alt and flags.cmd and flags.ctrl and flags.shift
end

-- Activates apps back to front, with the focus app last.
local function activateApps(apps, focusApp)
  for i = #apps, 1, -1 do
    if apps[i] ~= focusApp then
      apps[i]:activate(true)
    end
  end
  if focusApp then focusApp:activate(true) end
end

--------------------------------------------------
-- Z-Order
--------------------------------------------------

-- Returns the z-ordered list of bundle IDs from all visible windows (front to back).
local function bundleIDsByZOrder()
  local order = {}
  local seen = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    local bundleID = window:application():bundleID()
    if bundleID and not seen[bundleID] then
      seen[bundleID] = true
      table.insert(order, bundleID)
    end
  end
  return order
end

-- Returns the z-order that would result from activating a single app.
local function zOrderAfterActivation(currentOrder, bundleID)
  local result = {}
  for _, id in ipairs(currentOrder) do
    if id ~= bundleID then
      table.insert(result, id)
    end
  end
  table.insert(result, 1, bundleID)
  return result
end

-- Returns the z-order that would result from activating an action sequence back to front,
-- then the focus app last.
local function zOrderAfterActionSequence(currentOrder, sequenceBundleIDs, focusBundleID)
  local order = currentOrder
  for i = #sequenceBundleIDs, 1, -1 do
    if sequenceBundleIDs[i] ~= focusBundleID then
      order = zOrderAfterActivation(order, sequenceBundleIDs[i])
    end
  end
  if focusBundleID then
    order = zOrderAfterActivation(order, focusBundleID)
  end
  return order
end

-- Returns whether two z-order lists differ.
local function zOrdersDiffer(a, b)
  if #a ~= #b then return true end
  for i, id in ipairs(a) do
    if id ~= b[i] then return true end
  end
  return false
end

--------------------------------------------------
-- Window Positioning
--------------------------------------------------

-- Positions a single window within its tile.
local function positionWindow(window, screenFrame, weight, tileOffset)
  local width = screenFrame.w * weight
  local x = screenFrame.x + screenFrame.w * tileOffset

  window:setFrame(hs.geometry.rect(x, screenFrame.y, width, screenFrame.h), 0)
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
      positionWindow(window, screenFrame, normalizedWeight, offset)
    end

    offset = offset + normalizedWeight
  end
end

--------------------------------------------------
-- Window Layout
--------------------------------------------------

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

-- Resolves which app should receive focus after tiling.
local function resolveFocusApp(tiles, initialFocusedWindow, focusBundleID)
  -- Explicit target: find the matching app
  if focusBundleID then
    for _, tile in ipairs(tiles) do
      if tile.app:bundleID() == focusBundleID then
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

  -- Fall back to first tile if all belong to the initially focused app
  if #tiles > 0 then return tiles[1].app end
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

-- Assigns windows to tiles and positions them proportionally on the target screen.
local function applyLayout(tiles, initialFocusedWindow, opts)
  local targetScreen = resolveTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  local tilesWithWindows = assignWindowsToTiles(tiles)
  if #tilesWithWindows == 0 then return end

  local focusBundleID = opts and opts.focusBundleID
  local focusApp = resolveFocusApp(tilesWithWindows, initialFocusedWindow, focusBundleID)

  -- Collect unique apps in tile order
  local apps = {}
  local seen = {}
  for _, tile in ipairs(tilesWithWindows) do
    local bundleID = tile.app:bundleID()
    if not seen[bundleID] then
      seen[bundleID] = true
      table.insert(apps, tile.app)
    end
  end

  positionTiles(screenFrame, tilesWithWindows)
  hs.timer.doAfter(0.01, function()
    if opts and opts.skipReorder then
      if focusApp then focusApp:activate(true) end
    else
      activateApps(apps, focusApp)
    end
  end)
end

--------------------------------------------------
-- Action Resolution
--------------------------------------------------

-- Resolves consecutive letter actions into app actions by longest-prefix matching.
local function resolveLetterActions(actions)
  local resolved = {}
  local index = 1

  while index <= #actions do
    local action = actions[index]

    if action.type ~= ActionType.letter then
      table.insert(resolved, action)
      index = index + 1
    else
      -- Collect consecutive letters
      local letters = ""
      for i = index, #actions do
        if actions[i].type ~= ActionType.letter then break end
        letters = letters .. actions[i].id
      end

      -- Match longest prefix against registered apps
      local matched = false
      for tryLength = #letters, 1, -1 do
        local registration = registeredApps[letters:sub(1, tryLength)]
        if registration then
          table.insert(resolved, {
            id = registration.bundleID,
            type = ActionType.focusOrLayout,
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

-- Merges consecutive actions with the same type and ID, summing weights.
local function mergeConsecutiveActions(actions)
  if #actions == 0 then return {} end

  local merged = {}
  local current = {
    id = actions[1].id,
    type = actions[1].type,
    weight = actions[1].weight,
  }

  for i = 2, #actions do
    local action = actions[i]
    local isSameAction = current.type ~= ActionType.split
      and action.type ~= ActionType.split
      and action.type .. ":" .. action.id == current.type .. ":" .. current.id

    if isSameAction then
      current.weight = current.weight + action.weight
    else
      table.insert(merged, current)
      current = { id = action.id, type = action.type, weight = action.weight }
    end
  end

  table.insert(merged, current)
  return merged
end

-- Merges actions, ensures apps are running, and returns tiles with app references.
local function buildTiles(actions)
  local merged = mergeConsecutiveActions(actions)

  local tiles = {}
  for _, action in ipairs(merged) do
    if action.type ~= ActionType.split then
      local app = ensureApp(action.id)
      if app then
        table.insert(tiles, { app = app, weight = action.weight })
      end
    end
  end
  return tiles
end

--------------------------------------------------
-- Queue Processing
--------------------------------------------------

-- Replays a memorized action sequence, positioning tiles and focusing the target app.
local function replayActionSequence(actionSequence, bundleID, initialFocusedWindow)
  local sequenceBundleIDs = {}
  for _, action in ipairs(actionSequence) do
    if action.id then
      table.insert(sequenceBundleIDs, action.id)
    end
  end

  -- Determine whether replaying would change z-order beyond a simple activation
  local currentOrder = bundleIDsByZOrder()
  local needsReorder = zOrdersDiffer(
    zOrderAfterActionSequence(currentOrder, sequenceBundleIDs, bundleID),
    zOrderAfterActivation(currentOrder, bundleID)
  )

  local tiles = buildTiles(actionSequence)

  hs.timer.doAfter(0.1, function()
    applyLayout(tiles, initialFocusedWindow, {
      focusBundleID = bundleID,
      skipReorder = not needsReorder,
    })
  end)
end

-- Resolves the current queue and applies layout eagerly while hyper is held.
-- On first app: preactivates for responsiveness.
-- On repeated shorthand or multiple apps: memorizes action sequence and tiles immediately.
local function updateEagerLayout()
  local resolved = resolveLetterActions(actionQueue)
  local mergedActions = mergeConsecutiveActions(resolved)
  local tiles = buildTiles(mergedActions)
  local isActionSequence = #tiles >= 2 or (#tiles == 1 and tiles[1].weight > 1)

  if isActionSequence then
    -- Action sequence: memorize and layout immediately
    memorizeActionSequence(mergedActions)
    applyLayout(tiles, eagerFocusedWindow)
    eagerPhase = "laid_out"
  elseif #tiles == 1 and not eagerPhase then
    -- First app: preactivate
    tiles[1].app:activate()
    eagerPhase = "preactivated"
  end
end

-- Drains the action queue on hyper release or immediate processing.
-- Multi-app layouts are already applied eagerly; only single-app needs handling here.
local function processQueue()
  local initialFocusedWindow = eagerFocusedWindow or hs.window.focusedWindow()
  local wasLaidOut = eagerPhase == "laid_out"
  eagerPhase = nil
  eagerFocusedWindow = nil

  if #actionQueue == 0 then return end

  -- Snapshot and clear queue
  local actions = actionQueue
  actionQueue = {}

  -- Multi-app layout was already applied eagerly
  if wasLaidOut then return end

  -- Single app: replay memorized action sequence or activate
  local resolvedActions = resolveLetterActions(actions)
  local tiles = buildTiles(resolvedActions)

  if #tiles == 1 then
    local bundleID = tiles[1].app:bundleID()
    local actionSequence = findActionSequence(bundleID)

    if actionSequence then
      replayActionSequence(actionSequence, bundleID, initialFocusedWindow)
    else
      hs.timer.doAfter(0.1, function()
        tiles[1].app:activate(true)
      end)
    end
  end
end

-- Appends an action and applies eagerly while hyper is held, or processes on release.
local function enqueueAction(action)
  table.insert(actionQueue, action)

  if isHyperHeld() then
    hyperkey.startPolling()
    if not eagerFocusedWindow then
      eagerFocusedWindow = hs.window.focusedWindow()
    end
    updateEagerLayout()
  else
    processQueue()
  end
end

--------------------------------------------------
-- Public API
--------------------------------------------------

local M = {}

--- Registers an app shortcut for multi-letter tiling activation.
--- Each letter in the shortcut is bound as a hyper hotkey.
function M.registerApp(shortcut, bundleID, defaultWeight)
  registeredApps[shortcut] = { bundleID = bundleID, defaultWeight = defaultWeight or 1 }

  for i = 1, #shortcut do
    local letter = shortcut:sub(i, i)

    if not registeredLetters[letter] then
      registeredLetters[letter] = true

      hs.hotkey.bind(HYPER_MODIFIERS, letter, function()
        enqueueAction({ id = letter, type = ActionType.letter, weight = 1 })
      end)
    end
  end
end

--- Binds a hyper key to insert a split action into the queue.
--- Splits prevent merging of adjacent app actions.
function M.setSplitKey(key)
  hs.hotkey.bind(HYPER_MODIFIERS, key, function()
    enqueueAction({ id = nil, type = ActionType.split, weight = 1 })
  end)
end

--------------------------------------------------
-- Initialization
--------------------------------------------------

hyperkey.onRelease(function() processQueue() end)

return M
