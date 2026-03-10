return {
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = function(plugin)
			local app_dir = plugin.dir .. "/app"
			vim.fn.system("cd " .. vim.fn.shellescape(app_dir) .. " && bun install")
			vim.fn.system(
				"cd "
					.. vim.fn.shellescape(app_dir)
					.. " && bun add mermaid@latest && cp node_modules/mermaid/dist/mermaid.min.js _static/mermaid.min.js"
			)
		end,
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.g.mkdp_auto_start = 0
			vim.g.mkdp_auto_close = 0
		end,
		ft = { "markdown" },
	},
	{
		"OXY2DEV/markview.nvim",
		lazy = false,
		dependencies = {
			"saghen/blink.cmp",
		},
		opts = {
			preview = {
				icon_provider = "mini",
				modes = { "n", "no", "c", "i" },
				hybrid_modes = { "n", "i" },
			},
		},
	},
	{
		"folke/zen-mode.nvim",
		opts = {
			window = {
				backdrop = 1, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
				width = 120, -- width of the Zen window
				height = 1, -- height of the Zen window
			},
			plugins = {
				-- disable some global vim options (vim.o...)
				-- comment the lines to not apply the options
				options = {
					enabled = true,
					ruler = false, -- disables the ruler text in the cmd line area
					showcmd = false, -- disables the command in the last line of the screen
					-- you may turn on/off statusline in zen mode by setting 'laststatus'
					-- statusline will be shown only if 'laststatus' == 3
					laststatus = 0, -- turn off the statusline in zen mode
				},
				twilight = { enabled = false }, -- enable to start Twilight when zen mode opens
				gitsigns = { enabled = true }, -- disables git signs
				tmux = { enabled = true }, -- disables the tmux statusline
				todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
			},
		},
		keys = {
			{ "<leader>uz", "<cmd>ZenMode<cr>", desc = "Enable Zen Mode" },
		},
	},
}
