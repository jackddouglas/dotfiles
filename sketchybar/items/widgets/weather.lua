local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local location_file = os.getenv("HOME") .. "/.config/sketchybar/weather_location"
local popup_width = 250

-- Read location from file, default to London
local function get_location()
	local f = io.open(location_file, "r")
	if f then
		local loc = f:read("*l")
		f:close()
		if loc and loc ~= "" then
			return loc
		end
	end
	return "London"
end

-- Save location to file
local function save_location(loc)
	local f = io.open(location_file, "w")
	if f then
		f:write(loc)
		f:close()
	end
end

-------------------------------------------------------------------------------
-- Icon mapping
-------------------------------------------------------------------------------

-- Map WWO weather condition codes (wttr.in) to icons
local wwo_icons = {
	[113] = icons.weather.sunny,
	[116] = icons.weather.partly_cloudy,
	[119] = icons.weather.cloudy,
	[122] = icons.weather.cloudy,
	[143] = icons.weather.fog,
	[248] = icons.weather.fog,
	[260] = icons.weather.fog,
	[200] = icons.weather.thunder,
	[386] = icons.weather.thunder,
	[389] = icons.weather.thunder,
	[392] = icons.weather.thunder,
	[395] = icons.weather.thunder,
}

-- Rain codes
for _, code in ipairs({
	176,
	263,
	266,
	281,
	284,
	293,
	296,
	299,
	302,
	305,
	308,
	311,
	314,
	317,
	350,
	353,
	356,
	359,
	362,
	365,
	374,
	377,
}) do
	wwo_icons[code] = icons.weather.rain
end

-- Snow codes
for _, code in ipairs({
	179,
	182,
	185,
	227,
	230,
	320,
	323,
	326,
	329,
	332,
	335,
	338,
	368,
	371,
}) do
	wwo_icons[code] = icons.weather.snow
end

-- WMO weather codes (Open-Meteo) to icon + description
local wmo_table = {
	[0] = { icon = icons.weather.sunny, desc = "Clear sky" },
	[1] = { icon = icons.weather.sunny, desc = "Mainly clear" },
	[2] = { icon = icons.weather.partly_cloudy, desc = "Partly cloudy" },
	[3] = { icon = icons.weather.cloudy, desc = "Overcast" },
	[45] = { icon = icons.weather.fog, desc = "Fog" },
	[48] = { icon = icons.weather.fog, desc = "Rime fog" },
	[51] = { icon = icons.weather.rain, desc = "Light drizzle" },
	[53] = { icon = icons.weather.rain, desc = "Moderate drizzle" },
	[55] = { icon = icons.weather.rain, desc = "Dense drizzle" },
	[56] = { icon = icons.weather.rain, desc = "Freezing drizzle" },
	[57] = { icon = icons.weather.rain, desc = "Heavy freezing drizzle" },
	[61] = { icon = icons.weather.rain, desc = "Slight rain" },
	[63] = { icon = icons.weather.rain, desc = "Moderate rain" },
	[65] = { icon = icons.weather.rain, desc = "Heavy rain" },
	[66] = { icon = icons.weather.rain, desc = "Light freezing rain" },
	[67] = { icon = icons.weather.rain, desc = "Heavy freezing rain" },
	[71] = { icon = icons.weather.snow, desc = "Slight snowfall" },
	[73] = { icon = icons.weather.snow, desc = "Moderate snowfall" },
	[75] = { icon = icons.weather.snow, desc = "Heavy snowfall" },
	[77] = { icon = icons.weather.snow, desc = "Snow grains" },
	[80] = { icon = icons.weather.rain, desc = "Slight rain showers" },
	[81] = { icon = icons.weather.rain, desc = "Moderate rain showers" },
	[82] = { icon = icons.weather.rain, desc = "Violent rain showers" },
	[85] = { icon = icons.weather.snow, desc = "Slight snow showers" },
	[86] = { icon = icons.weather.snow, desc = "Heavy snow showers" },
	[95] = { icon = icons.weather.thunder, desc = "Thunderstorm" },
	[96] = { icon = icons.weather.thunder, desc = "Thunderstorm, slight hail" },
	[99] = { icon = icons.weather.thunder, desc = "Thunderstorm, heavy hail" },
}

-------------------------------------------------------------------------------
-- UI items
-------------------------------------------------------------------------------

local weather = sbar.add("item", "widgets.weather", {
	position = "right",
	updates = "on",
	icon = {
		string = icons.weather.default,
		font = {
			style = settings.font.style_map["Regular"],
			size = 16.0,
		},
		color = colors.white,
	},
	label = {
		string = "...",
		font = { family = settings.font.numbers },
		color = colors.text.primary,
	},
	update_freq = 900,
	popup = { align = "center" },
})

local location_label = sbar.add("item", {
	position = "popup." .. weather.name,
	icon = {
		string = "Location:",
		width = popup_width / 2,
		align = "left",
		font = { style = settings.font.style_map["Bold"] },
		color = colors.text.secondary,
	},
	label = {
		string = get_location(),
		width = popup_width / 2,
		align = "right",
		font = {
			size = 15,
			style = settings.font.style_map["Bold"],
		},
		max_chars = 18,
	},
	background = {
		height = 2,
		color = colors.text.quaternary,
		y_offset = -15,
	},
})

local description_item = sbar.add("item", {
	position = "popup." .. weather.name,
	icon = {
		string = "Conditions:",
		width = popup_width / 2,
		align = "left",
		color = colors.text.secondary,
	},
	label = {
		string = "...",
		width = popup_width / 2,
		align = "right",
		max_chars = 20,
	},
})

local feels_like_item = sbar.add("item", {
	position = "popup." .. weather.name,
	icon = {
		string = "Feels like:",
		width = popup_width / 2,
		align = "left",
		color = colors.text.secondary,
	},
	label = {
		string = "...",
		width = popup_width / 2,
		align = "right",
	},
})

local humidity_item = sbar.add("item", {
	position = "popup." .. weather.name,
	icon = {
		string = "Humidity:",
		width = popup_width / 2,
		align = "left",
		color = colors.text.secondary,
	},
	label = {
		string = "...",
		width = popup_width / 2,
		align = "right",
	},
})

local wind_item = sbar.add("item", {
	position = "popup." .. weather.name,
	icon = {
		string = "Wind:",
		width = popup_width / 2,
		align = "left",
		color = colors.text.secondary,
	},
	label = {
		string = "...",
		width = popup_width / 2,
		align = "right",
	},
})

local change_location_item = sbar.add("item", {
	position = "popup." .. weather.name,
	icon = { drawing = false },
	label = {
		string = "Change Location...",
		width = popup_width,
		align = "center",
		color = colors.accent,
		font = { style = settings.font.style_map["Bold"] },
	},
	background = {
		height = 2,
		color = colors.text.quaternary,
		y_offset = 15,
	},
})

-------------------------------------------------------------------------------
-- Apply weather data to UI
-------------------------------------------------------------------------------

local function apply_weather(data, location)
	weather:set({
		icon = { string = data.icon },
		label = { string = (data.temp_c or "?") .. "\xC2\xB0C" },
	})
	location_label:set({ label = { string = location } })
	description_item:set({ label = { string = data.description or "Unknown" } })
	feels_like_item:set({ label = { string = (data.feels_like or "?") .. "\xC2\xB0C" } })
	humidity_item:set({ label = { string = (data.humidity or "?") .. "%" } })
	wind_item:set({ label = { string = (data.wind_kmph or "?") .. " km/h" } })
end

local function fmt(v)
	if v == nil then
		return nil
	end
	return string.format("%.0f", tonumber(v))
end

-------------------------------------------------------------------------------
-- Fetch: Open-Meteo fallback (geocode -> forecast)
-------------------------------------------------------------------------------

local function fetch_open_meteo(location)
	local url_location = location:gsub(" ", "+")
	local geo_url = "https://geocoding-api.open-meteo.com/v1/search?name="
		.. url_location
		.. "&count=1&language=en&format=json"

	sbar.exec('curl -s --max-time 5 "' .. geo_url .. '"', function(geo)
		if type(geo) ~= "table" or not geo.results or not geo.results[1] then
			weather:set({ label = { string = "N/A" } })
			return
		end

		local lat = geo.results[1].latitude
		local lon = geo.results[1].longitude
		if not lat or not lon then
			weather:set({ label = { string = "N/A" } })
			return
		end

		local forecast_url = "https://api.open-meteo.com/v1/forecast"
			.. "?latitude="
			.. lat
			.. "&longitude="
			.. lon
			.. "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"
			.. "&temperature_unit=celsius&wind_speed_unit=kmh&timezone=auto"

		sbar.exec('curl -s --max-time 5 "' .. forecast_url .. '"', function(wx)
			if type(wx) ~= "table" or not wx.current then
				weather:set({ label = { string = "N/A" } })
				return
			end

			local c = wx.current
			local code = tonumber(c.weather_code) or -1
			local entry = wmo_table[code]

			apply_weather({
				temp_c = fmt(c.temperature_2m),
				feels_like = fmt(c.apparent_temperature),
				humidity = fmt(c.relative_humidity_2m),
				wind_kmph = fmt(c.wind_speed_10m),
				icon = entry and entry.icon or icons.weather.default,
				description = entry and entry.desc or "Unknown",
			}, location)
		end)
	end)
end

-------------------------------------------------------------------------------
-- Fetch: wttr.in primary, Open-Meteo fallback
-------------------------------------------------------------------------------

local function update_weather()
	local location = get_location()
	local url_location = location:gsub(" ", "+")

	sbar.exec('curl -s --max-time 5 "wttr.in/' .. url_location .. '?format=j1"', function(result)
		if type(result) == "table" and result.current_condition then
			local cc = result.current_condition[1]
			if cc then
				local code = tonumber(cc.weatherCode) or 0
				local desc = "Unknown"
				if cc.weatherDesc and cc.weatherDesc[1] then
					desc = cc.weatherDesc[1].value
				end
				apply_weather({
					temp_c = cc.temp_C,
					feels_like = cc.FeelsLikeC,
					humidity = cc.humidity,
					wind_kmph = cc.windspeedKmph,
					icon = wwo_icons[code] or icons.weather.default,
					description = desc,
				}, location)
				return
			end
		end

		-- wttr.in failed, fall back to Open-Meteo
		fetch_open_meteo(location)
	end)
end

-------------------------------------------------------------------------------
-- Event subscriptions
-------------------------------------------------------------------------------

weather:subscribe({ "routine", "forced", "system_woke" }, function()
	update_weather()
end)

local function hide_details()
	weather:set({ popup = { drawing = false } })
end

local function toggle_details()
	local should_draw = weather:query().popup.drawing == "off"
	if should_draw then
		weather:set({ popup = { drawing = true } })
	else
		hide_details()
	end
end

weather:subscribe("mouse.clicked", toggle_details)
weather:subscribe("mouse.exited.global", hide_details)

sbar.add("bracket", "widgets.weather.bracket", { weather.name }, {
	background = { color = colors.transparent },
})

weather:subscribe("mouse.entered", function()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		sbar.set("widgets.weather.bracket", { background = { color = colors.hover_bg } })
	end)
end)

weather:subscribe("mouse.exited", function()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		sbar.set("widgets.weather.bracket", { background = { color = colors.transparent } })
	end)
end)

-- Change location via osascript dialog
change_location_item:subscribe("mouse.clicked", function()
	local current = get_location()
	sbar.exec(
		'osascript -e \'tell application "System Events" to display dialog "Enter location (city, postcode, or address):" default answer "'
			.. current
			.. "\" with title \"Weather Location\"' -e 'text returned of result' 2>/dev/null",
		function(result)
			if type(result) == "string" and result ~= "" then
				local new_location = result:gsub("%s+$", "")
				if new_location ~= "" then
					save_location(new_location)
					update_weather()
				end
			end
		end
	)
end)

sbar.add("item", "widgets.weather.padding", {
	position = "right",
	width = settings.group_paddings,
})
