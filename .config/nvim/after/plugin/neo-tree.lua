local ok, neotree = pcall(require, "neo-tree")
if not ok then
	return
end

neotree.setup({
	window = { width = 28 },
	popup_border_style = "rounded",
	default_component_configs = {
		icon = { folder_closed = "", folder_open = "" },
		modified = { symbol = "●" },
		git_status = { symbols = { added = "A", modified = "M", deleted = "D", renamed = "R", unstaged = "U" } },
		indent = {
			with_markers = true,
			with_expanders = true,
			expander_collapsed = "",
			expander_expanded = "",
			-- expander_collapsed = ">",
			-- expander_expanded  = "v",
		},
	},
	filesystem = {
		hijack_netrw_behavior = "open_default",
		bind_to_cwd = true,
		follow_current_file = { enabled = true },
		use_libuv_file_watcher = true,
		filtered_items = { hide_dotfiles = false, hide_gitignored = true },
	},

	-- Apply UI tweaks exactly when entering the tree buffer
	event_handlers = {
		{
			event = "neo_tree_buffer_enter",
			handler = function()
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				vim.opt_local.signcolumn = "no"
				vim.opt_local.statuscolumn = ""
				vim.opt_local.fillchars:append({ eob = " " })
			end,
		},
	},
})

-- keys: toggle & reveal current file
vim.keymap.set("n", "<leader>e", ":Neotree toggle left reveal_force_cwd<CR>", { silent = true, desc = "Explorer" })
vim.keymap.set("n", "<leader>E", ":Neotree focus left<CR>", { silent = true, desc = "Explorer focus" })

-- auto-open even when starting with a file
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		if vim.env.MAN_PN and vim.env.MAN_PN ~= "" then
			return
		end
		vim.cmd("Neotree show left reveal_force_cwd")
	end,
})
