vim.opt.mouse = "a"
vim.opt.hlsearch = false
vim.cmd([[filetype plugin on]])
vim.opt.encoding = "utf-8"
vim.opt.number = true
vim.opt.relativenumber = false
vim.o.statuscolumn = [[%s%{&number ? v:lnum : ''}]]
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.clipboard:append("unnamedplus")
vim.cmd("highlight CursorLine guibg=#202123")
vim.opt.cursorline = true
vim.opt.guicursor = "n-v-c:block,i:hor25-blinkon100-blinkoff75"
vim.opt.signcolumn = "no"
vim.cmd("set verbose=0")
vim.opt.wildmode = { "longest", "list", "full" }
vim.opt.termguicolors = true
vim.opt.hidden = true
vim.opt.confirm = true

-- Indentation
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
