-- Disable autocomment continuation
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	command = "setlocal formatoptions-=c formatoptions-=o formatoptions-=r",
})

-- Trailing whitespace highlight + trim on save
vim.cmd([[highlight ExtraWhitespace ctermbg=red guibg=red]])
vim.fn.matchadd("ExtraWhitespace", [[\s\+$]])
vim.api.nvim_create_autocmd("InsertEnter", { pattern = "*", command = [[match ExtraWhitespace /\s\+\%#\@<!$/]] })
vim.api.nvim_create_autocmd("InsertLeave", { pattern = "*", command = [[match ExtraWhitespace /\s\+$/]] })
vim.api.nvim_create_autocmd("BufWinLeave", { pattern = "*", command = "call clearmatches()" })

-- Trim after write
vim.api.nvim_create_autocmd("BufWritePost", { pattern = "*", command = [[%s/\s\+$//e]] })
