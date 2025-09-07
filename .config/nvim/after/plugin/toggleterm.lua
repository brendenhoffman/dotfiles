local ok, tt = pcall(require, "toggleterm")
if not ok then
	return
end

tt.setup({
	start_in_insert = true,
	shade_terminals = true,
	direction = "horizontal",
	size = 12,
})

vim.g.TT_dir = "horizontal" -- default each new nvim session
local function _size_for(dir)
	return (dir == "horizontal") and 12 or 60
end

-- detect if any toggleterm window is currently visible
local function _is_toggleterm_open()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "toggleterm" then
			return true
		end
	end
	return false
end

-- Toggle using the current session's direction
function _G.TT_toggle()
	local dir = vim.g.TT_dir or "horizontal"
	local size = _size_for(dir)
	require("toggleterm").toggle(0, size, nil, dir)
end

-- Set direction (optionally re-open if it's currently shown)
local function _set_dir(dir, reopen_if_open)
	if dir ~= "horizontal" and dir ~= "vertical" then
		return
	end
	vim.g.TT_dir = dir
	if _is_toggleterm_open() and reopen_if_open then
		-- close current, then open in new direction
		require("toggleterm").toggle(0) -- close
		require("toggleterm").toggle(0, _size_for(dir), nil, dir) -- reopen
	else
		vim.notify("TT direction → " .. dir)
	end
end

-- Swap direction (and move the terminal if it's visible)
function _G.TT_swap()
	local newdir = (vim.g.TT_dir == "horizontal") and "vertical" or "horizontal"
	_set_dir(newdir, true)
end

-- Explicit setters
function _G.TT_set_h()
	_set_dir("horizontal", true)
end
function _G.TT_set_v()
	_set_dir("vertical", true)
end

-- Toggle
vim.keymap.set("n", "TT", _G.TT_toggle, { desc = "Toggle terminal" })
vim.keymap.set("t", "TT", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
	_G.TT_toggle()
end, { desc = "Toggle terminal", silent = true })

-- Swap orientation
vim.keymap.set("n", "<leader>ts", _G.TT_swap, { desc = "Terminal: swap H/V" })

-- Explicit orientation
vim.keymap.set("n", "<leader>th", _G.TT_set_h, { desc = "Terminal: horizontal" })
vim.keymap.set("n", "<leader>tv", _G.TT_set_v, { desc = "Terminal: vertical" })
