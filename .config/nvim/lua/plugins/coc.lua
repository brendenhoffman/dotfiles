local M = {}

local function wanted_from_langs()
	local ok_langs, langs = pcall(require, "langs")
	if not ok_langs then
		langs = {}
	end
	local ok_ext, ext = pcall(require, "externals")
	if not ok_ext then
		ext = { coc_by_lang = {} }
	end

	local set = {}
	for _, l in ipairs(langs) do
		for _, extname in ipairs(ext.coc_by_lang[l] or {}) do
			set[extname] = true
		end
	end

	-- optional static extras
	local listfile = vim.fn.stdpath("config") .. "/coc-extensions.txt"
	if vim.fn.filereadable(listfile) == 1 then
		for _, line in ipairs(vim.fn.readfile(listfile)) do
			if not line:match("^%s*$") and not line:match("^%s*#") then
				set[vim.fn.trim(line)] = true
			end
		end
	end
	return vim.tbl_keys(set)
end

local function read_installed()
	local pkg = vim.fn.stdpath("config") .. "/coc/extensions/package.json"
	local ok, json = pcall(vim.fn.readfile, pkg)
	if not ok then
		return {}
	end
	local ok2, decoded = pcall(vim.json.decode, table.concat(json, "\n"))
	if not ok2 then
		return {}
	end
	local have = {}
	for name, _ in pairs(decoded.dependencies or {}) do
		have[name] = true
	end
	return have
end

function M.bootstrap()
	local UI = require("bootstrap_ui")
	local wanted = wanted_from_langs()
	if #wanted == 0 then
		UI.add("coc.nvim", vim.log.levels.INFO, { "No desired extensions (langs.lua empty?)" })
		return
	end

	local installed = read_installed()
	local missing = {}
	for _, name in ipairs(wanted) do
		if not installed[name] then
			table.insert(missing, name)
		end
	end

	if #missing == 0 then
		UI.add("coc.nvim", vim.log.levels.INFO, { ("All %d extensions present ✓"):format(#wanted) })
		return
	end

	local cmd = {
		"nvim",
		"--headless",
		"CocInstall",
		"-sync",
		unpack(missing),
		"+qall",
	}

	local out, err, code
	if vim.system then
		-- nvim ≥0.10: use new API
		local res = vim.system(cmd, { text = true }):wait()
		out, err, code = res.stdout, res.stderr, res.code
	else
		-- fallback for older nvim: blocking system()
		out = vim.fn.systemlist(table.concat(cmd, " "))
		code = vim.v.shell_error
		err = {}
	end

	if code == 0 then
		UI.add("coc.nvim", vim.log.levels.INFO, { "Installed: " .. table.concat(missing, ", ") })
	else
		UI.add("coc.nvim", vim.log.levels.WARN, {
			"CocInstall exit code " .. code,
			(type(err) == "string" and err or table.concat(err, " ")),
		})
	end
end

vim.g.coc_disable_progress = 1
return M
