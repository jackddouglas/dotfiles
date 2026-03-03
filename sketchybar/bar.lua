local colors = require("colors")

-- Fully transparent bar -- items appear as standalone pills
sbar.bar({
	height = 40,
	color = colors.transparent,
	padding_right = 2,
	padding_left = 2,
	blur_radius = 0,
	shadow = false,
	font_smoothing = true,
})
