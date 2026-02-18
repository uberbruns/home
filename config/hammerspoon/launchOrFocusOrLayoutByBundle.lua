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

local hyperkey = require("hyperkey")

local M = {}

--------------------------------------------------
-- Configuration
--------------------------------------------------

local PADDING = 8
local CASCADE_OFFSET_X = 0
local CASCADE_OFFSET_Y = 0
local queue = {}

local ActionType = {
  focusOrLayout = "focusOrLayout",
  split = "split"
}

--------------------------------------------------
-- Public API
--------------------------------------------------

function M.launchOrFocusOrLayoutByBundle(bundleID)
  local action = createQueuedAction(ActionType.focusOrLayout, bundleID)
  table.insert(queue, action)

  if not isHyperHeld() then
    processQueue()
  else
    hyperkey.startPolling()
  end
end

function M.bindSplitLayoutAction(key)
  local hyper = {"cmd", "alt", "ctrl", "shift"}
  hs.hotkey.bind(hyper, key, function()
    local action = createQueuedAction(ActionType.split, nil)
    table.insert(queue, action)

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

function createQueuedAction(type, bundleID)
  return {
    type = type,
    bundleID = bundleID,
    weight = 1
  }
end

function processQueue()
  if #queue == 0 then return end

  local totalCount = #queue
  local initialFocusedWindow = hs.window.focusedWindow()

  local apps = activateQueuedApps()

  if totalCount > 1 then
    hs.timer.doAfter(0.1, function()
      layoutApps(apps, initialFocusedWindow)
    end)
  end

  queue = {}
end

function consolidateActions(actions)
  if #actions == 0 then return {} end

  local result = {}
  local current = {
    type = actions[1].type,
    bundleID = actions[1].bundleID,
    weight = actions[1].weight
  }

  for i = 2, #actions do
    local action = actions[i]

    if current.type == ActionType.split or action.type == ActionType.split then
      table.insert(result, current)
      current = {
        type = action.type,
        bundleID = action.bundleID,
        weight = action.weight
      }
    else
      local key = action.type .. ":" .. action.bundleID
      local currentKey = current.type .. ":" .. current.bundleID

      if key == currentKey then
        current.weight = current.weight + action.weight
      else
        table.insert(result, current)
        current = {
          type = action.type,
          bundleID = action.bundleID,
          weight = action.weight
        }
      end
    end
  end

  table.insert(result, current)
  return result
end

function activateQueuedApps()
  local consolidatedActions = consolidateActions(queue)

  local tiles = {}
  for _, action in ipairs(consolidatedActions) do
    if action.type ~= ActionType.split then
      local app = activateApp(action.bundleID)
      if app then
        table.insert(tiles, { app = app, weight = action.weight })
      end
    end
  end
  return tiles
end

function activateApp(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
  return hs.application.get(bundleID)
end

--------------------------------------------------
-- Window Layout
--------------------------------------------------

function layoutApps(tiles, initialFocusedWindow)
  local targetScreen = getTargetScreen(tiles)
  local screenFrame = targetScreen:frame()

  local tilesWithWindows = distributeWindowsToTiles(tiles)
  local allWindows = collectAllWindows(tilesWithWindows)

  if #tilesWithWindows > 0 then
    layoutTilesOnScreen(screenFrame, tilesWithWindows)
    hs.timer.doAfter(0.01, function()
      bringWindowsToFront(allWindows)
      restoreFocus(initialFocusedWindow, allWindows, tiles)
    end)
  end
end

function distributeWindowsToTiles(tiles)
  local appTiles = {}

  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    if not appTiles[bundleID] then
      appTiles[bundleID] = {
        app = tile.app,
        tiles = {},
        windows = {}
      }
    end
    table.insert(appTiles[bundleID].tiles, tile)
  end

  for _, appData in pairs(appTiles) do
    for _, win in ipairs(appData.app:allWindows()) do
      if win:isStandard() then
        table.insert(appData.windows, win)
      end
    end
  end

  local result = {}
  for _, tile in ipairs(tiles) do
    local bundleID = tile.app:bundleID()
    local appData = appTiles[bundleID]

    if appData and #appData.windows > 0 then
      local tileIndex = #result + 1
      local tilesForThisApp = 0
      for i = 1, tileIndex do
        if result[i] and result[i].app:bundleID() == bundleID then
          tilesForThisApp = tilesForThisApp + 1
        end
      end

      local isLastTileForApp = (tilesForThisApp + 1) == #appData.tiles
      local windowsAvailable = #appData.windows - tilesForThisApp

      if windowsAvailable > 0 then
        local tileWindows = {}
        if isLastTileForApp then
          for i = tilesForThisApp + 1, #appData.windows do
            table.insert(tileWindows, appData.windows[i])
          end
        else
          table.insert(tileWindows, appData.windows[tilesForThisApp + 1])
        end

        table.insert(result, {
          app = tile.app,
          weight = tile.weight,
          windows = tileWindows
        })
      end
    end
  end

  return result
end

function collectAllWindows(tilesWithWindows)
  local allWindows = {}
  for _, tile in ipairs(tilesWithWindows) do
    for _, win in ipairs(tile.windows) do
      table.insert(allWindows, win)
    end
  end
  return allWindows
end

function bringWindowsToFront(windows)
  for i = #windows, 1, -1 do
    windows[i]:raise()
  end
end

function layoutTilesOnScreen(screenFrame, tiles)
  local totalWeight = 0
  for _, tile in ipairs(tiles) do
    totalWeight = totalWeight + tile.weight
  end

  local tileIndex = 0
  for _, tile in ipairs(tiles) do
    local weight = tile.weight / totalWeight
    local windowCount = #tile.windows
    for windowIndex, win in ipairs(tile.windows) do
      layoutWindow(win, screenFrame, weight, tileIndex, windowIndex - 1, windowCount)
    end
    tileIndex = tileIndex + weight
  end
end

function layoutWindow(win, screenFrame, weight, appIndex, windowIndex, windowCount)
  local halfPad = PADDING / 2
  local paddedScreen = hs.geometry.rect(
    screenFrame.x + halfPad,
    screenFrame.y + halfPad,
    screenFrame.w - PADDING,
    screenFrame.h - PADDING
  )
  local cascadeOffsetX = CASCADE_OFFSET_X * (windowCount - 1)
  local cascadeOffsetY = CASCADE_OFFSET_Y * (windowCount - 1)
  local x = paddedScreen.x + paddedScreen.w * appIndex + halfPad + CASCADE_OFFSET_X * windowIndex
  local y = paddedScreen.y + halfPad + CASCADE_OFFSET_Y * windowIndex
  local w = paddedScreen.w * weight - PADDING - cascadeOffsetX
  local h = paddedScreen.h - PADDING - cascadeOffsetY
  win:setFrame(hs.geometry.rect(x, y, w, h), 0)
end

--------------------------------------------------
-- Helpers
--------------------------------------------------

function isHyperHeld()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.cmd and flags.shift and flags.alt and flags.ctrl
end

function getTargetScreen(tiles)
  if #tiles > 0 then
    local mainWindow = tiles[1].app:mainWindow()
    if mainWindow then
      return mainWindow:screen()
    end
  end

  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow then
    return focusedWindow:screen()
  end

  return hs.screen.mainScreen()
end

function restoreFocus(initialWindow, layoutedWindows, tiles)
  if initialWindow then
    local initialId = initialWindow:id()
    for _, win in ipairs(layoutedWindows) do
      if win:id() == initialId then
        initialWindow:focus()
        return
      end
    end
  end

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

return M
