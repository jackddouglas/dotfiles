vim.keymap.set("n", "<leader>ot", function()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("No file to open", vim.log.levels.WARN)
		return
	end
	vim.system({ "open", "-a", "Typora", file })
end, { buffer = true, desc = "Open in Typora" })
