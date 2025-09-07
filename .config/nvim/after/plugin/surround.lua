local ok, surround = pcall(require, "nvim-surround")
if not ok then
	return
end
surround.setup({
	keymaps = {
		normal = "ys",
		normal_cur = "yss",
		normal_line = "yS",
		normal_cur_line = "ySS",
		visual = "as",
		delete = "ds",
		change = "cs",
	},
})
