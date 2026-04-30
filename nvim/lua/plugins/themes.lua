return {
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = "rktjmp/lush.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			-- brighten terminal_color_8
			vim.api.nvim_create_autocmd({ "ColorScheme" }, {
				callback = function()
					if vim.g.colors_name == "zenwritten" then
						if vim.o.background == "dark" then
							vim.g.terminal_color_8 = "#707070"
						else
							vim.g.terminal_color_8 = "#888888"
						end
					end
				end,
			})

			-- vim.cmd.colorscheme("zenwritten")
		end,
	},
	{
		"kepano/flexoki-neovim",
		name = "flexoki",
		lazy = false,
		priority = 1000,
		config = function()
			local function apply_highlights()
				local p = require("flexoki.palette").palette()
				local groups = {
					IblIndent = { fg = p["ui-2"] },
					IblScope = { fg = p["tx-3"] },
					BufferLineFill = { bg = p["bg-2"] },
					BufferLineBackground = { fg = p["tx-3"], bg = p["bg-2"] },
					BufferLineBufferVisible = { fg = p["tx-2"], bg = p["bg-2"] },
					BufferLineBufferSelected = { fg = p.tx, bg = p.bg, bold = true },
					BufferLineSeparator = { fg = p["bg-2"], bg = p["bg-2"] },
					BufferLineSeparatorVisible = { fg = p["bg-2"], bg = p["bg-2"] },
					BufferLineSeparatorSelected = { fg = p["bg-2"], bg = p.bg },
					BufferLineIndicatorSelected = { fg = p["bl-2"], bg = p.bg },
					BufferLineIndicatorVisible = { fg = p["bg-2"], bg = p["bg-2"] },
					BufferLineCloseButton = { fg = p["tx-3"], bg = p["bg-2"] },
					BufferLineCloseButtonVisible = { fg = p["tx-2"], bg = p["bg-2"] },
					BufferLineCloseButtonSelected = { fg = p.tx, bg = p.bg },
					BufferLineModified = { fg = p["or"], bg = p["bg-2"] },
					BufferLineModifiedVisible = { fg = p["or"], bg = p["bg-2"] },
					BufferLineModifiedSelected = { fg = p["or"], bg = p.bg },
					BufferLineDuplicate = { fg = p["tx-3"], bg = p["bg-2"], italic = true },
					BufferLineDuplicateVisible = { fg = p["tx-2"], bg = p["bg-2"], italic = true },
					BufferLineDuplicateSelected = { fg = p["tx-2"], bg = p.bg, italic = true },
					BufferLineError = { fg = p.re, bg = p["bg-2"] },
					BufferLineErrorVisible = { fg = p.re, bg = p["bg-2"] },
					BufferLineErrorSelected = { fg = p.re, bg = p.bg, bold = true },
					BufferLineErrorDiagnostic = { fg = p.re, bg = p["bg-2"] },
					BufferLineErrorDiagnosticVisible = { fg = p.re, bg = p["bg-2"] },
					BufferLineErrorDiagnosticSelected = { fg = p.re, bg = p.bg, bold = true },
					BufferLineWarning = { fg = p.ye, bg = p["bg-2"] },
					BufferLineWarningVisible = { fg = p.ye, bg = p["bg-2"] },
					BufferLineWarningSelected = { fg = p.ye, bg = p.bg, bold = true },
					BufferLineWarningDiagnostic = { fg = p.ye, bg = p["bg-2"] },
					BufferLineWarningDiagnosticVisible = { fg = p.ye, bg = p["bg-2"] },
					BufferLineWarningDiagnosticSelected = { fg = p.ye, bg = p.bg, bold = true },
				}
				for name, opts in pairs(groups) do
					vim.api.nvim_set_hl(0, name, opts)
				end
				pcall(function()
					require("ibl").setup()
				end)
			end

			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "flexoki*",
				callback = function()
					vim.schedule(apply_highlights)
				end,
			})

			vim.api.nvim_create_autocmd("OptionSet", {
				pattern = "background",
				callback = function()
					vim.cmd.colorscheme("flexoki")
				end,
			})

			vim.cmd.colorscheme("flexoki")
		end,
	},
}
