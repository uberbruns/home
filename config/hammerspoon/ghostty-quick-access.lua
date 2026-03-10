-- Toggles the Ghostty quick terminal via AppleScript. Hammerspoon handles
-- the global hotkey so the binding works regardless of which app is focused.

--- Hides the Ghostty quick terminal. Called from Python via `hs -c`.
function HideGhosttyQuickAccess()
  hs.osascript.applescript('tell application "Ghostty" to perform action "toggle_quick_terminal" on terminal 1')
end

hs.hotkey.bind({"cmd", "shift"}, "space", function()
  HideGhosttyQuickAccess()
end)
