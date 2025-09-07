--Buffer counts
local function _buf_counts()
	local listed = vim.fn.getbufinfo({ buflisted = 1 })
	local total = #listed
	local modified = 0
	for _, b in ipairs(listed) do
		if b.changed == 1 then
			modified = modified + 1
		end
	end

	-- how many buffers are visible in windows?
	local visible = 0
	local seen = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local bufnr = vim.api.nvim_win_get_buf(win)
		if not seen[bufnr] and vim.bo[bufnr].buflisted then
			seen[bufnr] = true
			visible = visible + 1
		end
	end

	return total, modified, visible
end

-- "bufs:3 ●2" (hide when only one buffer)
local function buffers_indicator_text()
	local total, modified = _buf_counts()
	if total <= 1 then
		return ""
	end
	local s = ("bufs:%d"):format(total)
	if modified > 0 then
		s = s .. (" ●%d"):format(modified)
	end
	return s
end

local function _mode()
	return vim.fn.mode(1):sub(1, 1)
end

-- mode-aware color: yellow normally, dark text in Insert so it's readable
local function buffers_indicator_color()
	local total, modified = _buf_counts()
	if modified == 0 or total <= 1 then
		return nil
	end
	if _mode() == "i" then
		return { fg = "#000000", gui = "bold" }
	else
		return { fg = "#E5C07B", gui = "bold" }
	end
end

local BuffsComponent = {
	buffers_indicator_text,
	color = buffers_indicator_color,
}

--Lualine setup
local ok, lualine = pcall(require, "lualine")
if not ok then
	return
end

local seps = { left = "", right = "" }
local comps = { left = "", right = "" }

lualine.setup({
	options = {
		theme = "powerline",
		icons_enabled = true,
		component_separators = comps,
		section_separators = seps,
		always_divide_middle = true,
		globalstatus = false,
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress", BuffsComponent },
		lualine_z = { "location" },
	},
})

-- Force refresh when buffers change (helps with plugins opening files off-cycle)
vim.api.nvim_create_autocmd({
	"BufAdd",
	"BufDelete",
	"BufEnter",
	"BufModifiedSet",
	"BufWritePost",
	"WinEnter",
	"WinClosed",
	"TabEnter",
	"TabLeave",
}, {
	callback = function()
		pcall(function()
			require("lualine").refresh({ place = { "statusline" } })
		end)
	end,
})

-- Detect mode change
vim.api.nvim_create_autocmd("ModeChanged", {
	callback = function()
		pcall(function()
			require("lualine").refresh({ place = { "statusline" } })
		end)
	end,
})
