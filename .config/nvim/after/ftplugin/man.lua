local function pagerize()
	-- kill numbers and your custom statuscolumn (this removes [RO] too)
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.statuscolumn = ""
	vim.wo.statuscolumn = ""
	vim.opt_local.wrap = true
	vim.opt_local.linebreak = true
	vim.opt_local.breakindent = true
	vim.opt_local.list = false
	vim.opt_local.colorcolumn = ""
	vim.opt_local.cursorline = false
	vim.opt_local.foldenable = false
	vim.opt_local.fillchars:append({ eob = " " }) -- hide ~ on empty lines

	-- close neo-tree if it slipped open
	pcall(vim.cmd, "Neotree close")
end

pagerize()

-- Some man open paths re-trigger window opts; re-apply defensively
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
	buffer = 0,
	callback = function()
		if vim.bo.filetype == "man" then
			pagerize()
		end
	end,
})

-- If pager came in via "man://..." URI, catch that too
vim.api.nvim_create_autocmd("BufWinEnter", {
	pattern = "man://*",
	callback = function()
		if vim.bo.filetype == "man" then
			pagerize()
		end
	end,
})

-- light keybinds for pager feel
vim.keymap.set("n", "q", "<cmd>quit<CR>", { buffer = true, nowait = true, desc = "Quit man" })
vim.keymap.set("n", "<Esc>", "<cmd>quit<CR>", { buffer = true, nowait = true })
-- open the page for the word under cursor (like “follow link”)
vim.keymap.set("n", "<CR>", "<cmd>Man <cword><CR>", { buffer = true, desc = "Open man for word" })

-- OPTIONAL: disable diagnostics/lint in man buffers
vim.schedule(function()
	vim.b.coc_diagnostic_disable = 1 -- CoC: stop diagnostics here
end)
