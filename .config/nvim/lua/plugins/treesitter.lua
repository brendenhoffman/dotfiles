local M = {}

function M.bootstrap()
	local ok, ts = pcall(require, "nvim-treesitter")
	if not ok then
		return
	end
	ts.install({
		"bash", "c", "lua", "markdown", "markdown_inline",
		"query", "vim", "vimdoc",
	}):wait(120000)
end

return M
