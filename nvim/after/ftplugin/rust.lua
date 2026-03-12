-- Rust ftplugin: custom formatexpr that preserves list indentation in comments

vim.opt_local.textwidth = 80

local function format_rust_comments()
	local start_line = vim.v.lnum
	local end_line = start_line + vim.v.count - 1

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if #lines == 0 then
		return 0
	end

	-- Detect comment prefix (//!, ///, //) from first line
	local first_line = lines[1]
	local prefix = first_line:match("^(%s*//[/!]?)") or first_line:match("^(%s*//)")

	-- Fall back to internal formatting if not a comment
	if not prefix then
		return 1
	end

	local fmt_prefix = prefix:gsub("%s+$", "")
	local tw = vim.bo.textwidth > 0 and vim.bo.textwidth or 80

	local input = table.concat(lines, "\n")
	local cmd = string.format("fmt -w %d -p '%s'", tw, fmt_prefix)
	local result = vim.fn.system(cmd, input)

	if vim.v.shell_error ~= 0 then
		return 1
	end

	local formatted = vim.split(result, "\n", { trimempty = true })
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, formatted)

	return 0
end

_G.RustFormatComments = format_rust_comments
vim.opt_local.formatexpr = "v:lua.RustFormatComments()"
