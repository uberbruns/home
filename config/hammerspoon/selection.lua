--[[
  Text selection capture and deferred replacement for the quick-access picker.

  Flow:
  1. Hotkey fires → captureSelectionForPicker() reads the active selection
  2. Picker opens (kitty-quick-access)
  3. Picker calls ipcGetCapturedSelection() via hs CLI to read the stored text
  4. Picker calls ipcQueueReplacement(text) to register the chosen replacement
  5. Picker closes → applyQueuedReplacement() pastes the replacement into the
     original app once it regains focus

  ipcGetCapturedSelection, ipcQueueReplacement, captureSelectionForPicker, and
  applyQueuedReplacement are globals (not locals) so they remain reachable after
  require() returns. Local variables are garbage collected once the module chunk
  finishes executing, silently making them unreachable.

  Glossary:
  - element: focused AXUIElement (text field, editor, etc.)
  - range:   NSRange table { location = <int>, length = <int> }
]]

--------------------------------------------------
-- Configuration
--------------------------------------------------

local COPY_PASTE_DELAY_US   = 150000 -- 150ms; increase if apps respond slowly
local FOCUS_RESTORE_DELAY_S = 0.15   -- seconds to wait for original app to regain focus

--------------------------------------------------
-- State
--------------------------------------------------

local capturedSelection = nil
local queuedReplacement = nil

--------------------------------------------------
-- Accessibility
--------------------------------------------------

-- Splices replacement into AXValue at AXSelectedTextRange and repositions the cursor.
-- Returns true on success; false if the element does not expose a writable AXValue.
local function writeSelectionViaAccessibility(element, replacement)
  local value = element:attributeValue("AXValue")
  local range = element:attributeValue("AXSelectedTextRange")
  if not value or not range then return false end

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

--------------------------------------------------
-- Clipboard Fallback
--------------------------------------------------

-- Simulates Cmd+C to copy the selection, then restores the prior clipboard contents.
local function readSelectionViaClipboard()
  local saved = hs.pasteboard.getContents()
  hs.pasteboard.setContents("")
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.usleep(COPY_PASTE_DELAY_US)
  local selected = hs.pasteboard.getContents()
  hs.pasteboard.setContents(saved or "")
  return (selected and #selected > 0) and selected or nil
end

-- Writes replacement to clipboard, simulates Cmd+V to paste, then restores the prior clipboard.
local function writeSelectionViaClipboard(replacement)
  local saved = hs.pasteboard.getContents()
  hs.pasteboard.setContents(replacement)
  hs.eventtap.keyStroke({"cmd"}, "v")
  hs.timer.usleep(COPY_PASTE_DELAY_US)
  hs.pasteboard.setContents(saved or "")
end

--------------------------------------------------
-- Selection Capture
--------------------------------------------------

-- Reads the current selection from the focused element, with clipboard fallback.
local function readCurrentSelection()
  local element = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  if element then
    local text = element:attributeValue("AXSelectedText")
    if text and #text > 0 then return text end
  end
  return readSelectionViaClipboard()
end

--------------------------------------------------
-- Public API (called from init.lua)
--------------------------------------------------

-- Captures the active selection before the picker opens. Resets any pending replacement.
function captureSelectionForPicker()
  capturedSelection = readCurrentSelection()
  queuedReplacement = nil
end

-- Applies the queued replacement once the picker closes and the original app regains focus.
-- No-op if no replacement was queued.
function applyQueuedReplacement()
  if not queuedReplacement then return end

  local replacement = queuedReplacement
  queuedReplacement = nil
  capturedSelection = nil

  hs.timer.doAfter(FOCUS_RESTORE_DELAY_S, function()
    local element = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    if element and writeSelectionViaAccessibility(element, replacement) then return end
    writeSelectionViaClipboard(replacement)
  end)
end

--------------------------------------------------
-- Public IPC API (called via hs CLI)
--------------------------------------------------

--- Returns the selection captured at picker launch as a JSON array, or "null".
function ipcGetCapturedSelection()
  if capturedSelection == nil then return "null" end
  return hs.json.encode({capturedSelection})
end

--- Queues text to be inserted when the picker closes. Accepts a JSON array.
function ipcQueueReplacement(jsonText)
  queuedReplacement = hs.json.decode(jsonText)[1]
end
