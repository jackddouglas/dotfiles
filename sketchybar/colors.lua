-- Detect macOS system accent color at startup
local accent_map = {
	["-1"] = 0xFF8E8E93, -- Graphite (systemGray)
	["0"] = 0xFFFF3B30, -- Red
	["1"] = 0xFFFF9F0A, -- Orange
	["2"] = 0xFFFFD60A, -- Yellow
	["3"] = 0xFF30D158, -- Green
	["5"] = 0xFFBF5AF2, -- Purple
	["6"] = 0xFFFF375F, -- Pink
}

local function get_system_accent()
	local handle = io.popen("defaults read -g AppleAccentColor 2>/dev/null")
	if handle then
		local result = handle:read("*l")
		handle:close()
		if result and accent_map[result] then
			return accent_map[result]
		end
	end
	return 0xFF007AFF -- Blue (macOS default)
end

local accent = get_system_accent()

return {
	-- macOS system colors (dark mode)
	black = 0xFF000000,
	white = 0xFFFFFFFF,
	red = 0xFFFF3B30,
	green = 0xFF30D158,
	blue = 0xFF007AFF,
	yellow = 0xFFFFD60A,
	orange = 0xFFFF9F0A,
	magenta = 0xFFFF375F,
	purple = 0xFFBF5AF2,
	grey = 0xFF8E8E93,
	transparent = 0x00000000,

	-- System accent (respects user preference)
	accent = accent,

	-- Semantic text colors (macOS dark mode label hierarchy)
	text = {
		primary = 0xFFFFFFFF,
		secondary = 0x99EBEBF5,
		tertiary = 0x4DEBEBF5,
		quaternary = 0x29EBEBF5,
	},

	-- Pill backgrounds (frosted glass effect -- used with blur_radius on items)
	bar = {
		bg = 0x663A3A3C,
	},
	-- Slightly brighter on hover
	hover_bg = 0x80484848,

	-- Popup menus
	popup = {
		bg = 0xE61C1C1E,
		border = 0x33FFFFFF,
	},

	-- Background fills (macOS dark mode system backgrounds)
	bg1 = 0xFF1C1C1E,
	bg2 = 0xFF2C2C2E,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
