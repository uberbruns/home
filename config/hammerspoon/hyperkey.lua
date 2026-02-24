-- Tracks hyper key (cmd+alt+ctrl+shift) held state via polling,
-- notifying registered callbacks on release.

local M = {}

--------------------------------------------------
-- State
--------------------------------------------------

local isDown = false
local releaseCallbacks = {}
local pollTimer = nil

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
    isDown = true
  else
    if isDown then notifyRelease() end
    stopPolling()
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
  pollTimer = hs.timer.doEvery(1/30, pollHyperState)
  hs.timer.doAfter(5, function()
    if not pollTimer then return end
    stopPolling()
    if isDown then notifyRelease() end
  end)
end

return M
