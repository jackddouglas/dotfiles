local TmuxNavigateIgnore = function(motion, buftype)
	vim.g.last_pane = vim.fn.win_getid()
	vim.cmd(motion)
	if vim.bo.buftype ~= buftype then
		vim.g.last_pane = vim.fn.win_getid()
	else
		while vim.bo.buftype == buftype do
			local jumped_to = vim.fn.win_getid()
			vim.cmd(motion)
			if vim.fn.win_getid() == jumped_to then
				vim.fn.win_gotoid(vim.g.last_pane)
				break
			end
		end
	end
end

return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = { "ryanoasis/vim-devicons" },
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(count, level)
					local icon = level:match("error") and " " or " "
					return " " .. icon .. count
				end,
				custom_filter = function(buf_number)
					if vim.bo[buf_number].buftype == "terminal" then
						return false
					end
					return true
				end,
			},
		},
	},
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
			"TmuxNavigatorProcessList",
		},
		init = function()
			vim.g.tmux_navigator_no_mappings = 1

			-- Set terminal mode keymaps
			vim.api.nvim_create_autocmd("TermEnter", {
				callback = function()
					local opts = { buffer = true }
					vim.keymap.set("t", "<C-h>", function()
						TmuxNavigateIgnore("TmuxNavigateLeft", "nofile")
					end, opts)
					vim.keymap.set("t", "<C-j>", function()
						TmuxNavigateIgnore("TmuxNavigateDown", "nofile")
					end, opts)
					vim.keymap.set("t", "<C-k>", function()
						TmuxNavigateIgnore("TmuxNavigateUp", "nofile")
					end, opts)
					vim.keymap.set("t", "<C-l>", function()
						TmuxNavigateIgnore("TmuxNavigateRight", "nofile")
					end, opts)
				end,
			})

			-- These autocommands will focus on the last buffer that was not ignored, when we go from a tmux pane to a vim split
			vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "TabEnter" }, {
				pattern = { "*" },
				callback = function()
					vim.fn.win_gotoid(vim.g.last_pane)
				end,
			})
		end,
		keys = {
			{
				"<c-h>",
				function()
					TmuxNavigateIgnore("TmuxNavigateLeft", "nofile")
				end,
			},
			{
				"<c-j>",
				function()
					TmuxNavigateIgnore("TmuxNavigateDown", "nofile")
				end,
			},
			{
				"<c-k>",
				function()
					TmuxNavigateIgnore("TmuxNavigateUp", "nofile")
				end,
			},
			{
				"<c-l>",
				function()
					TmuxNavigateIgnore("TmuxNavigateRight", "nofile")
				end,
			},
		},
	},
	{
		"nvim-mini/mini.statusline",
		version = false,
		config = function()
			local jj_cache = { value = "", time = 0 }
			local function jj_status()
				local now = vim.uv.now()
				if now - jj_cache.time < 3000 then
					return jj_cache.value
				end
				local bookmark = vim.fn.system(
					[[jj log --ignore-working-copy -r 'heads(::@ & bookmarks())' --no-graph -T 'separate("", bookmarks, if(self.contained_in("@"), "", "~"))' 2>/dev/null]]
				)
				if vim.v.shell_error ~= 0 then
					jj_cache.value = ""
					jj_cache.time = now
					return jj_cache.value
				end
				local change_id = vim.fn.system(
					[[jj log --ignore-working-copy -r @ --no-graph -T 'change_id.shortest()' 2>/dev/null]]
				)
				if vim.v.shell_error ~= 0 then
					jj_cache.value = ""
					jj_cache.time = now
					return jj_cache.value
				end
				bookmark = vim.trim(bookmark)
				change_id = vim.trim(change_id)
				if bookmark ~= "" then
					jj_cache.value = bookmark .. " " .. change_id
				else
					jj_cache.value = change_id
				end
				jj_cache.time = now
				return jj_cache.value
			end

			require("mini.statusline").setup({
				content = {
					active = function()
						local MiniStatusline = require("mini.statusline")
						local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
						local jj = jj_status()
						local diff = MiniStatusline.section_diff({ trunc_width = 75 })
						local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
						local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
						local filename = MiniStatusline.section_filename({ trunc_width = 140 })
						local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
						local location = MiniStatusline.section_location({ trunc_width = 75 })
						local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

						return MiniStatusline.combine_groups({
							{ hl = mode_hl, strings = { mode } },
							{ hl = "MiniStatuslineDevinfo", strings = { jj, diff, diagnostics, lsp } },
							"%<",
							{ hl = "MiniStatuslineFilename", strings = { filename } },
							"%=",
							{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
							{ hl = mode_hl, strings = { search, location } },
						})
					end,
				},
			})
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
	{
		"nvim-mini/mini.starter",
		version = false,
		opts = {},
	},
}
