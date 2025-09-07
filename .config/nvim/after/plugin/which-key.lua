local ok, wk = pcall(require, "which-key")
if not ok then
	return
end

wk.setup({
	plugins = { spelling = { enabled = true } },
	win = { border = "rounded" },
})

wk.add({
	{ "<leader>e", desc = "Explorer" },
	{ "<leader>E", desc = "Explorer focus" },
	{ "<leader>s", desc = "Shellcheck" },
	{ "<leader>g", group = "Git" },
	{ "<leader>t", group = "Terminal" },
	{ "<leader>u", group = "UI/Notify" },
})
