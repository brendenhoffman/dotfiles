local ok, ts = pcall(require, "nvim-treesitter")
if not ok then
	return
end

ts.install({
	"bash", "c", "lua", "markdown", "markdown_inline",
	"query", "vim", "vimdoc",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function(ev)
		local max = 500 * 1024
		local name = vim.api.nvim_buf_get_name(ev.buf)
		local ok2, stats = pcall(vim.uv.fs_stat, name)
		if ok2 and stats and stats.size > max then
			return
		end
		pcall(vim.treesitter.start, ev.buf)
	end,
})

vim.filetype.add({
	extension = { zsh = "sh" },
})
