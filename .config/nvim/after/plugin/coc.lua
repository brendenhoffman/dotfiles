vim.keymap.set(
	"i",
	"<TAB>",
	[[coc#pum#visible() ? coc#pum#confirm() : "\<C-t>"]],
	{ silent = true, noremap = true, expr = true, replace_keycodes = false }
)
vim.cmd("hi CocMenuSel ctermbg=237 guibg=#13354A")
