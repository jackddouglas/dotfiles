local M = {}

local state = {
	buf = nil,
	win = nil,
}

local function is_valid_buf()
	return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function is_valid_win()
	return state.win and vim.api.nvim_win_is_valid(state.win)
end

function M.toggle()
	-- if terminal window is open, close it
	if is_valid_win() then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
		return
	end

	-- calculate height: bottom third of the screen
	local height = math.floor(vim.o.lines / 3)

	-- open a bottom split
	vim.cmd("botright " .. height .. "split")
	state.win = vim.api.nvim_get_current_win()

	-- reuse existing terminal buffer or create a new one
	if is_valid_buf() then
		vim.api.nvim_win_set_buf(state.win, state.buf)
	else
		vim.cmd.terminal()
		state.buf = vim.api.nvim_get_current_buf()
		vim.bo[state.buf].buflisted = false
	end

	-- window options: clean appearance, inherit theme colors
	local wo = vim.wo[state.win]
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.foldcolumn = "0"
	wo.winhighlight = "Normal:Normal"

	-- enter insert mode
	vim.cmd.startinsert()
end

return M
