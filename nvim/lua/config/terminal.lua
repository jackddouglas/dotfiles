local M = {}

local state = {
	buf = nil,
	win = nil,
}

local jjui_state = {
	buf = nil,
	win = nil,
}

local function is_valid(s)
	return {
		buf = function()
			return s.buf and vim.api.nvim_buf_is_valid(s.buf)
		end,
		win = function()
			return s.win and vim.api.nvim_win_is_valid(s.win)
		end,
	}
end

function M.toggle()
	local valid = is_valid(state)

	-- if terminal window is open, close it
	if valid.win() then
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
	if valid.buf() then
		vim.api.nvim_win_set_buf(state.win, state.buf)
	else
		vim.cmd.terminal()
		state.buf = vim.api.nvim_get_current_buf()
		vim.bo[state.buf].buflisted = false
	end

	local wo = vim.wo[state.win]
	wo.foldcolumn = "0"
	wo.winhighlight = "Normal:Normal"
	wo.scrolloff = 0

	-- enter insert mode
	vim.cmd.startinsert()
end

local function open_float(buf)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	return vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "single",
	})
end

function M.toggle_jjui()
	local valid = is_valid(jjui_state)

	-- if jjui window is open, close it
	if valid.win() then
		vim.api.nvim_win_close(jjui_state.win, true)
		jjui_state.win = nil
		return
	end

	-- reuse existing buffer or create a new one
	if valid.buf() then
		jjui_state.win = open_float(jjui_state.buf)
	else
		-- create a scratch buffer, open the float, then start the terminal
		local buf = vim.api.nvim_create_buf(false, true)
		jjui_state.win = open_float(buf)
		vim.fn.jobstart("jjui", {
			term = true,
			on_exit = function()
				-- auto-close window and clear state when jjui exits
				if jjui_state.win and vim.api.nvim_win_is_valid(jjui_state.win) then
					vim.api.nvim_win_close(jjui_state.win, true)
				end
				jjui_state.buf = nil
				jjui_state.win = nil
			end,
		})
		jjui_state.buf = vim.api.nvim_get_current_buf()
	end

	local wo = vim.wo[jjui_state.win]
	wo.foldcolumn = "0"
	wo.winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

	vim.cmd.startinsert()
end

return M
