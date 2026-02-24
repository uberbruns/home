-- Hyper-key bindings for window positioning, cycling, and screen moves.

local hyper = {"cmd", "alt", "ctrl", "shift"}

local function bindWindowLocation(key, xFraction, widthFraction)
  hs.hotkey.bind(hyper, key, function()
    local win = hs.window.focusedWindow()
    if win then
      local screen = win:screen():frame()
      win:setFrame(hs.geometry.rect(
        screen.x + screen.w * xFraction,
        screen.y,
        screen.w * widthFraction,
        screen.h
      ), 0)
    end
  end)
end

local function bindCycleWindows(key)
  hs.hotkey.bind(hyper, key, function()
    local app = hs.application.frontmostApplication()
    if not app then return end
    local appWindows = {}
    for _, win in ipairs(hs.window.orderedWindows()) do
      if win:application() == app then
        table.insert(appWindows, win)
      end
    end
    if #appWindows > 1 then
      appWindows[#appWindows]:focus()
    end
  end)
end

local function bindMoveToNextScreen(key)
  hs.hotkey.bind(hyper, key, function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveToScreen(win:screen():next(), false, true, 0)
      win:maximize(0)
    end
  end)
end

return {
  bindCycleWindows = bindCycleWindows,
  bindMoveToNextScreen = bindMoveToNextScreen,
  bindWindowLocation = bindWindowLocation,
}
