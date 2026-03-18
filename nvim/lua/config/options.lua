local o = vim.opt

-- indentation
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true

-- line numbers
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.statuscolumn = '%s%=%{v:virtnum>0?"":v:relnum?v:relnum:v:lnum}  '

-- display
o.wrap = false
o.cursorline = true
o.showmode = false
o.termguicolors = true
o.fillchars = "eob: "
o.laststatus = 3

-- scrolling
o.scrolloff = 8
o.sidescrolloff = 8

-- search
o.ignorecase = true
o.smartcase = true

-- editing
o.backspace = "indent,eol,start"
o.textwidth = 80
o.clipboard = "unnamedplus"
o.mouse = "a"

-- splits
o.splitbelow = true
o.splitright = true

-- files
o.autoread = true
o.undofile = true
o.swapfile = false

-- folds
o.foldlevelstart = 99

-- timing
o.updatetime = 250
o.timeoutlen = 300

-- misc
o.shortmess:append("sI")

-- leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "
