--[[
  App Launcher with Tiling Layout

  - Apps are queued as action objects with type and bundle ID
  - Split actions can be inserted to prevent consolidation
  - If hyper key is held, actions accumulate in the queue
  - If hyper key is not held, the queue is processed immediately
  - When hyper key is released, the queue is processed

  Queue Processing:
  - Consecutive actions with same type and bundle ID are consolidated, summing weights
  - Split actions break consolidation without being layouted
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

local PADDING = 8
local CASCADE_OFFSET_X = 0
local CASCADE_OFFSET_Y = 0

local ActionType = {
  focusOrLayout = "focusOrLayout",
  split = "split",
  letterRegistered = "letterRegistered"
}

local actionQueue = {}
local registeredApps = {}
local registeredLetters = {}

--------------------------------------------------
-- Public API
--------------------------------------------------

function M.queueAppForLayout(bundleID)
  -- Create and queue action
  local action = createFocusOrLayoutAction(bundleID)
  table.insert(actionQueue, action)

  -- Process immediately or wait for hyper release
  if not isHyperHeld() then
    processQueue()
  else
    hyperkey.startPolling()
  end
end

-- Legacy function name for compatibility
M.launchOrFocusOrLayoutByBundle = M.queueAppForLayout

function M.registerApp(shortcut, bundleID)
  -- Store app registration
  registeredApps[shortcut] = bundleID

  -- Register hotkeys for each letter in the shortcut
  for i = 1, #shortcut do
    local letter = shortcut:sub(i, i)

    if not registeredLetters[letter] then
      -- Register this letter as hotkey
      registeredLetters[letter] = true

      local hyper = {"cmd", "alt", "ctrl", "shift"}
      hs.hotkey.bind(hyper, letter, function()
        local action = createLetterAction(letter)
        table.insert(actionQueue, action)

        if not isHyperHeld() then
          processQueue()
        else
          hyperkey.startPolling()
        end
      end)
    end
  end
end

function M.setSplitKey(key)
  -- Bind key to insert split action
  local hyper = {"cmd", "alt", "ctrl", "shift"}
  hs.hotkey.bind(hyper, key, function()
    local action = createSplitAction()
    table.insert(actionQueue, action)

    if not isHyperHeld() then
      processQueue()
    else
      hyperkey.startPolling()
    end
  end)
end

--------------------------------------------------
-- Queue Processing
--------------------------------------------------

function processQueue()
  -- Validate queue
  if #actionQueue == 0 then return end

  -- Convert letter actions to app actions
  local processedActions = convertLetterActionsToAppActions(actionQueue)

  -- Capture initial state
  local totalCount = #processedActions
  local initialFocusedWindow = hs.window.focusedWindow()

  -- Create tiles from processed actions
  local tiles = createTilesFromActions(processedActions)

  -- Trigger layout for multiple items
  if totalCount > 1 then
    hs.timer.doAfter(0.1, function()
      layoutTiles(tiles, initialFocusedWindow)
    end)
  end

  -- Clear queue
  actionQueue = {}
end

function convertLetterActionsToAppActions(actions)
  local convertedActions = {}
  local letterIndex = 1

  while letterIndex <= #actions do
    local action = actions[letterIndex]

    if action.type == ActionType.letterRegistered then
      -- Collect consecutive letter actions
      local letterSequence = ""
      local sequenceLength = 0

      for i = letterIndex, #actions do
        if actions[i].type == ActionType.letterRegistered then
          letterSequence = letterSequence .. actions[i].id
          sequenceLength = sequenceLength + 1
        else
          break
        end
      end

      -- Try to match letters to registered apps
      local matched = false
      local consumedLetters = 0

      for tryLength = #letterSequence, 1, -1 do
        local testShortcut = letterSequence:sub(1, tryLength)
        local bundleID = registeredApps[testShortcut]

        if bundleID then
          -- Found match, create app action
          table.insert(convertedActions, createFocusOrLayoutAction(bundleID))
          consumedLetters = tryLength
          matched = true
          break
        end
      end

      if matched then
        -- Advance past consumed letters
        letterIndex = letterIndex + consumedLetters
      else
        -- No match found, discard first letter and retry
        letterIndex = letterIndex + 1
      end
    else
      -- Non-letter action, pass through
      table.insert(convertedActions, action)
      letterIndex = letterIndex + 1
    end
  end

  return convertedActions
end

function consolidateActions(actions)
  -- Handle empty input
  if #actions == 0 then return {} end

  -- Initialize with first action
  local consolidatedActions = {}
  local currentAction = {
    type = actions[1].type,
    id = actions[1].id,
    value = actions[1].value
  }

  -- Process remaining actions
  for i = 2, #actions do
    local action = actions[i]

    -- Split actions always break consolidation
    if currentAction.type == ActionType.split or action.type == ActionType.split then
      table.insert(consolidatedActions, currentAction)
      currentAction = {
        type = action.type,
        id = action.id,
        value = action.value
      }
    else
      -- Consolidate consecutive matching actions
      local actionKey = action.type .. ":" .. action.id
      local currentKey = currentAction.type .. ":" .. currentAction.id

      if actionKey == currentKey then
        currentAction.value = currentAction.value + action.value
      else
        table.insert(consolidatedActions, currentAction)
        currentAction = {
          type = action.type,
          id = action.id,
          value = action.value
        }
      end
    end
  end

  -- Add final action
  table.insert(consolidatedActions, currentAction)
  return consolidatedActions
end

function createTilesFromActions(actions)
  -- Consolidate actions
  local consolidatedActions = consolidateActions(actions)

  -- Activate apps and create tiles
  local tiles = {}
  for _, action in ipairs(consolidatedActions) do
    if action.type ~= ActionType.split then
      local app = ensureAppRunning(action.id)
      if app then
        table.insert(tiles, { app = app, weight = action.value })
      end
    end
  end
  return tiles
end

--------------------------------------------------
-- Window Layout
--------------------------------------------------

function layoutTiles(tiles, initialFocusedWindow)
  -- Determine target screen
  local targetScreen = determineTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  -- Distribute windows to tiles
  local tilesWithWindows = distributeWindowsToTiles(tiles)
  local layoutedWindows = collectAllWindows(tilesWithWindows)

  -- Apply layout
  if #tilesWithWindows > 0 then
    layoutTilesOnScreen(screenFrame, tilesWithWindows)

    -- Restore z-order and focus
    hs.timer.doAfter(0.01, function()
      bringWindowsToFront(layoutedWindows)
      restoreFocus(initialFocusedWindow, layoutedWindows, tiles)
    end)
  end
end

function distributeWindowsToTiles(tiles)
  -- Group tiles by application
  local tilesByApp = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    if not tilesByApp[bundleID] then
      tilesByApp[bundleID] = {
        app = tile.app,
        tiles = {},
        windows = {}
      }
    end
    table.insert(tilesByApp[bundleID].tiles, tile)
  end

  -- Collect standard windows for each app
  for _, tileGroup in pairs(tilesByApp) do
    for _, window in ipairs(tileGroup.app:allWindows()) do
      if window:isStandard() then
        table.insert(tileGroup.windows, window)
      end
    end
  end

  -- Assign windows to tiles
  local tilesWithWindows = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    local tileGroup = tilesByApp[bundleID]

    if tileGroup and #tileGroup.windows > 0 then
      -- Count already assigned tiles for this app
      local assignedTileCount = 0
      for i = 1, #tilesWithWindows do
        if tilesWithWindows[i].app:bundleID() == bundleID then
          assignedTileCount = assignedTileCount + 1
        end
      end

      -- Check if this is the last tile for this app
      local isLastTileForApp = (assignedTileCount + 1) == #tileGroup.tiles
      local windowsAvailable = #tileGroup.windows - assignedTileCount

      if windowsAvailable > 0 then
        -- Assign windows to tile
        local tileWindows = {}
        if isLastTileForApp then
          -- Last tile gets all remaining windows
          for i = assignedTileCount + 1, #tileGroup.windows do
            table.insert(tileWindows, tileGroup.windows[i])
          end
        else
          -- Non-last tiles get single window
          table.insert(tileWindows, tileGroup.windows[assignedTileCount + 1])
        end

        table.insert(tilesWithWindows, {
          app = tile.app,
          weight = tile.weight,
          windows = tileWindows
        })
      end
    end
  end

  return tilesWithWindows
end

function layoutTilesOnScreen(screenFrame, tiles)
  -- Calculate total weight
  local totalWeight = 0
  for _, tile in ipairs(tiles) do
    totalWeight = totalWeight + tile.weight
  end

  -- Position each tile and its windows
  local tilePosition = 0
  for _, tile in ipairs(tiles) do
    local normalizedWeight = tile.weight / totalWeight
    local windowCount = #tile.windows

    for windowIndex, window in ipairs(tile.windows) do
      layoutWindow(window, screenFrame, normalizedWeight, tilePosition, windowIndex - 1, windowCount)
    end

    tilePosition = tilePosition + normalizedWeight
  end
end

function layoutWindow(window, screenFrame, weight, tilePosition, windowIndex, windowCount)
  -- Calculate padding
  local halfPadding = PADDING / 2
  local paddedScreen = hs.geometry.rect(
    screenFrame.x + halfPadding,
    screenFrame.y + halfPadding,
    screenFrame.w - PADDING,
    screenFrame.h - PADDING
  )

  -- Calculate cascade offsets
  local cascadeOffsetX = CASCADE_OFFSET_X * (windowCount - 1)
  local cascadeOffsetY = CASCADE_OFFSET_Y * (windowCount - 1)

  -- Calculate window frame
  local x = paddedScreen.x + paddedScreen.w * tilePosition + halfPadding + CASCADE_OFFSET_X * windowIndex
  local y = paddedScreen.y + halfPadding + CASCADE_OFFSET_Y * windowIndex
  local width = paddedScreen.w * weight - PADDING - cascadeOffsetX
  local height = paddedScreen.h - PADDING - cascadeOffsetY

  -- Apply frame
  window:setFrame(hs.geometry.rect(x, y, width, height), 0)
end

--------------------------------------------------
-- Supporting Functions
--------------------------------------------------

function createFocusOrLayoutAction(bundleID)
  return {
    type = ActionType.focusOrLayout,
    id = bundleID,
    value = 1
  }
end

function createSplitAction()
  return {
    type = ActionType.split,
    id = nil,
    value = 1
  }
end

function createLetterAction(letter)
  return {
    type = ActionType.letterRegistered,
    id = letter,
    value = 1
  }
end

function ensureAppRunning(bundleID)
  -- Activate if running, otherwise launch
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
  return hs.application.get(bundleID)
end

function collectAllWindows(tilesWithWindows)
  local allWindows = {}
  for _, tile in ipairs(tilesWithWindows) do
    for _, window in ipairs(tile.windows) do
      table.insert(allWindows, window)
    end
  end
  return allWindows
end

function bringWindowsToFront(windows)
  -- Raise in reverse order to preserve relative z-order
  for i = #windows, 1, -1 do
    windows[i]:raise()
  end
end

function isHyperHeld()
  local modifierFlags = hs.eventtap.checkKeyboardModifiers()
  return modifierFlags.cmd and modifierFlags.shift and modifierFlags.alt and modifierFlags.ctrl
end

function determineTargetScreen(tiles)
  -- Prefer first app's main window screen
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then
      return mainWindow:screen()
    end
  end

  -- Fallback to focused window screen
  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow then
    return focusedWindow:screen()
  end

  -- Final fallback to main screen
  return hs.screen.mainScreen()
end

function restoreFocus(initialFocusedWindow, layoutedWindows, tiles)
  -- Restore focus to initially focused window if it was layouted
  if initialFocusedWindow then
    local initialWindowId = initialFocusedWindow:id()
    for _, window in ipairs(layoutedWindows) do
      if window:id() == initialWindowId then
        initialFocusedWindow:focus()
        return
      end
    end
  end

  -- Fallback to first app's main window
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
