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

-- Run CocInstall in a child nvim. If opts.sync = true, block (for headless installer).
local function run_coc_install(missing, opts)
	opts = opts or {}
	local UI = require("bootstrap_ui")
	local ex = "CocInstall -sync " .. table.concat(missing, " ")

	if opts.sync then
		-- headless/CI: block until done
		local cmd = 'nvim --headless -c "' .. ex .. '" -c "qall"'
		local _ = vim.fn.system(cmd)
		local code = vim.v.shell_error
		if code == 0 then
			UI.add("coc.nvim", vim.log.levels.INFO, { "Installed: " .. table.concat(missing, ", ") })
		else
			UI.add("coc.nvim", vim.log.levels.WARN, { "CocInstall exit code " .. code })
		end
		return
	end

	-- interactive: async, non-blocking
	if vim.system then
		vim.system({ "nvim", "--headless", "-c", ex, "-c", "qall" }, { text = true }, function(res)
			if res.code == 0 then
				UI.add("coc.nvim", vim.log.levels.INFO, { "Installed: " .. table.concat(missing, ", ") })
			else
				UI.add("coc.nvim", vim.log.levels.WARN, {
					"CocInstall exit code " .. tostring(res.code),
					(res.stderr or ""):gsub("%s+$", ""),
				})
			end
			-- optionally: refresh quickfix panel
			pcall(require("bootstrap_ui").update_quickfix)
		end)
	else
		vim.fn.jobstart({ "nvim", "--headless", "-c", ex, "-c", "qall" }, {
			on_exit = function(_, code)
				if code == 0 then
					require("bootstrap_ui").add(
						"coc.nvim",
						vim.log.levels.INFO,
						{ "Installed: " .. table.concat(missing, ", ") }
					)
				else
					require("bootstrap_ui").add("coc.nvim", vim.log.levels.WARN, { "CocInstall exit code " .. code })
				end
				pcall(require("bootstrap_ui").update_quickfix)
			end,
		})
	end
end

function M.bootstrap(opts)
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

	run_coc_install(missing, opts)
end

vim.g.coc_disable_progress = 1
return M
