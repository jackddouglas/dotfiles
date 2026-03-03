local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
	icon = {
		color = colors.text.secondary,
		padding_left = 8,
		font = {
			style = settings.font.style_map["Black"],
			size = 12.0,
		},
	},
	label = {
		color = colors.text.primary,
		padding_right = 8,
		width = 49,
		align = "right",
		font = { family = settings.font.numbers },
	},
	position = "right",
	padding_left = 1,
	padding_right = 1,
	background = {
		color = colors.transparent,
		height = 28,
		corner_radius = 9,
	},
	click_script = "open -a 'Calendar'",
})

-- Padding item
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe("mouse.entered", function()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		cal:set({ background = { color = colors.hover_bg } })
	end)
end)

cal:subscribe("mouse.exited", function()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		cal:set({ background = { color = colors.transparent } })
	end)
end)

local function update_calendar()
	cal:set({ icon = os.date("%a %d %b"), label = os.date("%H:%M") })

	-- Schedule next update at exact minute boundary
	local seconds_until_next_minute = 60 - (os.time() % 60)
	sbar.delay(seconds_until_next_minute, update_calendar)
end

cal:subscribe({ "forced", "routine", "system_woke" }, update_calendar)
