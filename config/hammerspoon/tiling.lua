--[[
  App Launcher with Tiling Layout

  - Apps are queued as action objects with a type and bundle ID
  - Split actions can be inserted to prevent merging
  - If hyper key is held, actions accumulate in the queue
  - If hyper key is not held, the queue processes immediately
  - When hyper key is released, the queue processes

  Queue Processing:
  - Consecutive actions with same type and bundle ID are merged, summing weights
  - Split actions break merging without producing tiles
  - Actions separated by different apps or splits remain as separate tiles
  - Each unique app is activated (launched if needed)
  - If only one item was queued, no layout is applied
  - If multiple items were queued, tiling layout is triggered

  Tiling Layout:
  - Target screen: first app's main window > focused window > main screen
  - Windows are distributed across app tiles (one per tile, last gets remaining)
  - Empty app tiles (more tiles than windows) are dropped
  - Screen width is divided proportionally by remaining tile weights
  - Multiple windows in last tile are cascaded within their portion
  - Padding is applied around screen edges and between windows
  - Focus is restored to the initially focused window if it was part of
    the layout, otherwise the first app's main window receives focus
]]

--------------------------------------------------
-- Requirements
--------------------------------------------------

local hyperkey = require("hyperkey")

--------------------------------------------------
-- Module Definition
--------------------------------------------------

local M = {}

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

local actionQueue = {}
local registeredApps = {}
local registeredLetters = {}

--------------------------------------------------
-- Forward Declarations
--------------------------------------------------

local activateApp
local applyLayout
local assignWindowsToTiles
local bringWindowsToFront
local buildTiles
local collectWindows
local enqueueAction
local isHyperHeld
local mergeConsecutiveActions
local positionTiles
local positionWindow
local processQueue
local resolveLetterActions
local resolveTargetScreen
local restoreFocus

--------------------------------------------------
-- Public API
--------------------------------------------------

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

-- Adds an action to the queue and processes immediately or defers to hyper release.
function enqueueAction(action)
  table.insert(actionQueue, action)

  if not isHyperHeld() then
    processQueue()
  else
    hyperkey.startPolling()
  end
end

function processQueue()
  if #actionQueue == 0 then return end

  -- Resolve letter actions and capture initial state
  local resolvedActions = resolveLetterActions(actionQueue)
  local queuedCount = #resolvedActions
  local initialFocusedWindow = hs.window.focusedWindow()

  -- Build tiles from resolved actions
  local tiles = buildTiles(resolvedActions)

  -- Apply layout for multiple items
  if queuedCount > 1 then
    hs.timer.doAfter(0.1, function()
      applyLayout(tiles, initialFocusedWindow)
    end)
  end

  actionQueue = {}
end

-- Resolves consecutive letter actions into app actions by matching against registered shortcuts.
function resolveLetterActions(actions)
  local resolvedActions = {}
  local index = 1

  while index <= #actions do
    local action = actions[index]

    if action.type == ActionType.letter then
      -- Collect consecutive letter actions into a sequence
      local letterSequence = ""

      for i = index, #actions do
        if actions[i].type == ActionType.letter then
          letterSequence = letterSequence .. actions[i].id
        else
          break
        end
      end

      -- Match longest prefix against registered apps
      local matched = false
      local consumedCount = 0

      for tryLength = #letterSequence, 1, -1 do
        local candidate = letterSequence:sub(1, tryLength)
        local registration = registeredApps[candidate]

        if registration then
          table.insert(resolvedActions, {
            id = registration.bundleID,
            type = ActionType.focusOrLayout,
            weight = registration.defaultWeight,
          })
          consumedCount = tryLength
          matched = true
          break
        end
      end

      if matched then
        index = index + consumedCount
      else
        index = index + 1
      end
    else
      table.insert(resolvedActions, action)
      index = index + 1
    end
  end

  return resolvedActions
end

-- Merges consecutive actions with the same type and ID, summing their weights.
function mergeConsecutiveActions(actions)
  if #actions == 0 then return {} end

  local mergedActions = {}
  local current = {
    id = actions[1].id,
    type = actions[1].type,
    weight = actions[1].weight,
  }

  for i = 2, #actions do
    local action = actions[i]

    -- Split actions always break merging
    if current.type == ActionType.split or action.type == ActionType.split then
      table.insert(mergedActions, current)
      current = { id = action.id, type = action.type, weight = action.weight }
    else
      local actionKey = action.type .. ":" .. action.id
      local currentKey = current.type .. ":" .. current.id

      if actionKey == currentKey then
        current.weight = current.weight + action.weight
      else
        table.insert(mergedActions, current)
        current = { id = action.id, type = action.type, weight = action.weight }
      end
    end
  end

  table.insert(mergedActions, current)
  return mergedActions
end

-- Merges actions, activates apps, and builds tile list.
function buildTiles(actions)
  local mergedActions = mergeConsecutiveActions(actions)

  local tiles = {}
  for _, action in ipairs(mergedActions) do
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

function applyLayout(tiles, initialFocusedWindow)
  local targetScreen = resolveTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  local tilesWithWindows = assignWindowsToTiles(tiles)
  local allWindows = collectWindows(tilesWithWindows)

  if #tilesWithWindows > 0 then
    positionTiles(screenFrame, tilesWithWindows)

    hs.timer.doAfter(0.01, function()
      bringWindowsToFront(allWindows)
      restoreFocus(initialFocusedWindow, allWindows, tiles)
    end)
  end
end

function assignWindowsToTiles(tiles)
  -- Group tiles by application
  local tilesByApp = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    if not tilesByApp[bundleID] then
      tilesByApp[bundleID] = {
        app = tile.app,
        tiles = {},
        windows = {},
      }
    end
    table.insert(tilesByApp[bundleID].tiles, tile)
  end

  -- Collect standard windows for each app
  for _, group in pairs(tilesByApp) do
    for _, window in ipairs(group.app:allWindows()) do
      if window:isStandard() then
        table.insert(group.windows, window)
      end
    end
  end

  -- Assign windows to tiles
  local result = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    local group = tilesByApp[bundleID]

    if group and #group.windows > 0 then
      -- Count already assigned tiles for this app
      local assignedCount = 0
      for i = 1, #result do
        if result[i].app:bundleID() == bundleID then
          assignedCount = assignedCount + 1
        end
      end

      local isLastTile = (assignedCount + 1) == #group.tiles
      local remainingWindows = #group.windows - assignedCount

      if remainingWindows > 0 then
        local tileWindows = {}
        if isLastTile then
          -- Last tile gets all remaining windows
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
      end
    end
  end

  return result
end

function positionTiles(screenFrame, tiles)
  -- Calculate total weight
  local totalWeight = 0
  for _, tile in ipairs(tiles) do
    totalWeight = totalWeight + tile.weight
  end

  -- Position each tile
  local offset = 0
  for _, tile in ipairs(tiles) do
    local normalizedWeight = tile.weight / totalWeight

    for windowIndex, window in ipairs(tile.windows) do
      positionWindow(window, screenFrame, normalizedWeight, offset, windowIndex - 1, #tile.windows)
    end

    offset = offset + normalizedWeight
  end
end

function positionWindow(window, screenFrame, weight, tileOffset, windowIndex, windowCount)
  -- Calculate cascade offsets
  local cascadeX = CASCADE_OFFSET_X * (windowCount - 1)
  local cascadeY = CASCADE_OFFSET_Y * (windowCount - 1)

  -- Calculate available space
  local availableHeight = screenFrame.h - (2 * PADDING)
  local availableWidth = screenFrame.w - (2 * PADDING)
  local availableX = screenFrame.x + PADDING
  local availableY = screenFrame.y + PADDING

  -- Calculate window frame
  local height = availableHeight - cascadeY
  local width = availableWidth * weight - PADDING - cascadeX
  local x = availableX + availableWidth * tileOffset + CASCADE_OFFSET_X * windowIndex
  local y = availableY + CASCADE_OFFSET_Y * windowIndex

  window:setFrame(hs.geometry.rect(x, y, width, height), 0)
end

--------------------------------------------------
-- Supporting Functions
--------------------------------------------------

function activateApp(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
  return hs.application.get(bundleID)
end

function bringWindowsToFront(windows)
  -- Raise in reverse order to preserve relative z-order
  for i = #windows, 1, -1 do
    windows[i]:raise()
  end
end

function collectWindows(tilesWithWindows)
  local allWindows = {}
  for _, tile in ipairs(tilesWithWindows) do
    for _, window in ipairs(tile.windows) do
      table.insert(allWindows, window)
    end
  end
  return allWindows
end

function isHyperHeld()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.alt and flags.cmd and flags.ctrl and flags.shift
end

function resolveTargetScreen(tiles)
  -- Prefer first app's main window screen
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then
      return mainWindow:screen()
    end
  end

  -- Fall back to focused window screen
  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow then
    return focusedWindow:screen()
  end

  -- Final fallback to main screen
  return hs.screen.mainScreen()
end

function restoreFocus(initialFocusedWindow, tiledWindows, tiles)
  -- Restore focus to initially focused window if it was tiled
  if initialFocusedWindow then
    local initialWindowId = initialFocusedWindow:id()
    for _, window in ipairs(tiledWindows) do
      if window:id() == initialWindowId then
        initialFocusedWindow:focus()
        return
      end
    end
  end

  -- Fall back to first app's main window
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then
      mainWindow:focus()
    end
  end
end

--------------------------------------------------
-- Initialization
--------------------------------------------------

hyperkey.onRelease(function() processQueue() end)

--------------------------------------------------
-- Module Export
--------------------------------------------------

return M
