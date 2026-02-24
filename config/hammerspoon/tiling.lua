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
local PADDING = 0
local CASCADE_OFFSET_X = 0
local CASCADE_OFFSET_Y = 0

local ActionType = {
  focusOrLayout = "focusOrLayout",
  letter = "letter",
  split = "split",
}

--------------------------------------------------
-- State
--------------------------------------------------

local actionQueue = {}
local registeredApps = {}
local registeredLetters = {}

--------------------------------------------------
-- Forward Declarations
--------------------------------------------------

local activateApp
local applyLayout
local assignWindowsToTiles
local buildTiles
local collectStandardWindows
local enqueueAction
local isHyperHeld
local mergeConsecutiveActions
local positionTiles
local positionWindow
local processQueue
local raiseWindows
local resolveLetterActions
local resolveTargetScreen
local restoreFocus

--------------------------------------------------
-- Public API
--------------------------------------------------

local M = {}

--- Queues an app for focus or tiling layout by bundle ID.
--- If hyper is held, the action accumulates; otherwise it processes immediately.
function M.queueAppForLayout(bundleID)
  enqueueAction({ id = bundleID, type = ActionType.focusOrLayout, weight = 1 })
end

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
-- Queue Processing
--------------------------------------------------

-- Appends an action and processes immediately or defers to hyper release.
function enqueueAction(action)
  table.insert(actionQueue, action)

  if isHyperHeld() then
    hyperkey.startPolling()
  else
    processQueue()
  end
end

-- Drains the action queue: resolves, merges, activates apps, and applies layout.
function processQueue()
  if #actionQueue == 0 then return end

  -- Snapshot and clear queue
  local actions = actionQueue
  actionQueue = {}

  -- Resolve letter sequences into app actions
  local resolvedActions = resolveLetterActions(actions)
  local initialFocusedWindow = hs.window.focusedWindow()

  -- Activate apps and build tiles
  local tiles = buildTiles(resolvedActions)

  -- Apply tiling layout or raise single app's windows
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

--------------------------------------------------
-- Action Resolution
--------------------------------------------------

-- Resolves consecutive letter actions into app actions by longest-prefix matching.
function resolveLetterActions(actions)
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
function mergeConsecutiveActions(actions)
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
function buildTiles(actions)
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
-- Window Layout
--------------------------------------------------

-- Assigns windows to tiles and positions them proportionally on the target screen.
function applyLayout(tiles, initialFocusedWindow)
  local targetScreen = resolveTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  -- Assign windows and flatten for z-ordering
  local tilesWithWindows = assignWindowsToTiles(tiles)
  if #tilesWithWindows == 0 then return end

  local allWindows = {}
  for _, tile in ipairs(tilesWithWindows) do
    for _, window in ipairs(tile.windows) do
      table.insert(allWindows, window)
    end
  end

  -- Position, raise, and restore focus
  positionTiles(screenFrame, tilesWithWindows)
  hs.timer.doAfter(0.01, function()
    raiseWindows(allWindows)
    restoreFocus(initialFocusedWindow, allWindows, tiles)
  end)
end

-- Distributes each app's standard windows across its tiles (last tile gets remaining).
function assignWindowsToTiles(tiles)
  -- Group tiles by app and collect standard windows
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

  -- Assign one window per tile; last tile gets all remaining
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

-- Positions tiles left-to-right, dividing screen width by weight.
function positionTiles(screenFrame, tiles)
  local totalWeight = 0
  for _, tile in ipairs(tiles) do
    totalWeight = totalWeight + tile.weight
  end

  local offset = 0
  for _, tile in ipairs(tiles) do
    local normalizedWeight = tile.weight / totalWeight

    for windowIndex, window in ipairs(tile.windows) do
      positionWindow(window, screenFrame, normalizedWeight, offset, windowIndex - 1, #tile.windows)
    end

    offset = offset + normalizedWeight
  end
end

-- Positions a single window within its tile, applying cascade offsets.
function positionWindow(window, screenFrame, weight, tileOffset, windowIndex, windowCount)
  local cascadeX = CASCADE_OFFSET_X * (windowCount - 1)
  local cascadeY = CASCADE_OFFSET_Y * (windowCount - 1)

  local availableHeight = screenFrame.h - (2 * PADDING)
  local availableWidth = screenFrame.w - (2 * PADDING)
  local availableX = screenFrame.x + PADDING
  local availableY = screenFrame.y + PADDING

  local height = availableHeight - cascadeY
  local width = availableWidth * weight - PADDING - cascadeX
  local x = availableX + availableWidth * tileOffset + CASCADE_OFFSET_X * windowIndex
  local y = availableY + CASCADE_OFFSET_Y * windowIndex

  window:setFrame(hs.geometry.rect(x, y, width, height), 0)
end

--------------------------------------------------
-- Supporting Functions
--------------------------------------------------

-- Launches or activates an app by bundle ID and returns the app object.
function activateApp(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
  return hs.application.get(bundleID)
end

-- Returns all standard windows for an app.
function collectStandardWindows(app)
  local windows = {}
  for _, window in ipairs(app:allWindows()) do
    if window:isStandard() then
      table.insert(windows, window)
    end
  end
  return windows
end

-- Returns true if all hyper modifier keys are currently pressed.
function isHyperHeld()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.alt and flags.cmd and flags.ctrl and flags.shift
end

-- Raises windows in reverse order to preserve relative z-order.
function raiseWindows(windows)
  for i = #windows, 1, -1 do
    windows[i]:raise()
  end
end

-- Resolves the target screen from tiles or falls back to focused/main screen.
function resolveTargetScreen(tiles)
  -- Prefer first app's main window screen
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then return mainWindow:screen() end
  end

  -- Fall back to focused window screen
  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow then return focusedWindow:screen() end

  return hs.screen.mainScreen()
end

-- Restores focus to the initially focused window if tiled, else first app's main window.
function restoreFocus(initialFocusedWindow, tiledWindows, tiles)
  if initialFocusedWindow then
    local initialWindowId = initialFocusedWindow:id()
    for _, window in ipairs(tiledWindows) do
      if window:id() == initialWindowId then
        initialFocusedWindow:focus()
        return
      end
    end
  end

  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then mainWindow:focus() end
  end
end

--------------------------------------------------
-- Initialization
--------------------------------------------------

hyperkey.onRelease(function() processQueue() end)

return M
