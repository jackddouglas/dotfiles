local autocmd = vim.api.nvim_create_autocmd

-- enable wrap for prose filetypes
autocmd("FileType", {
	pattern = { "markdown", "text", "gitcommit", "typst" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
	end,
})

-- highlight on yank
autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- restore cursor position when opening files
autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- clean up terminal buffers
autocmd("TermOpen", {
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.statuscolumn = ""
	end,
})

-- auto-resize splits when terminal is resized
autocmd("VimResized", {
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- q to close popup-style buffers
autocmd("FileType", {
	pattern = {
		"help",
		"qf",
		"lspinfo",
		"man",
		"notify",
		"checkhealth",
		"mason",
		"lazy",
		"query",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, desc = "Close" })
	end,
})

-- link rust operators to the Operator highlight group instead of Statement
vim.api.nvim_set_hl(0, "@operator.rust", { link = "Operator" })
