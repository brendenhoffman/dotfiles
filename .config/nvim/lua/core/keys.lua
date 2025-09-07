local map = vim.keymap.set
map("v", "<C-c>", '"+y', { noremap = true })
map("n", "<C-p>", '"+P', { noremap = true })
map("i", "jj", "<Esc>", { noremap = true })
map("n", ";", ":", { noremap = true })
map("n", "qq", ":qa<CR>", { noremap = true })
map("n", "ww", ":w<CR>", { noremap = true })
map("n", "wq", ":wqa<CR>", { noremap = true })
map("n", "q1", ":qa!<CR>", { noremap = true })
map("n", "<leader>sv", ":source ~/.config/nvim/init.lua<CR>", { noremap = true })
map("n", "QQ", ":q<CR>", { noremap = true, silent = true })
map("n", "wa", ":wa<CR>", { noremap = true })
map("v", "<Tab>", ">gv", { noremap = true, silent = true })
map("v", "<S-Tab>", "<gv", { noremap = true, silent = true })

-- Shellcheck current file
map("n", "<leader>s", ":!clear && shellcheck %<CR>", { noremap = true, silent = true })
