return {
	{
		"ibhagwan/fzf-lua",
		config = function()
			local fzf = require("fzf-lua")
			fzf.setup({
				defaults = { file_icons = "mini" },
				fzf_colors = true,
				keymap = {
					builtin = {
						["<C-f>"] = "preview-page-down",
						["<C-b>"] = "preview-page-up",
					},
					fzf = {
						["ctrl-f"] = "preview-page-down",
						["ctrl-b"] = "preview-page-up",
					},
				},
				winopts = {
					border = "single",
					height = 0.85,
					width = 0.80,
					preview = {
						border = "single",
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
				actions = {
					files = {
						["enter"] = fzf.actions.file_edit,
					},
				},
			})
			fzf.register_ui_select()
		end,
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			lsp_file_methods = {
				autosave_changes = "unmodified",
			},
			float = {
				padding = 2,
				max_width = 0.8,
				max_height = 0.8,
				border = "single",
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
