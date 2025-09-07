local ok, ctx = pcall(require, "treesitter-context")
if not ok then
	return
end

ctx.setup({
	enable = true,
	max_lines = 3,
	min_window_height = 0,
	multiline_threshold = 1,
	trim_scope = "outer",
	mode = "cursor",
	separator = "─",
	zindex = 20,
})

vim.keymap.set("n", "<leader>uc", function()
	require("treesitter-context").toggle()
end, { desc = "Toggle TS context" })
