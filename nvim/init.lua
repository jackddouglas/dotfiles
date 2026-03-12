local vim = vim
local o = vim.opt

o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.wrap = false
o.autoread = true
o.signcolumn = "yes"
o.number = true
o.relativenumber = true
o.cursorline = true
o.backspace = "indent,eol,start"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.swapfile = false
o.fillchars = "eob: "
o.foldlevelstart = 99
o.termguicolors = true
o.clipboard = "unnamedplus"
o.updatetime = 250
o.splitbelow = true
o.splitright = true
o.laststatus = 3
o.scrolloff = 8
o.sidescrolloff = 8
o.showmode = false
o.mouse = "a"
o.timeoutlen = 300
o.shortmess:append("sI")
o.winborder = "single"

local g = vim.g

g.mapleader = " "
g.maplocalleader = " "

local map = vim.keymap.set

map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear search highlight" })

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

-- manage buffers
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

-- manage windows
map("n", "<leader>wd", confirm_close("close"), { desc = "Close window" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "Close other windows" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<leader>\\", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>w=", "<cmd>wincmd =<cr>", { desc = "Equalize windows" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- quit
map("n", "<leader>qq", "<cmd>confirm qall<cr>", { desc = "Quit all" })
map("n", "<leader>qw", confirm_close("quit"), { desc = "Quit window" })

-- find
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
		local level = item.style and item.style:match("(%w+)$") or ""
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

-- git
map("n", "<leader>gs", "<cmd>FzfLua git_status<cr>", { desc = "Git status" })
map("n", "<leader>gd", "<cmd>FzfLua git_diff<cr>", { desc = "Git diff (changed files)" })
map("n", "<leader>gH", "<cmd>FzfLua git_hunks<cr>", { desc = "Git hunks (search diffs)" })
map("n", "<leader>gc", "<cmd>FzfLua git_commits<cr>", { desc = "Git commits (project)" })
map("n", "<leader>gC", "<cmd>FzfLua git_bcommits<cr>", { desc = "Git commits (buffer)" })
map("n", "<leader>gb", "<cmd>FzfLua git_blame<cr>", { desc = "Git blame (buffer)" })
map("n", "<leader>gB", "<cmd>FzfLua git_branches<cr>", { desc = "Git branches" })
map("n", "<leader>gS", "<cmd>FzfLua git_stash<cr>", { desc = "Git stash" })

-- add comment above/below
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

-- copy relative filepath
map("n", "<leader>y", function()
	vim.fn.setreg("+", vim.fn.expand("%"))
end, { desc = "Copy relative path" })

-- quick access
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>M", "<cmd>Mason<cr>", { desc = "Mason" })

-- toggle options
map("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })
map("n", "<leader>td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- diagnostics
vim.diagnostic.config({
	virtual_text = { current_line = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
	underline = true,
	severity_sort = true,
	float = { border = "single", source = true },
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

-- LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local b = args.buf
		map("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", { buffer = b, desc = "Go to definition" })
		map("n", "gD", "<cmd>FzfLua lsp_declarations<cr>", { buffer = b, desc = "Go to declaration" })
		map("n", "gr", "<cmd>FzfLua lsp_references<cr>", { buffer = b, desc = "Go to references" })
		map("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", { buffer = b, desc = "Go to implementations" })
		map("n", "gy", "<cmd>FzfLua lsp_typedefs<cr>", { buffer = b, desc = "Go to type definition" })
		map("n", "K", vim.lsp.buf.hover, { buffer = b, desc = "Hover" })
		map("n", "<leader>cr", vim.lsp.buf.rename, { buffer = b, desc = "Rename symbol" })
		map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = b, desc = "Code action" })
		map("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = b, desc = "Signature help" })
		map("n", "<leader>cl", "<cmd>checkhealth vim.lsp<cr>", { buffer = b, desc = "LSP info" })

		local client = vim.lsp.get_client_by_id(args.data.client_id)

		-- rust-analyzer: switch cargo target
		if client and client.name == "rust_analyzer" then
			map("n", "<leader>ct", function()
				local targets = {
					{ label = "default (host triple)", value = nil },
					{ label = "wasm32-unknown-unknown", value = "wasm32-unknown-unknown" },
					{ label = "aarch64-apple-darwin", value = "aarch64-apple-darwin" },
				}
				vim.ui.select(targets, {
					prompt = "rust-analyzer cargo target:",
					format_item = function(item)
						return item.label
					end,
				}, function(choice)
					if not choice then
						return
					end
					local target = choice.value
					-- allow typing a custom target
					local function apply(t)
						vim.lsp.config("rust_analyzer", {
							settings = {
								["rust-analyzer"] = {
									cargo = { target = t or vim.NIL },
								},
							},
						})
						-- restart all rust-analyzer clients so the new config takes effect
						for _, c in ipairs(vim.lsp.get_clients({ name = "rust_analyzer" })) do
							local bufs = vim.lsp.get_buffers_by_client_id(c.id)
							c:stop()
							vim.defer_fn(function()
								for _, buf in ipairs(bufs) do
									vim.lsp.start(vim.lsp.config.rust_analyzer, { bufnr = buf })
								end
							end, 500)
						end
						vim.notify("rust-analyzer target: " .. (t or "default"), vim.log.levels.INFO)
					end
					apply(target)
				end)
			end, { buffer = args.buf, desc = "Switch rust-analyzer target" })
		end

		-- enable inlay hints
		if client and client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
		end

		-- highlight references of symbol under cursor
		if client and client:supports_method("textDocument/documentHighlight") then
			local group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
			vim.api.nvim_clear_autocmds({ group = group, buffer = args.buf })
			vim.api.nvim_create_autocmd("CursorHold", {
				group = group,
				buffer = args.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				group = group,
				buffer = args.buf,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end,
})

-- enable wrap for prose
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "gitcommit", "typst" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
	end,
})

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- restore cursor position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- auto-resize splits when terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- q to close popup-style buffers
vim.api.nvim_create_autocmd("FileType", {
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

-- lazy
require("config.lazy")

-- terminal
local terminal = require("config.terminal")
map("n", "<C-\\>", terminal.toggle, { desc = "Toggle terminal" })
map("t", "<C-\\>", terminal.toggle, { desc = "Toggle terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- LSP server configuration
vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			cargo = {
				features = "all",
				targetDir = true,
			},
			check = {
				command = "clippy",
			},
			diagnostics = {
				styleLints = { enable = true },
			},
		},
	},
})

vim.lsp.enable("sourcekit")

-- link operators to the Operator group instead of Statement
vim.api.nvim_set_hl(0, "@operator.rust", { link = "Operator" })
