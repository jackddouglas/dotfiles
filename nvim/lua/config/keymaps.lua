local map = vim.keymap.set

-- general
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear search highlight" })
map({ "n", "v" }, "j", "gj", { desc = "Move down (display line)" })
map({ "n", "v" }, "k", "gk", { desc = "Move up (display line)" })

-- stay in visual when indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- center cursor after jumps
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Prev search result" })

-- confirm-close helper: prompts save/discard/cancel for modified buffers
local function confirm_close(action)
	return function()
		if vim.bo.modified then
			local choice =
				vim.fn.confirm("Save changes to " .. (vim.fn.expand("%:t") or "[No Name]") .. "?", "&Yes\n&No\n&Cancel")
			if choice == 1 then -- Yes
				vim.cmd("write")
				vim.cmd(action)
			elseif choice == 2 then -- No
				vim.cmd(action .. "!")
			end
		-- choice == 0 or 3 = Cancel, do nothing
		else
			vim.cmd(action)
		end
	end
end

-------------------------------------------------------------------------------
-- buffers
-------------------------------------------------------------------------------
map("n", "H", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
map("n", "L", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", function()
	if vim.bo.modified then
		local choice =
			vim.fn.confirm("Save changes to " .. (vim.fn.expand("%:t") or "[No Name]") .. "?", "&Yes\n&No\n&Cancel")
		if choice == 1 then
			vim.cmd("write")
			require("mini.bufremove").delete(0, false)
		elseif choice == 2 then
			require("mini.bufremove").delete(0, true)
		end
	else
		require("mini.bufremove").delete(0, false)
	end
end, { desc = "Close buffer" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })
map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", { desc = "Close buffers to left" })
map("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", { desc = "Close buffers to right" })
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Toggle pin" })
map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", { desc = "Close unpinned buffers" })
map("n", "<leader>bs", "<cmd>BufferLinePick<cr>", { desc = "Pick buffer" })
map("n", "<leader>bx", "<cmd>BufferLinePickClose<cr>", { desc = "Pick buffer to close" })

-------------------------------------------------------------------------------
-- windows
-------------------------------------------------------------------------------
map("n", "<leader>wd", confirm_close("close"), { desc = "Close window" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "Close other windows" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<leader>\\", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>w=", "<cmd>wincmd =<cr>", { desc = "Equalize windows" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-------------------------------------------------------------------------------
-- quit
-------------------------------------------------------------------------------
map("n", "<leader>qq", "<cmd>confirm qall<cr>", { desc = "Quit all" })
map("n", "<leader>qw", confirm_close("quit"), { desc = "Quit window" })

-------------------------------------------------------------------------------
-- find / search (FzfLua)
-------------------------------------------------------------------------------
map("n", "<leader><leader>", "<cmd>FzfLua files<cr>", { desc = "Find files" })
map("n", "<leader>/", "<cmd>FzfLua live_grep<cr>", { desc = "Grep" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent files" })
map("n", "<leader>'", "<cmd>FzfLua resume<cr>", { desc = "Resume last search" })
map("n", "<leader>sh", "<cmd>FzfLua help_tags<cr>", { desc = "Search help" })
map("n", "<leader>:", "<cmd>FzfLua command_history<cr>", { desc = "Command history" })
map("n", "<leader>sm", "<cmd>FzfLua marks<cr>", { desc = "Search marks" })
map("n", "<leader>sR", "<cmd>FzfLua registers<cr>", { desc = "Search registers" })
map("n", "<leader>ss", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Search symbols (buffer)" })
map("n", "<leader>sS", "<cmd>FzfLua lsp_workspace_symbols<cr>", { desc = "Search symbols (workspace)" })
map("n", "<leader>sk", "<cmd>FzfLua keymaps<cr>", { desc = "Search keymaps" })
map("n", "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Search diagnostics (buffer)" })
map("n", "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Search diagnostics (workspace)" })
map("n", "<leader>sn", function()
	local history = require("fidget.notification").get_history()
	if #history == 0 then
		vim.notify("No notifications in history", vim.log.levels.INFO)
		return
	end
	local items = {}
	for i = #history, 1, -1 do
		local item = history[i]
		local group = item.group_name or ""
		local msg = (item.message or ""):gsub("\n", " ")
		local annote = item.annote and (" [" .. item.annote .. "]") or ""
		table.insert(items, string.format("%s: %s%s", group, msg, annote))
	end
	require("fzf-lua").fzf_exec(items, {
		prompt = "Notifications> ",
	})
end, { desc = "Search notifications" })
map("n", "<leader>st", "<cmd>TodoFzfLua<cr>", { desc = "Search all todos" })
map("n", "<leader>sT", function()
	require("todo-comments.fzf").todo({ keywords = { "TODO", "FIX", "FIXME" } })
end, { desc = "Search TODO/FIX/FIXME" })
map("n", "<leader>sH", function()
	require("todo-comments.fzf").todo({ keywords = { "HACK", "WARN", "WARNING" } })
end, { desc = "Search HACK/WARN" })
map("n", "<leader>sN", function()
	require("todo-comments.fzf").todo({ keywords = { "NOTE", "INFO" } })
end, { desc = "Search NOTE/INFO" })

-------------------------------------------------------------------------------
-- git (FzfLua)
-------------------------------------------------------------------------------
map("n", "<leader>gs", "<cmd>FzfLua git_status<cr>", { desc = "Git status" })
map("n", "<leader>gd", "<cmd>FzfLua git_diff<cr>", { desc = "Git diff (changed files)" })
map("n", "<leader>gH", "<cmd>FzfLua git_hunks<cr>", { desc = "Git hunks (search diffs)" })
map("n", "<leader>gc", "<cmd>FzfLua git_commits<cr>", { desc = "Git commits (project)" })
map("n", "<leader>gC", "<cmd>FzfLua git_bcommits<cr>", { desc = "Git commits (buffer)" })
map("n", "<leader>gb", "<cmd>FzfLua git_blame<cr>", { desc = "Git blame (buffer)" })
map("n", "<leader>gB", "<cmd>FzfLua git_branches<cr>", { desc = "Git branches" })
map("n", "<leader>gS", "<cmd>FzfLua git_stash<cr>", { desc = "Git stash" })

-------------------------------------------------------------------------------
-- comments
-------------------------------------------------------------------------------
map("n", "gco", function()
	local cs = vim.bo.commentstring
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local indent = vim.fn.indent(line)
	local comment = cs:format("")
	local padding = string.rep(vim.bo.expandtab and " " or "\t", vim.bo.expandtab and indent or indent / vim.bo.tabstop)
	vim.api.nvim_buf_set_lines(0, line, line, false, { padding .. comment })
	vim.api.nvim_win_set_cursor(0, { line + 1, #padding + #comment:match("^(.-%S)%s*$") })
	vim.cmd("startinsert!")
end, { silent = true, desc = "Add comment below" })

map("n", "gcO", function()
	local cs = vim.bo.commentstring
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local indent = vim.fn.indent(line)
	local comment = cs:format("")
	local padding = string.rep(vim.bo.expandtab and " " or "\t", vim.bo.expandtab and indent or indent / vim.bo.tabstop)
	vim.api.nvim_buf_set_lines(0, line - 1, line - 1, false, { padding .. comment })
	vim.api.nvim_win_set_cursor(0, { line, #padding + #comment:match("^(.-%S)%s*$") })
	vim.cmd("startinsert!")
end, { silent = true, desc = "Add comment above" })

-------------------------------------------------------------------------------
-- misc
-------------------------------------------------------------------------------
map("n", "<leader>y", function()
	vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy relative path" })

map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>M", "<cmd>Mason<cr>", { desc = "Mason" })

-------------------------------------------------------------------------------
-- toggle options
-------------------------------------------------------------------------------
map("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })
map("n", "<leader>td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-------------------------------------------------------------------------------
-- diagnostics
-------------------------------------------------------------------------------
vim.diagnostic.config({
	virtual_text = { current_line = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = "󰌵 ",
		},
	},
	underline = true,
	severity_sort = true,
	float = { source = true },
})

map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostics" })

map("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Prev diagnostic" })

map("n", "]w", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN })
end, { desc = "Next warning" })
map("n", "[w", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN })
end, { desc = "Prev warning" })

map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev error" })

-------------------------------------------------------------------------------
-- terminal
-------------------------------------------------------------------------------
local terminal = require("config.terminal")
map("n", "<C-\\>", terminal.toggle, { desc = "Toggle terminal" })
map("t", "<C-\\>", terminal.toggle, { desc = "Toggle terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map("n", "<leader>j", terminal.toggle_jjui, { desc = "JJui" })
