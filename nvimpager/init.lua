-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{
			"zenbones-theme/zenbones.nvim",
			-- Optionally install Lush. Allows for more configuration or extending the colorscheme
			-- If you don't want to install lush, make sure to set g:zenbones_compat = 1
			-- In Vim, compat mode is turned on as Lush only works in Neovim.
			dependencies = "rktjmp/lush.nvim",
			lazy = false,
			priority = 1000,
			-- you can set set configuration options here
			config = function()
				vim.cmd.colorscheme("zenwritten")
			end,
		},
	},
	-- automatically check for plugin updates
	checker = { enabled = true },
})
