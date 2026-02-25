--[[
  Hyper-key driven app launcher with automatic tiling layout.

  Queuing Rules:
  - Actions accumulate while hyper is held, process on release
  - Actions process immediately when hyper is not held
  - Consecutive actions with same bundle ID merge, summing weights
  - Split actions break merging without producing tiles

  Layout Rules:
  - Single action: activate app and raise all windows
  - Multiple actions: activate apps and tile windows proportionally
  - Target screen: first app's main window > focused window > main screen
  - Windows distribute one per tile; last tile receives remaining windows
  - Tiles with no available windows are dropped
  - Focus restores to the initially focused window if tiled,
    otherwise the first app's main window receives focus

  Glossary:
  - action: queued intent with a type, bundle ID, and weight
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
local eagerActivatedApp = nil
local registeredApps = {}
local registeredLetters = {}

--------------------------------------------------
-- Supporting Functions
--------------------------------------------------

-- Launches or activates an app by bundle ID and returns the app object.
local function activateApp(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
  return hs.application.get(bundleID)
end

-- Returns all standard windows for an app.
local function collectStandardWindows(app)
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

-- Raises windows in reverse order to preserve relative z-order.
local function raiseWindows(windows)
  for i = #windows, 1, -1 do
    windows[i]:raise()
  end
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

-- Focuses the first tiled app that differs from the initially focused app.
local function restoreFocus(initialFocusedWindow, tiledWindows, tiles)
  local initialBundleID = initialFocusedWindow and initialFocusedWindow:application():bundleID()

  for _, tile in ipairs(tiles) do
    if tile.app:bundleID() ~= initialBundleID then
      local mainWindow = tile.app:mainWindow()
      if mainWindow then
        mainWindow:focus()
        return
      end
    end
  end

  -- Fall back to first tile if all tiles belong to the initially focused app.
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then mainWindow:focus() end
  end
end

-- Distributes each app's standard windows across its tiles (last tile gets remaining).
local function assignWindowsToTiles(tiles)
  local groupsByApp = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    if not groupsByApp[bundleID] then
      groupsByApp[bundleID] = {
        tiles = {},
        windows = collectStandardWindows(tile.app),
      }
    end
    table.insert(groupsByApp[bundleID].tiles, tile)
  end

  local result = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    local group = groupsByApp[bundleID]
    if not group or #group.windows == 0 then goto continue end

    -- Count previously assigned tiles for this app
    local assignedCount = 0
    for _, assigned in ipairs(result) do
      if assigned.app:bundleID() == bundleID then
        assignedCount = assignedCount + 1
      end
    end

    local remainingWindows = #group.windows - assignedCount
    if remainingWindows <= 0 then goto continue end

    local isLastTile = (assignedCount + 1) == #group.tiles
    local tileWindows = {}
    if isLastTile then
      for i = assignedCount + 1, #group.windows do
        table.insert(tileWindows, group.windows[i])
      end
    else
      table.insert(tileWindows, group.windows[assignedCount + 1])
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
local function applyLayout(tiles, initialFocusedWindow)
  local targetScreen = resolveTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  local tilesWithWindows = assignWindowsToTiles(tiles)
  if #tilesWithWindows == 0 then return end

  -- Flatten for z-ordering
  local allWindows = {}
  for _, tile in ipairs(tilesWithWindows) do
    for _, window in ipairs(tile.windows) do
      table.insert(allWindows, window)
    end
  end

  positionTiles(screenFrame, tilesWithWindows)
  hs.timer.doAfter(0.01, function()
    raiseWindows(allWindows)
    restoreFocus(initialFocusedWindow, allWindows, tiles)
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
      -- Collect consecutive letters into a sequence
      local sequence = ""
      for i = index, #actions do
        if actions[i].type ~= ActionType.letter then break end
        sequence = sequence .. actions[i].id
      end

      -- Match longest prefix against registered apps
      local matched = false
      for tryLength = #sequence, 1, -1 do
        local registration = registeredApps[sequence:sub(1, tryLength)]
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

-- Merges actions, activates apps, and returns tiles with app references.
local function buildTiles(actions)
  local merged = mergeConsecutiveActions(actions)

  local tiles = {}
  for _, action in ipairs(merged) do
    if action.type ~= ActionType.split then
      local app = activateApp(action.id)
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

-- Activates the first resolved app immediately for responsiveness while hyper is held.
local function eagerActivateFirst()
  if eagerActivatedApp then return end

  local resolved = resolveLetterActions(actionQueue)
  for _, action in ipairs(resolved) do
    if action.type == ActionType.focusOrLayout then
      eagerActivatedApp = activateApp(action.id)
      return
    end
  end
end

-- Drains the action queue: resolves, merges, activates apps, and applies layout.
local function processQueue()
  eagerActivatedApp = nil
  if #actionQueue == 0 then return end

  -- Snapshot and clear queue
  local actions = actionQueue
  actionQueue = {}

  local resolvedActions = resolveLetterActions(actions)
  local initialFocusedWindow = hs.window.focusedWindow()

  local tiles = buildTiles(resolvedActions)

  if #resolvedActions > 1 then
    hs.timer.doAfter(0.1, function()
      applyLayout(tiles, initialFocusedWindow)
    end)
  elseif #tiles == 1 then
    hs.timer.doAfter(0.1, function()
      raiseWindows(collectStandardWindows(tiles[1].app))
    end)
  end
end

-- Appends an action and processes immediately or defers to hyper release.
local function enqueueAction(action)
  table.insert(actionQueue, action)

  if isHyperHeld() then
    hyperkey.startPolling()
    eagerActivateFirst()
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
