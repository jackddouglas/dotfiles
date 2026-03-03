local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
	icon = {
		font = { size = 16.0 },
		string = icons.apple,
		padding_right = 8,
		padding_left = 8,
	},
	label = { drawing = false },
	background = {
		color = colors.transparent,
		height = 28,
		corner_radius = 9,
	},
	padding_left = 1,
	padding_right = 1,
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

apple:subscribe("mouse.entered", function()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		apple:set({ background = { color = colors.bar.bg } })
	end)
end)

apple:subscribe("mouse.exited", function()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		apple:set({ background = { color = colors.transparent } })
	end)
end)

-- Padding item
sbar.add("item", { width = 7 })
