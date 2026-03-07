-- Tracks hyper key (cmd+alt+ctrl+shift) held state via polling,
-- notifying registered callbacks on release.

local M = {}

--------------------------------------------------
-- State
--------------------------------------------------

local isDown = false
local releaseCallbacks = {}
local releaseCount = 0           -- consecutive polls without hyper pressed
local pollTimer = nil

local RELEASE_THRESHOLD = 3      -- require 3 consecutive non-hyper polls (~100ms at 30Hz)
local SETTLE_DELAY = 0.05        -- seconds to wait after release before notifying

--------------------------------------------------
-- Implementation
--------------------------------------------------

local function isHyperPressed()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.alt and flags.cmd and flags.ctrl and flags.shift
end

-- Invokes all registered release callbacks and resets held state.
local function notifyRelease()
  isDown = false
  for _, callback in ipairs(releaseCallbacks) do
    callback()
  end
end

local function stopPolling()
  if not pollTimer then return end
  pollTimer:stop()
  pollTimer = nil
end

local function pollHyperState()
  if isHyperPressed() then
    if not isDown then
      print("[hyperkey] down")
    end
    isDown = true
    releaseCount = 0
  else
    releaseCount = releaseCount + 1
    if isDown and releaseCount >= RELEASE_THRESHOLD then
      print("[hyperkey] up (after " .. releaseCount .. " polls)")
      stopPolling()
      hs.timer.doAfter(SETTLE_DELAY, notifyRelease)
    end
  end
end

--------------------------------------------------
-- Public API
--------------------------------------------------

--- Registers a callback invoked when the hyper key is released.
function M.onRelease(callback)
  table.insert(releaseCallbacks, callback)
end

--- Begins polling modifier state at 30 Hz with a 5-second safety timeout.
function M.startPolling()
  if pollTimer then return end
  print("[hyperkey] startPolling")
  isDown = true
  releaseCount = 0
  pollTimer = hs.timer.doEvery(1/30, pollHyperState)
  hs.timer.doAfter(5, function()
    if not pollTimer then return end
    stopPolling()
    if isDown then notifyRelease() end
  end)
end

return M
