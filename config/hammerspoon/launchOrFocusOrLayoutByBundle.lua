--[[
  App Launcher with Tiling Layout

  - Apps are queued by bundle ID
  - If hyper key is held, apps accumulate in the queue
  - If hyper key is not held, the queue is processed immediately
  - When hyper key is released, the queue is processed

  Queue Processing:
  - Each unique app is activated (launched if needed)
  - If only one item was queued, no layout is applied
  - If multiple items were queued, tiling layout is triggered

  Tiling Layout:
  - Target screen: first app's main window > focused window > main screen
  - All standard windows of queued apps are moved to the target screen
  - Screen width is divided by weight (queue count per app)
  - Multiple windows of same app are cascaded within their portion
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
local CASCADE_OFFSET = 24
local queue = {}

--------------------------------------------------
-- Public API
--------------------------------------------------

function M.launchOrFocusOrLayoutByBundle(bundleID)
  table.insert(queue, bundleID)

  if not isHyperHeld() then
    processQueue()
  else
    hyperkey.startPolling()
  end
end

--------------------------------------------------
-- Queue Processing
--------------------------------------------------

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

function activateQueuedApps()
  local counts = {}
  local order = {}
  for _, bundleID in ipairs(queue) do
    if not counts[bundleID] then
      counts[bundleID] = 0
      table.insert(order, bundleID)
    end
    counts[bundleID] = counts[bundleID] + 1
  end

  local apps = {}
  for _, bundleID in ipairs(order) do
    local app = activateApp(bundleID)
    if app then
      table.insert(apps, { app = app, weight = counts[bundleID] })
    end
  end
  return apps
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

function layoutApps(apps, initialFocusedWindow)
  local targetScreen = getTargetScreen(apps)
  local screenFrame = targetScreen:frame()

  local appsWithWindows = {}
  local allWindows = {}
  for _, appLayout in ipairs(apps) do
    local windows = {}
    for _, win in ipairs(appLayout.app:allWindows()) do
      if win:isStandard() then
        table.insert(windows, win)
        table.insert(allWindows, win)
      end
    end
    if #windows > 0 then
      table.insert(appsWithWindows, {
        app = appLayout.app,
        weight = appLayout.weight,
        windows = windows
      })
    end
  end

  if #appsWithWindows > 0 then
    layoutAppsOnScreen(screenFrame, appsWithWindows)
    hs.timer.doAfter(0.01, function()
      restoreFocus(initialFocusedWindow, allWindows, apps)
    end)
  end
end

function layoutAppsOnScreen(screenFrame, apps)
  local totalWeight = 0
  for _, appLayout in ipairs(apps) do
    totalWeight = totalWeight + appLayout.weight
  end

  local appIndex = 0
  for _, appLayout in ipairs(apps) do
    local weight = appLayout.weight / totalWeight
    local windowCount = #appLayout.windows
    for windowIndex, win in ipairs(appLayout.windows) do
      layoutWindow(win, screenFrame, weight, appIndex, windowIndex - 1, windowCount)
    end
    appIndex = appIndex + weight
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
  local cascadeOffset = CASCADE_OFFSET * (windowCount - 1)
  local x = paddedScreen.x + paddedScreen.w * appIndex + halfPad + CASCADE_OFFSET * windowIndex
  local y = paddedScreen.y + halfPad + CASCADE_OFFSET * windowIndex
  local w = paddedScreen.w * weight - PADDING - cascadeOffset
  local h = paddedScreen.h - PADDING - cascadeOffset
  win:setFrame(hs.geometry.rect(x, y, w, h), 0)
end

--------------------------------------------------
-- Helpers
--------------------------------------------------

function isHyperHeld()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.cmd and flags.shift and flags.alt and flags.ctrl
end

function getTargetScreen(apps)
  if #apps > 0 then
    local mainWindow = apps[1].app:mainWindow()
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

function restoreFocus(initialWindow, layoutedWindows, apps)
  if initialWindow then
    local initialId = initialWindow:id()
    for _, win in ipairs(layoutedWindows) do
      if win:id() == initialId then
        initialWindow:focus()
        return
      end
    end
  end

  if #apps > 0 then
    local mainWindow = apps[1].app:mainWindow()
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
