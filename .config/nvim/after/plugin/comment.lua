local ok, Comment = pcall(require, "Comment")
if not ok then
	return
end
Comment.setup({}) -- enables gc/gcc/gb mappings

-- Use plugin's provided <Plug> maps to avoid range quirks:
vim.keymap.set("n", "<leader>/", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment line" })
vim.keymap.set("x", "<leader>/", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment selection" })
