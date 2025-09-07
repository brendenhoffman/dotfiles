-- Highlight 80th column globally
vim.api.nvim_set_hl(0, "OverLength", { bg = "#303030" })

vim.g.overlength_col = 80
vim.g.overlength_on = true

local function pat()
	return ([[\%%>%dc.\+]]):format(vim.g.overlength_col)
end

local function clear_win(win)
	local id = vim.w.overlength_id
	if id and id > 0 then
		pcall(vim.fn.matchdelete, id, win)
	end
	vim.w.overlength_id = nil
end

local function apply_win()
	if not vim.g.overlength_on then
		return
	end
	clear_win(0)
	-- high priority so it’s less likely to be overridden
	vim.w.overlength_id = vim.fn.matchadd("OverLength", pat(), 100)
end

local aug = vim.api.nvim_create_augroup("OverLengthMinimal", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinNew", "TabEnter" }, { group = aug, callback = apply_win })
vim.api.nvim_create_autocmd("WinClosed", {
	group = aug,
	callback = function(args)
		clear_win(tonumber(args.match) or 0)
	end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
	group = aug,
	callback = function()
		vim.api.nvim_set_hl(0, "OverLength", { bg = "#303030" })
		apply_win()
	end,
})

vim.api.nvim_create_user_command("ToggleColumnHighlight", function()
	vim.g.overlength_on = not vim.g.overlength_on
	if vim.g.overlength_on then
		apply_win()
	else
		clear_win(0)
	end
	print("OverLength " .. (vim.g.overlength_on and (">" .. vim.g.overlength_col) or "OFF"))
end, {})

vim.api.nvim_create_user_command("SetOverLength", function(opts)
	local n = tonumber(opts.args)
	if not n or n < 1 then
		print("Usage: :SetOverLength <column>")
		return
	end
	vim.g.overlength_col = n
	if vim.g.overlength_on then
		apply_win()
	end
	print("OverLength >" .. n)
end, { nargs = 1 })

apply_win()

-- Snap commands via external git-snap script
local function run_snap(args)
	if vim.fn.executable("git-snap") == 0 then
		vim.notify("git-snap not found in PATH", vim.log.levels.ERROR)
		return
	end
	vim.system(args, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				print((obj.stdout or ""):gsub("%s+$", ""))
			else
				vim.notify((obj.stderr or "git-snap failed"):gsub("%s+$", ""), vim.log.levels.ERROR)
			end
		end)
	end)
end

vim.api.nvim_create_user_command("Snap", function()
	vim.cmd("write")
	run_snap({ "git-snap" })
end, {})

vim.api.nvim_create_user_command("SnapBuf", function()
	local file = vim.fn.expand("%:p")
	if file == "" then
		print("No file")
		return
	end
	vim.cmd("write")
	run_snap({ "git-snap", "--file", file })
end, {})
