--[[
  Selection bridge between the source app and the quick-access picker.

sh
sh

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
-- Focus
--------------------------------------------------

-- Activates the app and polls until it becomes frontmost.
local function ensureSourceAppFocused(app)
  if not app then return end
  if app:isFrontmost() then return end
  app:activate()
  for _ = 1, FOCUS_POLL_MAX_TRIES do
    hs.timer.usleep(FOCUS_POLL_US)
    if app:isFrontmost() then return end
  end
end

--------------------------------------------------
-- Selection Reading
--------------------------------------------------

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
  if not app then return nil end

  -- Focus source app without hiding the panel
  SuppressQuickAccessAutoHide()
  ensureSourceAppFocused(app)
  if not app:isFrontmost() then return nil end

  -- Simulate copy and restore clipboard
  local saved = hs.pasteboard.getContents()
  hs.pasteboard.setContents("")
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.usleep(COPY_PASTE_DELAY_US)
  local selected = hs.pasteboard.getContents()
  hs.pasteboard.setContents(saved or "")

  -- Refocus the quick-access panel
  local panel = hs.application.get("kitty-quick-access")
  if panel then panel:activate() end

  if selected and #selected > 0 then return selected end
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
    if element and writeSelectionViaAccessibility(element, replacement) then
      HideQuickAccess()
      return
    end
  end
  writeSelectionViaClipboard(replacement)
  HideQuickAccess()
end

--------------------------------------------------
-- IPC API (called from Python via `hs -c`)
--------------------------------------------------

--- Returns the captured selection as a JSON array, or "null".
--- Reads lazily on first call: AXSelectedText, then clipboard fallback.
function IpcGetCapturedSelection()
  if selectionText == nil and sourceElement then
    selectionText = readSelectionViaAccessibility(sourceElement)
    if selectionText then
      usedAccessibility = true
    else
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
