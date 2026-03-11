local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Load rift native Mach IPC client
-- rift.so is installed to ~/.local/share/rift.lua/ by the Nix derivation
package.cpath = os.getenv("HOME") .. "/.local/share/rift.lua/?.so;" .. package.cpath
local rift = require("rift")

-- Define workspace names for specific indexes (0-based for rift)
local workspace_names = {
	["0"] = "home",
	["1"] = "web",
	["2"] = "code",
	["3"] = "chat",
	["4"] = "music",
}

-- Function to get workspace display name
local function get_workspace_name(index)
	return workspace_names[tostring(index)] or tostring(index + 1)
end

-- Connect to rift via Mach IPC
local client, err = rift.connect()
if not client then
	print("rift.lua: failed to connect: " .. (err or "unknown"))
	return
end

-- Register custom sketchybar events (triggered by rift-cli subscriptions in run_on_start)
sbar.add("event", "rift_workspace_changed")
sbar.add("event", "rift_windows_changed")
sbar.add("event", "rift_window_title_changed")

-- Display mapping infrastructure
-- Maps sketchybar arrangement-id (1-based) -> macOS space id
local display_space_map = {}

-- Refresh display mapping by querying rift and matching UUIDs
local function refreshDisplayMapping()
	display_space_map = {}

	-- Query rift for display info (includes space ids and UUIDs)
	local rift_resp = client:send_request('"get_displays"')
	if not rift_resp or not rift_resp.data then
		return
	end

	-- Build UUID -> space mapping from rift
	local uuid_to_space = {}
	for _, display in ipairs(rift_resp.data) do
		if display.uuid and display.space then
			uuid_to_space[display.uuid] = display.space
		end
	end

	-- Query sketchybar for display info (includes arrangement-id and UUIDs)
	-- Use synchronous approach by parsing the output directly
	local handle = io.popen("sketchybar --query displays 2>/dev/null")
	if handle then
		local output = handle:read("*a")
		handle:close()

		-- Parse each display from the JSON array
		-- Match pattern: "arrangement-id": N ... "UUID": "xxx"
		for arr_id, uuid in output:gmatch('"arrangement%-id"%s*:%s*(%d+)[^}]-"UUID"%s*:%s*"([^"]+)"') do
			arr_id = tonumber(arr_id)
			if arr_id and uuid and uuid_to_space[uuid] then
				display_space_map[arr_id] = uuid_to_space[uuid]
			end
		end

		-- Also try reverse pattern: "UUID": "xxx" ... "arrangement-id": N
		for uuid, arr_id in output:gmatch('"UUID"%s*:%s*"([^"]+)"[^}]-"arrangement%-id"%s*:%s*(%d+)') do
			arr_id = tonumber(arr_id)
			if arr_id and uuid and uuid_to_space[uuid] and not display_space_map[arr_id] then
				display_space_map[arr_id] = uuid_to_space[uuid]
			end
		end
	end
end

-- Workspace items: workspaces[display_id][workspace_index]
local workspaces = {}

-- Workspace indicator items per display
local workspaces_indicators = {}

-- Root items per display (for padding)
local root_items = {}

-- Query rift for all windows and their workspace assignments for a specific space
local function getWindowsPerWorkspace(space_id)
	local open_windows = {}
	local request = space_id and ('{"get_workspaces":{"space_id":' .. space_id .. "}}") or '{"get_workspaces":{"space_id":null}}'

	local resp, req_err = client:send_request(request)
	if not resp then
		-- Try to reconnect
		client:reconnect()
		resp, req_err = client:send_request(request)
		if not resp then
			return open_windows, nil
		end
	end

	local focused_workspace = nil

	if resp and resp.data then
		for _, ws in ipairs(resp.data) do
			local ws_id = tostring(ws.index or ws.id or 0)
			if ws.is_active then
				focused_workspace = ws_id
			end
			if ws.windows then
				open_windows[ws_id] = {}
				for _, win in ipairs(ws.windows) do
					if win.app_name or win["app-name"] then
						table.insert(open_windows[ws_id], win.app_name or win["app-name"])
					end
				end
			end
		end
	end

	return open_windows, focused_workspace
end

local function updateWindow(display_id, workspace_index, open_windows, focused_workspace)
	if not workspaces[display_id] or not workspaces[display_id][workspace_index] then
		return
	end

	local workspace = workspaces[display_id][workspace_index]
	local windows = open_windows[workspace_index] or {}
	local is_focused = (workspace_index == focused_workspace)

	local icon_line = ""
	local no_app = (#windows == 0)

	for _, app in ipairs(windows) do
		local lookup = app_icons[app]
		local icon = ((lookup == nil) and app_icons["Default"] or lookup)
		icon_line = icon_line .. " " .. icon
	end

	sbar.animate("tanh", 10, function()
		if no_app and not is_focused then
			-- Hide empty unfocused workspaces
			workspace:set({
				icon = { drawing = false },
				label = { drawing = false },
				background = { drawing = false },
				padding_right = 0,
				padding_left = 0,
			})
			return
		end

		if no_app then
			-- Show dash for empty but focused/visible workspaces
			icon_line = " —"
			workspace:set({
				icon = { drawing = true },
				label = {
					string = icon_line,
					drawing = true,
					font = "sketchybar-app-font:Regular:16.0",
					y_offset = -1,
				},
				background = { drawing = true },
				padding_right = 1,
				padding_left = 1,
			})
			return
		end

		workspace:set({
			icon = { drawing = true },
			label = { drawing = true, string = icon_line },
			background = { drawing = true },
			padding_right = 1,
			padding_left = 1,
		})
	end)
end

local function updateFocusHighlight(display_id, focused_ws_id)
	if not workspaces[display_id] then
		return
	end

	for workspace_index, workspace in pairs(workspaces[display_id]) do
		local is_focused = (workspace_index == focused_ws_id)
		sbar.animate("sin", settings.animation.transition_duration, function()
			workspace:set({
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = {
					color = is_focused and colors.with_alpha(colors.accent, 0.2) or colors.transparent,
				},
			})
		end)
	end
end

-- Update all displays
local function updateAllDisplays()
	for display_id, space_id in pairs(display_space_map) do
		local open_windows, focused_workspace = getWindowsPerWorkspace(space_id)
		if workspaces[display_id] then
			for workspace_index, _ in pairs(workspaces[display_id]) do
				updateWindow(display_id, workspace_index, open_windows, focused_workspace)
			end
			if focused_workspace then
				updateFocusHighlight(display_id, focused_workspace)
			end
		end
	end
end

-- Create workspace items for a specific display
local function createWorkspacesForDisplay(display_id)
	if workspaces[display_id] then
		return -- Already created
	end

	workspaces[display_id] = {}

	-- Add left padding for this display
	root_items[display_id] = sbar.add("item", "workspace_root." .. display_id, {
		display = display_id,
		icon = { drawing = false },
		label = { drawing = false },
		background = { drawing = false },
		padding_left = 6,
		padding_right = 0,
	})

	local workspace_count = 10
	for i = 0, workspace_count - 1 do
		local workspace_index = tostring(i)

		local workspace = sbar.add("item", "workspace." .. display_id .. "." .. workspace_index, {
			display = display_id,
			icon = {
				color = colors.text.tertiary,
				highlight_color = colors.text.primary,
				drawing = false,
				font = { family = settings.font.numbers },
				string = get_workspace_name(i),
				padding_left = 10,
				padding_right = 5,
			},
			label = {
				padding_right = 10,
				color = colors.text.tertiary,
				highlight_color = colors.text.secondary,
				font = "sketchybar-app-font:Regular:16.0",
				y_offset = -1,
			},
			padding_right = 2,
			padding_left = 2,
			background = {
				color = colors.transparent,
				height = 28,
				corner_radius = 9,
			},
			-- Use rift-cli to switch workspace on click
			click_script = "rift-cli execute workspace switch " .. i,
		})

		workspaces[display_id][workspace_index] = workspace

		-- Mouse hover animations
		workspace:subscribe("mouse.entered", function()
			local is_focused = workspace:query().icon.highlight == "on"
			if not is_focused then
				sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
					workspace:set({ background = { color = colors.hover_bg } })
				end)
			end
		end)

		workspace:subscribe("mouse.exited", function()
			local is_focused = workspace:query().icon.highlight == "on"
			if not is_focused then
				sbar.animate(settings.animation.curve, settings.animation.hover_duration, function()
					workspace:set({ background = { color = colors.transparent } })
				end)
			end
		end)
	end

	-- Toggle indicator for this display
	workspaces_indicators[display_id] = sbar.add("item", "workspace_indicator." .. display_id, {
		display = display_id,
		padding_left = settings.group_paddings,
		padding_right = 0,
		icon = {
			padding_left = 8,
			padding_right = 9,
			color = colors.grey,
			string = icons.switch.on,
		},
		label = {
			width = 0,
			padding_left = 0,
			padding_right = 8,
			string = "Menu",
			color = colors.bg1,
		},
		background = {
			color = colors.with_alpha(colors.grey, 0.0),
			border_color = colors.with_alpha(colors.bg1, 0.0),
		},
	})

	local indicator = workspaces_indicators[display_id]

	indicator:subscribe("swap_menus_and_spaces", function(env)
		local currently_on = indicator:query().icon.value == icons.switch.on
		indicator:set({
			icon = { string = currently_on and icons.switch.off or icons.switch.on },
			label = { string = currently_on and "Spaces" or "Menu" },
		})
	end)

	indicator:subscribe("mouse.entered", function(env)
		sbar.animate("tanh", 30, function()
			indicator:set({
				background = {
					color = { alpha = 1.0 },
					border_color = { alpha = 1.0 },
				},
				icon = { color = colors.bg1 },
				label = { width = "dynamic" },
			})
		end)
	end)

	indicator:subscribe("mouse.exited", function(env)
		sbar.animate("tanh", 30, function()
			indicator:set({
				background = {
					color = { alpha = 0.0 },
					border_color = { alpha = 0.0 },
				},
				icon = { color = colors.grey },
				label = { width = 0 },
			})
		end)
	end)

	indicator:subscribe("mouse.clicked", function(env)
		sbar.trigger("swap_menus_and_spaces")
	end)
end

-- Initialize displays and create workspace items
local function initializeDisplays()
	refreshDisplayMapping()

	-- Create workspaces for each display
	for display_id, _ in pairs(display_space_map) do
		createWorkspacesForDisplay(display_id)
	end

	-- Initial update
	updateAllDisplays()
end

-- Add a root item for event subscriptions
local root = sbar.add("item", {
	icon = { drawing = false },
	label = { drawing = false },
	background = { drawing = false },
	padding_left = 0,
	padding_right = 0,
})

-- Subscribe to rift events via native Mach IPC for real-time updates
client:subscribe({ "workspace_changed", "windows_changed", "window_title_changed" }, function(env)
	updateAllDisplays()
end)

-- Event listeners for CLI-triggered sketchybar custom events
root:subscribe("rift_workspace_changed", function(env)
	updateAllDisplays()
end)

root:subscribe("rift_windows_changed", function()
	updateAllDisplays()
end)

root:subscribe("rift_window_title_changed", function()
	updateAllDisplays()
end)

root:subscribe("display_change", function()
	-- Refresh display mapping and reinitialize if needed
	refreshDisplayMapping()
	for display_id, _ in pairs(display_space_map) do
		if not workspaces[display_id] then
			createWorkspacesForDisplay(display_id)
		end
	end
	updateAllDisplays()
end)

-- Initialize on load
initializeDisplays()
