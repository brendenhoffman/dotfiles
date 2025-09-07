local M = {}

local function collect_expected()
	local ext = require("externals")
	local langs = (require("langs") or {})
	local allowed = {}
	for _, l in ipairs(langs) do
		allowed[l] = true
	end

	local want = {}
	for lang, list in pairs(ext.by_lang or {}) do
		if allowed[lang] then
			for _, exe in ipairs(list) do
				want[exe] = true
			end
		end
	end
	for _, exe in ipairs(ext.extras or {}) do
		want[exe] = true
	end
	return vim.tbl_keys(want)
end

local function check_all()
	local ext = require("externals")
	local wanted = collect_expected()
	table.sort(wanted)
	local missing, present = {}, {}
	for _, exe in ipairs(wanted) do
		if vim.fn.executable(exe) == 1 then
			table.insert(present, exe)
		else
			table.insert(missing, { exe = exe, hint = ext.hints and ext.hints[exe] or nil })
		end
	end
	return present, missing
end

function M.bootstrap()
	-- run when :BootstrapAll is invoked
	M.run_check()
end

function M.run_check()
	local UI = require("bootstrap_ui")
	local present, missing = check_all()
	if #missing == 0 then
		UI.add("External tools", vim.log.levels.INFO, { ("All %d tools present"):format(#present) })
		return
	end
	local lines = {}
	for _, m in ipairs(missing) do
		table.insert(lines, ("missing: %s%s"):format(m.exe, m.hint and ("  → " .. m.hint) or ""))
	end
	UI.add("External tools", vim.log.levels.WARN, lines)
end

-- Register a user command so you can run it anytime
vim.api.nvim_create_user_command("CheckExternalTools", function()
	M.run_check()
	require("bootstrap_ui").open()
	require("bootstrap_ui").update_quickfix()
	vim.cmd("copen")
end, {})

return M
