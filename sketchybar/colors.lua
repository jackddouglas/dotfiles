return {
	black = 0xFF100F0F,
	white = 0xFFCECDC3,
	red = 0xFFD14D41,
	green = 0xFF879A39,
	blue = 0xFF4385BE,
	yellow = 0xFFD0A215,
	orange = 0xFFDA702C,
	magenta = 0xFFCE5D97,
	grey = 0xFF575653,
	transparent = 0x00000000,

	bar = {
		bg = 0x7F000000,
		border = 0xff2c2e34,
	},
	popup = {
		bg = 0xc02c2e34,
		border = 0xff7f8490,
	},
	bg1 = 0xFF343331,
	bg2 = 0xFF403E3C,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
