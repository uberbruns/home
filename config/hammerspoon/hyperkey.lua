local M = {}

local hyperDown = false
local timer = nil
local onReleaseCallbacks = {}

local function isHyper()
  local flags = hs.eventtap.checkKeyboardModifiers()
  return flags.cmd and flags.shift and flags.alt and flags.ctrl
end

local function pollHyperState()
  if isHyper() then
    if not hyperDown then
      hyperDown = true
      print("hyperkey DOWN")
    end
  else
    if hyperDown then
      hyperDown = false
      print("hyperkey UP")
      for _, cb in ipairs(onReleaseCallbacks) do
        cb()
      end
    end
    if timer then
      timer:stop()
      timer = nil
    end
  end
end

local function startPolling()
  if timer then return end
  timer = hs.timer.doEvery(1/30, pollHyperState)
  hs.timer.doAfter(5, function()
    if timer then
      timer:stop()
      timer = nil
      if hyperDown then
        hyperDown = false
        print("hyperkey UP (timeout)")
        for _, cb in ipairs(onReleaseCallbacks) do
          cb()
        end
      end
    end
  end)
end

function M.isDown()
  return hyperDown
end

function M.onRelease(callback)
  table.insert(onReleaseCallbacks, callback)
end

function M.startPolling()
  startPolling()
end

startPolling()

return M
