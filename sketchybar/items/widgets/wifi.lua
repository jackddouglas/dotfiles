local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
sbar.exec(
	"killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0"
)

local popup_width = 250

local wifi_up = sbar.add("item", "widgets.wifi1", {
	position = "right",
	padding_left = -5,
	width = 0,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.upload,
		color = colors.text.tertiary,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.text.tertiary,
		string = "??? Bps",
	},
	y_offset = 4,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
	position = "right",
	padding_left = -5,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.download,
		color = colors.text.tertiary,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.text.tertiary,
		string = "??? Bps",
	},
	y_offset = -4,
})

local wifi = sbar.add("item", "widgets.wifi.padding", {
	position = "right",
	label = { drawing = false },
})

-- Pill background bracket
local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
	wifi.name,
	wifi_up.name,
	wifi_down.name,
}, {
	background = { color = colors.transparent },
	popup = { align = "center", height = 30 },
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
		},
		string = icons.wifi.router,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			size = 15,
			style = settings.font.style_map["Bold"],
		},
		max_chars = 18,
		string = "????????????",
	},
	background = {
		height = 2,
		color = colors.text.quaternary,
		y_offset = -15,
	},
})

local hostname = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Hostname:",
		width = popup_width / 2,
		color = colors.text.secondary,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
	},
})

local ip = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "IP:",
		width = popup_width / 2,
		color = colors.text.secondary,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local mask = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Subnet mask:",
		width = popup_width / 2,
		color = colors.text.secondary,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local router = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Router:",
		width = popup_width / 2,
		color = colors.text.secondary,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

sbar.add("item", { position = "right", width = settings.group_paddings })

wifi_up:subscribe("network_update", function(env)
	local up_color = (env.upload == "000 Bps") and colors.text.tertiary or colors.text.secondary
	local down_color = (env.download == "000 Bps") and colors.text.tertiary or colors.text.primary
	wifi_up:set({
		icon = { color = up_color },
		label = {
			string = env.upload,
			color = up_color,
		},
	})
	wifi_down:set({
		icon = { color = down_color },
		label = {
			string = env.download,
			color = down_color,
		},
	})
end)

wifi:subscribe({ "wifi_change", "system_woke" }, function(env)
	-- Try the standard IP check first, then fall back to networksetup for
	-- hotspot connections where DHCP is inactive but Wi-Fi is associated
	sbar.exec("ipconfig getifaddr en0", function(ip_result)
		local ip_addr = ip_result:gsub("%s+$", "")

		if ip_addr ~= "" then
			-- Normal Wi-Fi with a DHCP-assigned IP
			wifi:set({
				icon = {
					string = icons.wifi.connected,
					color = colors.white,
				},
			})
			return
		end

		-- No IP from ipconfig — check if Wi-Fi is associated but using
		-- CLAT46/NAT64 (personal hotspot). DHCP state will be INACTIVE
		-- while a BSSID is present when connected to a hotspot.
		sbar.exec(
			"ipconfig getsummary en0 2>/dev/null | awk '/^ *DHCP : <dictionary>/ {in_dhcp=1} in_dhcp && /State :/ {gsub(/^ *State : /,\"\"); print; exit}'",
			function(dhcp_result)
				local dhcp_state = dhcp_result:gsub("%s+$", "")

				-- Also check if we have an IP via networksetup (works for hotspots)
				sbar.exec(
					"networksetup -getinfo Wi-Fi | awk -F ': ' '/^IP address:/ {print $2}'",
					function(fallback_ip_result)
						local fallback_ip = fallback_ip_result:gsub("%s+$", "")
						local has_fallback_ip = fallback_ip ~= "" and fallback_ip ~= "none"

						if dhcp_state == "INACTIVE" and has_fallback_ip then
							-- Wi-Fi associated, DHCP inactive, but has IP = personal hotspot
							wifi:set({
								icon = {
									string = icons.wifi.hotspot,
									color = colors.white,
								},
							})
						elseif has_fallback_ip then
							-- Has IP through networksetup but DHCP not inactive
							wifi:set({
								icon = {
									string = icons.wifi.connected,
									color = colors.white,
								},
							})
						else
							-- Truly not connected
							wifi:set({
								icon = {
									string = icons.wifi.disconnected,
									color = colors.red,
								},
							})
						end
					end
				)
			end
		)
	end)
end)

local function hide_details()
	wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
	local should_draw = wifi_bracket:query().popup.drawing == "off"
	if should_draw then
		wifi_bracket:set({ popup = { drawing = true } })
		sbar.exec("networksetup -getcomputername", function(result)
			hostname:set({ label = result })
		end)
		-- IP display: try ipconfig first, fall back to networksetup for hotspots
		sbar.exec("ipconfig getifaddr en0", function(result)
			local ip_addr = result:gsub("%s+$", "")
			if ip_addr ~= "" then
				ip:set({ label = ip_addr })
			else
				sbar.exec("networksetup -getinfo Wi-Fi | awk -F ': ' '/^IP address:/ {print $2}'", function(fallback)
					local fallback_ip = fallback:gsub("%s+$", "")
					ip:set({ label = fallback_ip ~= "" and fallback_ip ~= "none" and fallback_ip or "N/A" })
				end)
			end
		end)
		sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
			local ssid_name = result:gsub("%s+$", "")
			-- macOS may return <redacted> for the SSID due to privacy restrictions
			local ssid_available = ssid_name ~= "" and ssid_name ~= "<redacted>"

			-- Check DHCP state to determine if this is a personal hotspot
			-- (DHCP INACTIVE + associated Wi-Fi = hotspot via CLAT46/NAT64)
			sbar.exec(
				"ipconfig getsummary en0 2>/dev/null | awk '/^ *DHCP : <dictionary>/ {in_dhcp=1} in_dhcp && /State :/ {gsub(/^ *State : /,\"\"); print; exit}'",
				function(dhcp_result)
					local dhcp_state = dhcp_result:gsub("%s+$", "")

					sbar.exec(
						"networksetup -getinfo Wi-Fi | awk -F ': ' '/^IP address:/ {print $2}'",
						function(ip_result)
							local fallback_ip = ip_result:gsub("%s+$", "")
							local is_hotspot = dhcp_state == "INACTIVE" and fallback_ip ~= "" and fallback_ip ~= "none"

							if is_hotspot then
								ssid:set({ label = "Personal Hotspot", icon = { string = icons.wifi.hotspot } })
							elseif ssid_available then
								ssid:set({ label = ssid_name, icon = { string = icons.wifi.router } })
							elseif fallback_ip ~= "" and fallback_ip ~= "none" then
								-- Connected but SSID redacted by macOS
								ssid:set({ label = "Wi-Fi", icon = { string = icons.wifi.router } })
							else
								ssid:set({ label = "Not Connected" })
							end
						end
					)
				end
			)
		end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
			local val = result:gsub("%s+$", "")
			mask:set({ label = val ~= "" and val ~= "(null)" and val or "N/A" })
		end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
			router:set({ label = result ~= "" and result or "N/A" })
		end)
	else
		hide_details()
	end
end

-- Hover animations
local function wifi_hover_on()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		wifi_bracket:set({ background = { color = colors.hover_bg } })
	end)
end

local function wifi_hover_off()
	sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
		wifi_bracket:set({ background = { color = colors.transparent } })
	end)
end

wifi_up:subscribe("mouse.clicked", toggle_details)
wifi_up:subscribe("mouse.entered", wifi_hover_on)
wifi_up:subscribe("mouse.exited", wifi_hover_off)
wifi_up:subscribe("mouse.exited.global", hide_details)
wifi_down:subscribe("mouse.clicked", toggle_details)
wifi_down:subscribe("mouse.entered", wifi_hover_on)
wifi_down:subscribe("mouse.exited", wifi_hover_off)
wifi_down:subscribe("mouse.exited.global", hide_details)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.entered", wifi_hover_on)
wifi:subscribe("mouse.exited", wifi_hover_off)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
	local label = sbar.query(env.NAME).label.value
	sbar.exec('echo "' .. label .. '" | pbcopy')
	sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
	sbar.delay(1, function()
		sbar.set(env.NAME, { label = { string = label, align = "right" } })
	end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
