-- Draws a dark overlay and purple border behind the kitty-quick-access
-- window on activation. Both are removed on deactivation or termination.

--------------------------------------------------
-- Configuration
--------------------------------------------------

local APP_NAME = "kitty-quick-access"
local BORDER_COLOR = { hex = "#a277ff" }
local BORDER_WIDTH = 2
local FADE_IN = 0.3
local FADE_OUT = 0.3
local OVERLAY_COLOR = { black = true, alpha = 0.8 }

--------------------------------------------------
-- State
--------------------------------------------------

local borderCanvas = nil
local isBackdropVisible = false
local overlayCanvas = nil

--------------------------------------------------
-- Canvas Helpers
--------------------------------------------------

-- Creates and shows a full-screen dark overlay.
local function createOverlayCanvas()
  local screenFrame = hs.screen.mainScreen():fullFrame()

  local canvas = hs.canvas.new(screenFrame)
  canvas[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = OVERLAY_COLOR,
    frame = { x = "0%", y = "0%", h = "100%", w = "100%" },
  }
  canvas:level(hs.canvas.windowLevels.modalPanel)
  canvas:show(FADE_IN)
  return canvas
end

-- Creates and shows a purple stroke border around the given window frame.
local function createBorderCanvas(windowFrame)
  local canvasFrame = {
    h = windowFrame.h + BORDER_WIDTH * 2,
    w = windowFrame.w + BORDER_WIDTH * 2,
    x = windowFrame.x - BORDER_WIDTH,
    y = windowFrame.y - BORDER_WIDTH,
  }

  local canvas = hs.canvas.new(canvasFrame)
  canvas[1] = {
    type = "rectangle",
    action = "stroke",
    strokeColor = BORDER_COLOR,
    strokeWidth = BORDER_WIDTH * 2,
  }
  canvas:level(hs.canvas.windowLevels.popUpMenu)
  canvas:show(FADE_IN)
  return canvas
end

-- Fades out and deletes a canvas after the fade completes.
local function deleteCanvas(canvas)
  canvas:hide(FADE_OUT)
  hs.timer.doAfter(FADE_OUT + 0.05, function() canvas:delete() end)
end

--------------------------------------------------
-- Backdrop Lifecycle
--------------------------------------------------

local function showBackdrop()
  if isBackdropVisible then return end
  isBackdropVisible = true

  overlayCanvas = createOverlayCanvas()

  -- Border around kitty window
  local app = hs.application.get(APP_NAME)
  if not app then return end
  local window = app:mainWindow()
  if not window then return end
  borderCanvas = createBorderCanvas(window:frame())
end

local function hideBackdrop()
  if not isBackdropVisible then return end
  isBackdropVisible = false

  if borderCanvas then
    deleteCanvas(borderCanvas)
    borderCanvas = nil
  end
  if overlayCanvas then
    deleteCanvas(overlayCanvas)
    overlayCanvas = nil
  end
end

--------------------------------------------------
-- Application Watcher
--------------------------------------------------

-- Global to prevent garbage collection after require() returns.
KittenWatcher = hs.application.watcher.new(function(appName, eventType)
  if eventType == hs.application.watcher.activated then
    if appName == APP_NAME then
      showBackdrop()
    elseif isBackdropVisible then
      hideBackdrop()
    end
    return
  end

  if appName ~= APP_NAME then return end

  if eventType == hs.application.watcher.deactivated
      or eventType == hs.application.watcher.terminated then
    hideBackdrop()
  end
end)

KittenWatcher:start()
