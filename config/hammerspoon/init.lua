--    ___                _
--   / _ \___ ___ ___ __(_)______
--  / , _/ -_) _ `/ // / / __/ -_)
-- /_/|_|\__/\_, /\_,_/_/_/  \__/
--           /_/

local hotkeys = require("hotkeys")
local bindApp = hotkeys.bindApp
local bindWindowLocation = hotkeys.bindWindowLocation
local bindCycleWindows = hotkeys.bindCycleWindows
local bindMoveToNextScreen = hotkeys.bindMoveToNextScreen
local tiling = require("tiling")


--   _____          ____
--  / ___/__  ___  / _(_)__ ___ _________
-- / /__/ _ \/ _ \/ _/ / _ `/ // / __/ -_)
-- \___/\___/_//_/_//_/\_, /\_,_/_/  \__/
--                    /___/

require("autoreload")
require("bookmarks")
require("hyperkey")

-- Tiling
tiling.registerApp("ad", "com.seriflabs.affinitydesigner2")
tiling.registerApp("ap", "com.seriflabs.affinityphoto2")
tiling.registerApp("c", "com.tinyspeck.slackmacgap")
tiling.registerApp("d", "com.hnc.Discord")
tiling.registerApp("e", "com.microsoft.VSCode")
tiling.registerApp("f", "com.apple.finder")
tiling.registerApp("g", "com.fournova.Tower3")
tiling.registerApp("mm", "com.apple.MobileSMS")
tiling.registerApp("mo", "com.microsoft.Outlook")
tiling.registerApp("ms", "org.whispersystems.signal-desktop")
tiling.registerApp("mu", "com.apple.Music")
tiling.registerApp("mw", "net.whatsapp.WhatsApp")
tiling.registerApp("nn", "notion.id")
tiling.registerApp("no", "com.apple.Notes")
tiling.registerApp("os", "org.openscad.OpenSCAD")
tiling.registerApp("ph", "com.apple.Photos")
tiling.registerApp("pl", "tv.plex.desktop")
tiling.registerApp("pr", "com.apple.Preview")
tiling.registerApp("pw", "com.1password.1password")
tiling.registerApp("sl", "com.prusa3d.slic3r")
tiling.registerApp("t", "com.mitchellh.ghostty")
tiling.registerApp("v", "com.microsoft.teams2")
tiling.registerApp("w", "com.apple.Safari")
tiling.registerApp("x", "com.apple.dt.Xcode")
tiling.setSplitKey("space")

-- Window Focus
bindCycleWindows("delete")

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


