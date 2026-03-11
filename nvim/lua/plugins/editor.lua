return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			spec = {
				{ "<leader>b", group = "buffer" },
				{ "<leader>c", group = "code" },
				{ "<leader>f", group = "file" },
				{ "<leader>g", group = "git" },
				{ "<leader>gh", group = "hunks" },
				{ "<leader>gt", group = "toggle" },
				{ "<leader>p", group = "persistence" },
				{ "<leader>q", group = "quit" },
				{ "<leader>s", group = "search" },
				{ "<leader>t", group = "toggle" },
				{ "<leader>u", group = "ui" },
				{ "<leader>w", group = "window" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer keymaps",
			},
		},
	},
	{
		"nvim-mini/mini.pairs",
		version = false,
		opts = {},
	},
	{
		"nvim-mini/mini.ai",
		version = false,
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					g = function()
						local from = { line = 1, col = 1 }
						local to = {
							line = vim.fn.line("$"),
							col = math.max(vim.fn.getline("$"):len(), 1),
						}
						return { from = from, to = to }
					end,
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
				},
			}
		end,
	},
	{
		"nvim-mini/mini.bufremove",
		version = false,
		opts = {},
	},
	{
		"nvim-mini/mini.surround",
		opts = {
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update_n_lines = "gsn",
			},
		},
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		config = function()
			require("gitsigns").setup({
				on_attach = function(bufnr)
					local gitsigns = require("gitsigns")

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]h", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gitsigns.nav_hunk("next")
						end
					end, { desc = "Next hunk" })

					map("n", "[h", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gitsigns.nav_hunk("prev")
						end
					end, { desc = "Prev hunk" })

					-- Actions
					map("n", "<leader>ghs", gitsigns.stage_hunk, { desc = "Stage hunk" })
					map("n", "<leader>ghr", gitsigns.reset_hunk, { desc = "Reset hunk" })

					map("v", "<leader>ghs", function()
						gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Stage hunk" })

					map("v", "<leader>ghr", function()
						gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Reset hunk" })

					map("n", "<leader>ghS", gitsigns.stage_buffer, { desc = "Stage buffer" })
					map("n", "<leader>ghR", gitsigns.reset_buffer, { desc = "Reset buffer" })
					map("n", "<leader>ghp", gitsigns.preview_hunk, { desc = "Preview hunk" })
					map("n", "<leader>ghi", gitsigns.preview_hunk_inline, { desc = "Preview hunk inline" })

					map("n", "<leader>ghb", function()
						gitsigns.blame_line({ full = true })
					end, { desc = "Blame line" })

					map("n", "<leader>ghd", gitsigns.diffthis, { desc = "Diff this" })

					map("n", "<leader>ghD", function()
						gitsigns.diffthis("~")
					end, { desc = "Diff this ~" })

					map("n", "<leader>ghQ", function()
						gitsigns.setqflist("all")
					end, { desc = "Quickfix all hunks" })
					map("n", "<leader>ghq", gitsigns.setqflist, { desc = "Quickfix hunks" })

					-- Toggles
					map("n", "<leader>gtb", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
					map("n", "<leader>gtw", gitsigns.toggle_word_diff, { desc = "Toggle word diff" })

					-- Text object
					map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "inner hunk" })
				end,
			})
		end,
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Prev todo comment",
			},
		},
	},
	{
		"nvim-mini/mini.sessions",
		version = false,
		lazy = false,
		opts = {},
		keys = {
			{
				"<leader>ps",
				function()
					MiniSessions.read()
				end,
				desc = "Load Session",
			},
			{
				"<leader>pS",
				function()
					MiniSessions.select("read")
				end,
				desc = "Select Session",
			},
			{
				"<leader>pl",
				function()
					local latest = MiniSessions.get_latest()
					if latest then
						MiniSessions.read(latest)
					end
				end,
				desc = "Load Last Session",
			},
			{
				"<leader>pw",
				function()
					if vim.v.this_session ~= "" then
						MiniSessions.write()
					else
						vim.ui.input({ prompt = "Session name: " }, function(name)
							if name and name ~= "" then
								MiniSessions.write(name)
							end
						end)
					end
				end,
				desc = "Write Session",
			},
			{
				"<leader>pd",
				function()
					MiniSessions.select("delete")
				end,
				desc = "Delete Session",
			},
		},
	},
}
