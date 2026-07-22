return {
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
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
		"nvim-mini/mini.files",
		version = false,
		opts = {
			windows = {
				preview = true,
				width_focus = 40,
				width_nofocus = 20,
				width_preview = 60,
			},
		},
		config = function(_, opts)
			require("mini.files").setup(opts)

			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesWindowOpen",
				callback = function(args)
					vim.api.nvim_win_set_config(args.data.win_id, { border = "single" })
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesBufferCreate",
				callback = function(args)
					local function yank(mods)
						return function()
							local entry = MiniFiles.get_fs_entry()
							if entry == nil then
								return
							end
							vim.fn.setreg(vim.v.register, vim.fn.fnamemodify(entry.path, mods))
						end
					end
					local buf = args.data.buf_id
					vim.keymap.set("n", "gy", yank(":."), { buffer = buf, desc = "Yank relative path" })
					vim.keymap.set("n", "gY", yank(":p"), { buffer = buf, desc = "Yank absolute path" })
				end,
			})
		end,
		keys = {
			{
				"<leader>e",
				function()
					local path = vim.api.nvim_buf_get_name(0)
					if vim.bo.buftype ~= "" or vim.uv.fs_stat(path) == nil then
						path = nil
					end
					MiniFiles.open(path, true, { windows = { preview = vim.o.columns >= 120 } })
				end,
				desc = "Files",
			},
		},
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		lazy = false,
	},
}
