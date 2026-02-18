local hyper = {"cmd", "alt", "ctrl", "shift"}
local tiling = require("tiling")

local function registerApp(shortcut, bundleID)
  tiling.registerApp(shortcut, bundleID)
end

local function bindAppByBundle(key, bundleID)
  hs.hotkey.bind(hyper, key, function()
    tiling.launchOrFocusOrLayoutByBundle(bundleID)
  end)
end

local function bindApp(key, app)
  hs.hotkey.bind(hyper, key, function()
    local alreadyRunning = hs.application.get(app) ~= nil
    hs.application.launchOrFocus(app)
    if not alreadyRunning then
      hs.timer.doAfter(0.25, function()
        local launched = hs.application.get(app)
        if launched then
          local win = launched:mainWindow()
          if win then win:maximize(0) end
        end
      end)
    end
  end)
end

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

local function bindXcode(key)
  hs.hotkey.bind(hyper, key, function()
    local path = hs.execute("/usr/bin/xcrun -f xcodebuild"):match("(.+%.app)")
    hs.execute("open " .. path)
  end)
end

return {
  registerApp = registerApp,
  bindApp = bindApp,
  bindAppByBundle = bindAppByBundle,
  bindCycleWindows = bindCycleWindows,
  bindMoveToNextScreen = bindMoveToNextScreen,
  bindWindowLocation = bindWindowLocation,
  bindXcode = bindXcode,
}
