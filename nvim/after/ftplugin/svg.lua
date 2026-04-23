vim.keymap.set("n", "<leader>ob", function()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("No file to open", vim.log.levels.WARN)
		return
	end
	vim.system({ "open", vim.uri_from_fname(file) })
end, { buffer = true, desc = "Open in browser" })
