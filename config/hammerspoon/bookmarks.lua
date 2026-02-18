local function readSafariBookmarks()
  local plist = hs.plist.read(os.getenv("HOME") .. "/Library/Safari/Bookmarks.plist")
  if not plist then return {} end

  local bookmarks = {}
  local function extract(node, folder)
    if node.WebBookmarkType == "WebBookmarkTypeList" then
      local name = node.Title or folder
      for _, child in ipairs(node.Children or {}) do
        extract(child, name)
      end
    elseif node.WebBookmarkType == "WebBookmarkTypeLeaf" then
      local url = node.URLString or ""
      local title = (node.URIDictionary or {}).title or url
      if url ~= "" then
        table.insert(bookmarks, {
          text = title,
          subText = folder .. " — " .. url,
          url = url,
          image = nil,
        })
      end
    end
  end

  extract(plist, "")
  return bookmarks
end

local chooser = hs.chooser.new(function(choice)
  if choice then
    hs.urlevent.openURL(choice.url)
  end
end)

hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "b", function()
  chooser:choices(readSafariBookmarks())
  chooser:show()
end)
