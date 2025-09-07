local M = {}

local function wanted_from_langs()
	local langs = (pcall(require, "langs") and require("langs")) or {}
	local ext = (pcall(require, "externals") and require("externals")) or { coc_by_lang = {} }
	local set = {}
	for _, l in ipairs(langs) do
		for _, extname in ipairs((ext.coc_by_lang[l] or {})) do
			set[extname] = true
		end
	end
	-- optional: also read extras from a static file if you want
	local listfile = vim.fn.expand("~/.config/nvim/coc-extensions.txt")
	if vim.fn.filereadable(listfile) == 1 then
		for _, line in ipairs(vim.fn.readfile(listfile)) do
			if not line:match("^%s*$") and not line:match("^%s*#") then
				set[vim.trim(line)] = true
			end
		end
	end
	return vim.tbl_keys(set)
end

local function read_installed()
	local pkg = vim.fn.expand("~/.config/coc/extensions/package.json")
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
	local cmd = { "nvim", "--headless", '+"CocInstall -sync ' .. table.concat(missing, " ") .. '"', "+qall" }
	local out, err = {}, {}
	local job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, d)
			if d then
				vim.list_extend(out, d)
			end
		end,
		on_stderr = function(_, d)
			if d then
				vim.list_extend(err, d)
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				UI.add("coc.nvim", vim.log.levels.INFO, { "Installed: " .. table.concat(missing, ", ") })
			else
				UI.add("coc.nvim", vim.log.levels.WARN, { "CocInstall exit code " .. code, table.concat(err, " ") })
			end
		end,
	})
	if job <= 0 then
		UI.add("coc.nvim", vim.log.levels.WARN, { "Failed to start headless CocInstall job" })
	end
end

vim.g.coc_disable_progress = 1
return M
