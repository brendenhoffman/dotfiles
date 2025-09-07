local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end
local builtin = require("telescope.builtin")

telescope.setup({
	defaults = {
		layout_config = { preview_width = 0.6 },
		sorting_strategy = "descending",
		mappings = {
			i = {
				-- Open current file at selected commit in vsplit
				["<C-o>"] = function(prompt_bufnr)
					local actions = require("telescope.actions")
					local state = require("telescope.actions.state")
					local entry = state.get_selected_entry()
					actions.close(prompt_bufnr)
					local sha = entry and entry.value or entry[1]
					local file = vim.fn.expand("%")
					if file == "" then
						return
					end
					local content = vim.fn.systemlist("git show " .. sha .. ":" .. vim.fn.shellescape(file))
					if vim.v.shell_error ~= 0 or (#content == 1 and content[1]:match("^fatal:")) then
						vim.notify("File didn't exist at that commit", vim.log.levels.WARN)
						return
					end
					vim.cmd("vsplit | enew")
					vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "wipe", false
					vim.cmd("file " .. file .. "@" .. sha)
					vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
				end,
				["<C-d>"] = require("telescope.actions").preview_scrolling_down,
				["<C-u>"] = require("telescope.actions").preview_scrolling_up,
			},
		},
	},
})

pcall(function()
	telescope.load_extension("fzf")
end)

-- All commits
vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits (project)" })
vim.keymap.set("n", "<leader>gb", builtin.git_bcommits, { desc = "Git commits (buffer)" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })

-- Snapshots-only pickers
vim.keymap.set("n", "<leader>gS", function()
	builtin.git_commits({
		git_command = { "git", "log", "--grep=snap:", "--fixed-strings", "--date=short", "--pretty=%H %ad %s" },
	})
end, { desc = "Git snapshots (project)" })

vim.keymap.set("n", "<leader>gB", function()
	local file = vim.fn.expand("%")
	if file == "" then
		return
	end
	builtin.git_bcommits({
		git_command = {
			"git",
			"log",
			"--grep=snap:",
			"--fixed-strings",
			"--date=short",
			"--pretty=%H %ad %s",
			"--",
			file,
		},
	})
end, { desc = "Git snapshots (buffer)" })
