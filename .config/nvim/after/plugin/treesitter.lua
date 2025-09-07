local ok, ts = pcall(require, "nvim-treesitter.configs")
if not ok then
	return
end
ts.setup({
	ensure_installed = {
		"c",
		"lua",
		"vim",
		"vimdoc",
		"query",
		"markdown",
		"markdown_inline",
	},
	sync_install = false,
	auto_install = true,
	ignore_install = { "javascript" },
	highlight = {
		enable = true,
		disable = function(lang, buf)
			local max = 500 * 1024
			local ok2, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			return ok2 and stats and stats.size > max
		end,
		additional_vim_regex_highlighting = false,
	},
})

vim.filetype.add({
	extension = {
		zsh = "sh",
	},
})
