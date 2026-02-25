-- Persistent quick-access terminal panel (kitty-quick-access) toggled via
-- Cmd+Space. Draws a full-screen dark overlay and purple border as backdrop
-- while the panel is active. Hides panel and backdrop on focus loss.
--
-- Globals:
--   HideQuickAccess()              — IPC entry point called from Python via `hs -c`
--   SuppressQuickAccessAutoHide()  — temporarily disables focus-loss hiding
--   QuickAccessWatcher             — prevents garbage collection after require()

--------------------------------------------------
-- Configuration
--------------------------------------------------

local APP_NAME = "kitty-quick-access"
local BORDER_COLOR = { hex = "#a277ff" }
local BORDER_WIDTH = 2
local FADE_DURATION = 0
local OVERLAY_COLOR = { black = true, alpha = 0.8 }

--------------------------------------------------
-- State
--------------------------------------------------

local borderCanvas = nil
local isBackdropVisible = false
local isSuppressingAutoHide = false
local overlayCanvas = nil

--------------------------------------------------
-- Canvas Helpers
--------------------------------------------------

-- Creates a full-screen dark overlay on the given screen.
local function createOverlayCanvas(screen)
  local canvas = hs.canvas.new(screen:fullFrame())
  canvas[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = OVERLAY_COLOR,
    frame = { x = "0%", y = "0%", h = "100%", w = "100%" },
  }
  canvas:level(hs.canvas.windowLevels.modalPanel)
  canvas:show(FADE_DURATION)
  return canvas
end

-- Creates a purple stroke border around the given window frame.
local function createBorderCanvas(windowFrame)
  local canvas = hs.canvas.new({
    h = windowFrame.h + BORDER_WIDTH * 2,
    w = windowFrame.w + BORDER_WIDTH * 2,
    x = windowFrame.x - BORDER_WIDTH,
    y = windowFrame.y - BORDER_WIDTH,
  })
  canvas[1] = {
    type = "rectangle",
    action = "stroke",
    strokeColor = BORDER_COLOR,
    strokeWidth = BORDER_WIDTH * 2,
  }
  canvas:level(hs.canvas.windowLevels.popUpMenu)
  canvas:show(FADE_DURATION)
  return canvas
end

-- Fades out and deletes a canvas.
local function fadeOutCanvas(canvas)
  canvas:hide(FADE_DURATION)
  hs.timer.doAfter(FADE_DURATION + 0.05, function() canvas:delete() end)
end

--------------------------------------------------
-- Backdrop
--------------------------------------------------

local function showBackdrop()
  if isBackdropVisible then return end

  local app = hs.application.get(APP_NAME)
  if not app then return end
  local window = app:mainWindow()
  if not window then return end

  isBackdropVisible = true
  overlayCanvas = createOverlayCanvas(window:screen())
  borderCanvas = createBorderCanvas(window:frame())
end

local function hideBackdrop()
  if not isBackdropVisible then return end
  isBackdropVisible = false

  if borderCanvas then
    fadeOutCanvas(borderCanvas)
    borderCanvas = nil
  end
  if overlayCanvas then
    fadeOutCanvas(overlayCanvas)
    overlayCanvas = nil
  end
end

--------------------------------------------------
-- Panel Control
--------------------------------------------------

--- Hides the quick-access panel. Called from Python via `hs -c`.
function HideQuickAccess()
  local app = hs.application.get(APP_NAME)
  if app then app:hide() end
end

--- Temporarily prevents the watcher from hiding the panel on focus loss.
--- Used during clipboard fallback to briefly focus the source app.
--- The flag is cleared on the next run loop iteration via doAfter(0).
function SuppressQuickAccessAutoHide()
  isSuppressingAutoHide = true
  hs.timer.doAfter(0, function() isSuppressingAutoHide = false end)
end

hs.hotkey.bind({"cmd"}, "space", function()
  local app = hs.application.get(APP_NAME)

  -- Toggle off when panel is focused
  if app and app:isFrontmost() then
    app:hide()
    return
  end

  -- Grab element reference (deferred read happens after panel is visible)
  CaptureSelectionForPicker()

  -- Reactivate existing panel or cold-start a new one
  if app then
    app:activate()
  else
    hs.task.new("/opt/homebrew/bin/kitten", nil, {
      "quick-access-terminal", os.getenv("HOME"),
    }):start()
  end
end)

--------------------------------------------------
-- Application Watcher
--------------------------------------------------

QuickAccessWatcher = hs.application.watcher.new(function(appName, eventType)
  if eventType == hs.application.watcher.activated then
    if appName == APP_NAME then
      showBackdrop()
    elseif isBackdropVisible and not isSuppressingAutoHide then
      hideBackdrop()
    end
    return
  end

  if appName ~= APP_NAME then return end

  if eventType == hs.application.watcher.deactivated then
    if not isSuppressingAutoHide then
      hideBackdrop()
      local app = hs.application.get(APP_NAME)
      if app then app:hide() end
    end
  elseif eventType == hs.application.watcher.terminated then
    hideBackdrop()
  end
end)

QuickAccessWatcher:start()
