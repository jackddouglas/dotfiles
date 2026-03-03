return {
	paddings = 3,
	group_paddings = 5,

	icons = "sf-symbols", -- alternatively available: NerdFont

	-- This is a font configuration for SF Pro and SF Mono (installed manually)
	font = require("helpers.default_font"),

	-- Animation defaults
	animation = {
		curve = "tanh",
		hover_duration = 12, -- ~0.2s at 60Hz
		transition_duration = 20, -- ~0.33s at 60Hz
	},

	-- Alternatively, this is a font config for JetBrainsMono Nerd Font
	-- font = {
	--   text = "JetBrainsMono Nerd Font", -- Used for text
	--   numbers = "JetBrainsMono Nerd Font", -- Used for numbers
	--   style_map = {
	--     ["Regular"] = "Regular",
	--     ["Semibold"] = "Medium",
	--     ["Bold"] = "SemiBold",
	--     ["Heavy"] = "Bold",
	--     ["Black"] = "ExtraBold",
	--   },
	-- },
}
