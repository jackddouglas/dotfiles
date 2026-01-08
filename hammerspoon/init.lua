local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

vim:disableForApp("Ghostty")
	:disableForApp("Terminal")
	:disableForApp("Obsidian")
	:bindHotKeys({ enter = { { "ctrl" }, ";" } })
