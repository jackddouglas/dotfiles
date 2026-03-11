return {
	{
		"ibhagwan/fzf-lua",
		---@module "fzf-lua"
		---@type fzf-lua.Config|{}
		---@diagnostic disable: missing-fields
		opts = {
			defaults = { file_icons = "mini" },
			fzf_colors = true,
			winopts = {
				height = 0.85,
				width = 0.80,
				preview = {
					layout = "flex",
					flip_columns = 120,
				},
			},
			files = {
				git_icons = true,
				fd_opts = "--type f --hidden --follow --exclude .git",
			},
			grep = {
				rg_glob = true,
			},
		},
		config = function(_, opts)
			local fzf = require("fzf-lua")
			fzf.setup(opts)
			fzf.register_ui_select()
		end,
		---@diagnostic enable: missing-fields
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			float = {
				padding = 2,
				max_width = 0.8,
				max_height = 0.8,
				border = "rounded",
			},
			keymaps = {
				["gy"] = { "actions.yank_entry", opts = { modify = ":." }, desc = "Yank relative path" },
				["gY"] = { "actions.yank_entry", desc = "Yank absolute path" },
			},
		},
		keys = {
			{
				"<leader>o",
				function()
					local oil = require("oil")
					local config = require("oil.config")
					config.float.preview_split = vim.o.columns < 120 and "below" or "right"
					oil.open_float(nil, { preview = {} })
				end,
				desc = "Oil",
			},
		},
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		lazy = false,
	},
}
