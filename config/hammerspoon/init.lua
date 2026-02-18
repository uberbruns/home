--    ___                _
--   / _ \___ ___ ___ __(_)______
--  / , _/ -_) _ `/ // / / __/ -_)
-- /_/|_|\__/\_, /\_,_/_/_/  \__/
--           /_/

local hotkeys = require("hotkeys")
local bindApp = hotkeys.bindApp
local bindAppByBundle = hotkeys.bindAppByBundle
local bindWindowLocation = hotkeys.bindWindowLocation
local bindCycleWindows = hotkeys.bindCycleWindows
local bindMoveToNextScreen = hotkeys.bindMoveToNextScreen


--   _____          ____
--  / ___/__  ___  / _(_)__ ___ _________
-- / /__/ _ \/ _ \/ _/ / _ `/ // / __/ -_)
-- \___/\___/_//_/_//_/\_, /\_,_/_/  \__/
--                    /___/

require("autoreload")
require("bookmarks")
require("hyperkey")

local launcher = require("launchOrFocusOrLayoutByBundle")

-- Apps
bindAppByBundle("t", "com.mitchellh.ghostty")
bindAppByBundle("e", "com.microsoft.VSCode")
bindAppByBundle("f", "com.apple.finder")
bindAppByBundle("w", "com.apple.Safari")
bindAppByBundle("x", "com.apple.dt.Xcode")
bindAppByBundle("p", "tv.plex.desktop")
bindAppByBundle("c", "com.tinyspeck.slackmacgap")
bindAppByBundle("d", "com.hnc.Discord")
bindAppByBundle("s", "org.whispersystems.signal-desktop")
bindAppByBundle("r", "com.prusa3d.slic3r")
bindAppByBundle("o", "org.openscad.OpenSCAD")

-- Window Focus
bindCycleWindows("delete")

-- Layout
launcher.bindSplitLayoutAction("space")

-- Window Location
bindWindowLocation("1", 0,   1/4) 
bindWindowLocation("2", 1/4, 3/4)
bindWindowLocation("3", 0,   1/3)
bindWindowLocation("4", 1/3, 2/3)
bindWindowLocation("5", 0,   1/2)
bindWindowLocation("6", 1/2, 1/2)
bindWindowLocation("7", 0,   2/3)
bindWindowLocation("8", 2/3, 1/3)
bindWindowLocation("9", 0,   3/4)
bindWindowLocation("0", 1/4, 3/4)
bindWindowLocation("ß", 0,   1)
bindMoveToNextScreen("´")


