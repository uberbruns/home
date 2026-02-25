--[[
  Selection bridge between the source app and the quick-access picker.

  Captures a reference to the focused UI element at hotkey time (near-zero
  cost). The actual text is read lazily when the picker requests it — first
  via AXSelectedText, falling back to Cmd+C with auto-hide suppressed.
  Replacement uses the same channel that succeeded for reading.

  Globals (called from kitty-quick-access.lua):
    CaptureSelectionForPicker()  — saves element ref and source app
    ApplyQueuedReplacement()     — writes replacement into source app

  IPC globals (called from Python via `hs -c`):
    IpcGetCapturedSelection()    — returns selection as JSON array or "null"
    IpcQueueReplacement(json)    — queues replacement text

  Glossary:
    element — focused AXUIElement (text field, editor, etc.)
    range   — NSRange table { location = <int>, length = <int> }
]]

--------------------------------------------------
-- Configuration
--------------------------------------------------

local COPY_PASTE_DELAY_US  = 150000 -- 150ms; increase if apps respond slowly
local FOCUS_POLL_US        = 10000  -- 10ms per poll iteration
local FOCUS_POLL_MAX_TRIES = 5      -- give up after 50ms

--------------------------------------------------
-- State
--------------------------------------------------

local queuedReplacement = nil
local selectionText = nil
local sourceApp = nil
local sourceElement = nil
local usedAccessibility = false

--------------------------------------------------
-- Selection Reading
--------------------------------------------------

-- Ensures the source app is frontmost, activating it if needed.
-- Polls in short intervals to minimize wait time.
local function ensureSourceAppFocused(app)
  if not app then return end
  if app:isFrontmost() then
    print("[selection] focus: " .. app:name() .. " already frontmost")
    return
  end
  print("[selection] focus: calling activate() on " .. app:name())
  app:activate()
  for i = 1, FOCUS_POLL_MAX_TRIES do
    hs.timer.usleep(FOCUS_POLL_US)
    if app:isFrontmost() then
      print("[selection] focus: " .. app:name() .. " became frontmost after " .. (i * FOCUS_POLL_US / 1000) .. "ms")
      return
    end
  end
  print("[selection] focus: " .. app:name() .. " NOT frontmost after " .. (FOCUS_POLL_MAX_TRIES * FOCUS_POLL_US / 1000) .. "ms")
end

-- Reads AXSelectedText from the given element.
local function readSelectionViaAccessibility(element)
  if not element then return nil end
  local text = element:attributeValue("AXSelectedText")
  if text and #text > 0 then return text end
  return nil
end

-- Focuses the source app, simulates Cmd+C, reads clipboard, restores it.
-- Suppresses quick-access auto-hide during the focus switch.
local function readSelectionViaClipboard(app)
  if not app then
    print("[selection] clipboard: no source app, skipping")
    return nil
  end

  print("[selection] clipboard: suppressing auto-hide")
  SuppressQuickAccessAutoHide()

  print("[selection] clipboard: activating " .. app:name() .. " (pid " .. app:pid() .. ")")
  ensureSourceAppFocused(app)

  if not app:isFrontmost() then
    print("[selection] clipboard: FAILED to focus " .. app:name() .. " after polling")
    return nil
  end
  print("[selection] clipboard: " .. app:name() .. " is frontmost")

  -- Copy selection and restore clipboard
  local saved = hs.pasteboard.getContents()
  print("[selection] clipboard: saved clipboard (" .. (saved and #saved or 0) .. " chars)")
  hs.pasteboard.setContents("")
  print("[selection] clipboard: sending Cmd+C")
  hs.eventtap.keyStroke({"cmd"}, "c")
  print("[selection] clipboard: waiting " .. (COPY_PASTE_DELAY_US / 1000) .. "ms for copy")
  hs.timer.usleep(COPY_PASTE_DELAY_US)
  local selected = hs.pasteboard.getContents()
  print("[selection] clipboard: pasteboard contains " .. (selected and #selected or 0) .. " chars")
  hs.pasteboard.setContents(saved or "")
  print("[selection] clipboard: restored previous clipboard")

  if selected and #selected > 0 then
    print("[selection] clipboard: SUCCESS captured " .. #selected .. " chars")
    return selected
  end
  print("[selection] clipboard: no selection found")
  return nil
end

--------------------------------------------------
-- Selection Writing
--------------------------------------------------

-- Splices replacement into AXValue at AXSelectedTextRange.
local function writeSelectionViaAccessibility(element, replacement)
  local range = element:attributeValue("AXSelectedTextRange")
  local value = element:attributeValue("AXValue")
  if not range or not value then return false end

  local newValue = value:sub(1, range.location)
    .. replacement
    .. value:sub(range.location + range.length + 1)
  if not element:setAttributeValue("AXValue", newValue) then return false end

  element:setAttributeValue("AXSelectedTextRange", {
    location = range.location + #replacement,
    length = 0,
  })
  return true
end

-- Pastes replacement via Cmd+V, restoring the prior clipboard contents.
local function writeSelectionViaClipboard(replacement)
  local saved = hs.pasteboard.getContents()
  hs.pasteboard.setContents(replacement)
  hs.eventtap.keyStroke({"cmd"}, "v")
  hs.timer.usleep(COPY_PASTE_DELAY_US)
  hs.pasteboard.setContents(saved or "")
end

--------------------------------------------------
-- Public API (called from kitty-quick-access.lua)
--------------------------------------------------

--- Saves the focused element and source app for deferred selection reading.
function CaptureSelectionForPicker()
  queuedReplacement = nil
  selectionText = nil
  sourceApp = hs.application.frontmostApplication()
  sourceElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  usedAccessibility = false
end

--- Writes the queued replacement into the source app.
--- Activates the source app if it hasn't regained focus yet.
--- Uses the same channel (AX or clipboard) that succeeded for reading.
function ApplyQueuedReplacement()
  if not queuedReplacement then return end

  local app = sourceApp
  local replacement = queuedReplacement
  local restoreViaAccessibility = usedAccessibility
  queuedReplacement = nil
  selectionText = nil
  sourceApp = nil
  usedAccessibility = false

  ensureSourceAppFocused(app)

  if restoreViaAccessibility then
    local element = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    if element and writeSelectionViaAccessibility(element, replacement) then return end
  end
  writeSelectionViaClipboard(replacement)
end

--------------------------------------------------
-- IPC API (called from Python via `hs -c`)
--------------------------------------------------

--- Returns the captured selection as a JSON array, or "null".
--- Reads lazily on first call: AXSelectedText, then clipboard fallback.
function IpcGetCapturedSelection()
  if selectionText == nil and sourceElement then
    print("[selection] read: trying AXSelectedText")
    selectionText = readSelectionViaAccessibility(sourceElement)
    if selectionText then
      print("[selection] read: AX succeeded (" .. #selectionText .. " chars)")
      usedAccessibility = true
    else
      print("[selection] read: AX returned nothing, trying clipboard fallback")
      selectionText = readSelectionViaClipboard(sourceApp)
    end
    sourceElement = nil
  end
  if selectionText == nil then return "null" end
  return hs.json.encode({selectionText})
end

--- Queues text to replace the captured selection when the picker closes.
function IpcQueueReplacement(jsonText)
  queuedReplacement = hs.json.decode(jsonText)[1]
end
