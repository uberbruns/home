--    ___                _
--   / _ \___ ___ ___ __(_)______
--  / , _/ -_) _ `/ // / / __/ -_)
-- /_/|_|\__/\_, /\_,_/_/_/  \__/
--           /_/

require("hs.ipc")
local windows = require("windows")
local workspace = require("workspace")


--   _____          ____
--  / ___/__  ___  / _(_)__ ___ _________
-- / /__/ _ \/ _ \/ _/ / _ `/ // / __/ -_)
-- \___/\___/_//_/_//_/\_, /\_,_/_/  \__/
--                    /___/

require("kitty-quick-access")
require("selection")

-- Workspace
workspace.registerApp("ad", "com.seriflabs.affinitydesigner2")
workspace.registerApp("ap", "com.seriflabs.affinityphoto2")
workspace.registerApp("c", "com.tinyspeck.slackmacgap")
workspace.registerApp("d", "com.hnc.Discord")
workspace.registerApp("e", "com.microsoft.VSCode")
workspace.registerApp("f", "com.apple.finder")
workspace.registerApp("g", "com.fournova.Tower3")
workspace.registerApp("mm", "com.apple.MobileSMS")
workspace.registerApp("mo", "com.microsoft.Outlook")
workspace.registerApp("ms", "org.whispersystems.signal-desktop")
workspace.registerApp("mt", "com.microsoft.teams2")
workspace.registerApp("mu", "com.apple.Music")
workspace.registerApp("mw", "net.whatsapp.WhatsApp")
workspace.registerApp("nn", "notion.id")
workspace.registerApp("no", "com.apple.Notes")
workspace.registerApp("os", "org.openscad.OpenSCAD")
workspace.registerApp("ph", "com.apple.Photos")
workspace.registerApp("pl", "tv.plex.desktop")
workspace.registerApp("pr", "com.apple.Preview")
workspace.registerApp("pw", "com.1password.1password")
workspace.registerApp("ps", "com.prusa3d.slic3r")
workspace.registerApp("s", "com.apple.iphonesimulator", 1/3)
workspace.registerApp("t", "com.mitchellh.ghostty")
workspace.registerApp("w", "com.apple.Safari")
workspace.registerApp("x", "com.apple.dt.Xcode")
workspace.setSplitKey("space")

-- Window Focus
windows.bindCycleWindows("delete")

-- Window Location
windows.bindWindowLocation("1", 0,   1/4)
windows.bindWindowLocation("2", 1/4, 3/4)
windows.bindWindowLocation("3", 0,   1/3)
windows.bindWindowLocation("4", 1/3, 2/3)
windows.bindWindowLocation("5", 0,   1/2)
windows.bindWindowLocation("6", 1/2, 1/2)
windows.bindWindowLocation("7", 0,   2/3)
windows.bindWindowLocation("8", 2/3, 1/3)
windows.bindWindowLocation("9", 0,   3/4)
windows.bindWindowLocation("0", 1/4, 3/4)
windows.bindWindowLocation("ß", 0,   1)
windows.bindMoveToNextScreen("´")
