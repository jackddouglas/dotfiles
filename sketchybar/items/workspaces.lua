local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Define workspace names for specific indexes
local workspace_names = {
	["1"] = "home",
	["2"] = "web",
	["3"] = "code",
	["4"] = "chat",
	["5"] = "music",
}

-- Function to get workspace display name
local function get_workspace_name(index)
	return workspace_names[tostring(index)] or tostring(index)
end

local query_workspaces =
	"/etc/profiles/per-user/jackdouglas/bin/aerospace list-workspaces --all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"

-- Add padding to the left
local root = sbar.add("item", {
	icon = {
		color = colors.with_alpha(colors.white, 0.3),
		highlight_color = colors.white,
		drawing = false,
	},
	label = {
		color = colors.grey,
		highlight_color = colors.white,
		drawing = false,
	},
	background = {
		color = colors.transparent,
		border_width = 1,
		height = 28,
		border_color = colors.black,
		corner_radius = 9,
		drawing = false,
	},
	padding_left = 6,
	padding_right = 0,
})

local workspaces = {}

local function withWindows(f)
	local open_windows = {}
	local get_windows =
		"/etc/profiles/per-user/jackdouglas/bin/aerospace list-windows --monitor all --format '%{workspace}%{app-name}' --json"
	local query_visible_workspaces =
		"/etc/profiles/per-user/jackdouglas/bin/aerospace list-workspaces --visible --monitor all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"
	local get_focus_workspaces = "/etc/profiles/per-user/jackdouglas/bin/aerospace list-workspaces --focused"
	sbar.exec(get_windows, function(workspace_and_windows)
		for _, entry in ipairs(workspace_and_windows) do
			local workspace_index = entry.workspace
			local app = entry["app-name"]
			if open_windows[workspace_index] == nil then
				open_windows[workspace_index] = {}
			end
			table.insert(open_windows[workspace_index], app)
		end
		sbar.exec(get_focus_workspaces, function(focused_workspaces)
			sbar.exec(query_visible_workspaces, function(visible_workspaces)
				local args = {
					open_windows = open_windows,
					focused_workspaces = focused_workspaces,
					visible_workspaces = visible_workspaces,
				}
				f(args)
			end)
		end)
	end)
end

local function updateWindow(workspace_index, args)
	local open_windows = args.open_windows[workspace_index]
	local focused_workspaces = args.focused_workspaces
	local visible_workspaces = args.visible_workspaces

	if open_windows == nil then
		open_windows = {}
	end

	local icon_line = ""
	local no_app = true
	for i, open_window in ipairs(open_windows) do
		no_app = false
		local app = open_window
		local lookup = app_icons[app]
		local icon = ((lookup == nil) and app_icons["Default"] or lookup)
		icon_line = icon_line .. " " .. icon
	end

	sbar.animate("tanh", 10, function()
		for i, visible_workspace in ipairs(visible_workspaces) do
			if no_app and workspace_index == visible_workspace["workspace"] then
				local monitor_id = visible_workspace["monitor-appkit-nsscreen-screens-id"]
				icon_line = " —"
				workspaces[workspace_index]:set({
					icon = { drawing = true },
					label = {
						string = icon_line,
						drawing = true,
						-- padding_right = 20,
						font = "sketchybar-app-font:Regular:16.0",
						y_offset = -1,
					},
					background = { drawing = true },
					padding_right = 1,
					padding_left = 1,
					display = monitor_id,
				})
				return
			end
		end
		if no_app and workspace_index ~= focused_workspaces then
			workspaces[workspace_index]:set({
				icon = { drawing = false },
				label = { drawing = false },
				background = { drawing = false },
				padding_right = 0,
				padding_left = 0,
			})
			return
		end
		if no_app and workspace_index == focused_workspaces then
			icon_line = " —"
			workspaces[workspace_index]:set({
				icon = { drawing = true },
				label = {
					string = icon_line,
					drawing = true,
					-- padding_right = 20,
					font = "sketchybar-app-font:Regular:16.0",
					y_offset = -1,
				},
				background = { drawing = true },
				padding_right = 1,
				padding_left = 1,
			})
		end

		workspaces[workspace_index]:set({
			icon = { drawing = true },
			label = { drawing = true, string = icon_line },
			background = { drawing = true },
			padding_right = 1,
			padding_left = 1,
		})
	end)
end

local function updateWindows()
	withWindows(function(args)
		for workspace_index, _ in pairs(workspaces) do
			updateWindow(workspace_index, args)
		end
	end)
end

local function updateWorkspaceMonitor()
	local workspace_monitor = {}
	sbar.exec(query_workspaces, function(workspaces_and_monitors)
		for _, entry in ipairs(workspaces_and_monitors) do
			local space_index = entry.workspace
			local monitor_id = math.floor(entry["monitor-appkit-nsscreen-screens-id"])
			workspace_monitor[space_index] = monitor_id
		end
		for workspace_index, _ in pairs(workspaces) do
			workspaces[workspace_index]:set({
				display = workspace_monitor[workspace_index],
			})
		end
	end)
end

sbar.exec(query_workspaces, function(workspaces_and_monitors)
	for _, entry in ipairs(workspaces_and_monitors) do
		local workspace_index = entry.workspace

		local workspace = sbar.add("item", "workspace." .. workspace_index, {
			icon = {
				color = colors.with_alpha(colors.white, 0.3),
				-- highlight_color = colors.red,
				highlight_color = colors.white,
				drawing = false,
				font = { family = settings.font.numbers },
				string = get_workspace_name(workspace_index),
				padding_left = 10,
				padding_right = 5,
			},
			label = {
				padding_right = 10,
				-- color = colors.grey,
				color = colors.with_alpha(colors.white, 0.3),
				highlight_color = colors.white,
				font = "sketchybar-app-font:Regular:16.0",
				y_offset = -1,
			},
			padding_right = 2,
			padding_left = 2,
			background = {
				color = colors.transparent,
				border_width = 1,
				height = 28,
				border_color = colors.grey,
			},
			click_script = "/etc/profiles/per-user/jackdouglas/bin/aerospace workspace " .. tostring(workspace_index),
		})

		workspaces[workspace_index] = workspace

		workspace:subscribe("aerospace_workspace_change", function(env)
			local focused_workspace = env.FOCUSED_WORKSPACE
			local is_focused = focused_workspace == workspace_index

			sbar.animate("tanh", 10, function()
				workspace:set({
					icon = { highlight = is_focused },
					label = { highlight = is_focused },
					background = {
						border_width = is_focused and 2 or 1,
					},
					blur_radius = 30,
				})
			end)
		end)
	end

	-- Toggle indicator (created after workspace items so it appears at the end)
	local workspaces_indicator = sbar.add("item", {
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

	workspaces_indicator:subscribe("swap_menus_and_spaces", function(env)
		local currently_on = workspaces_indicator:query().icon.value == icons.switch.on
		workspaces_indicator:set({
			icon = { string = currently_on and icons.switch.off or icons.switch.on },
			label = { string = currently_on and "Spaces" or "Menu" },
		})
	end)

	workspaces_indicator:subscribe("mouse.entered", function(env)
		sbar.animate("tanh", 30, function()
			workspaces_indicator:set({
				background = {
					color = { alpha = 1.0 },
					border_color = { alpha = 1.0 },
				},
				icon = { color = colors.bg1 },
				label = { width = "dynamic" },
			})
		end)
	end)

	workspaces_indicator:subscribe("mouse.exited", function(env)
		sbar.animate("tanh", 30, function()
			workspaces_indicator:set({
				background = {
					color = { alpha = 0.0 },
					border_color = { alpha = 0.0 },
				},
				icon = { color = colors.grey },
				label = { width = 0 },
			})
		end)
	end)

	workspaces_indicator:subscribe("mouse.clicked", function(env)
		sbar.trigger("swap_menus_and_spaces")
	end)

	-- initial setup
	updateWindows()
	updateWorkspaceMonitor()

	root:subscribe("aerospace_focus_change", function()
		updateWindows()
	end)

	root:subscribe("display_change", function()
		updateWorkspaceMonitor()
		updateWindows()
	end)

	sbar.exec("/etc/profiles/per-user/jackdouglas/bin/aerospace list-workspaces --focused", function(focused_workspace)
		local focused_workspace = focused_workspace:match("^%s*(.-)%s*$")
		workspaces[focused_workspace]:set({
			icon = { highlight = true },
			label = { highlight = true },
			background = { border_width = 2 },
		})
	end)
end)
