local M = {}

local function coc_config_dir()
	local xdg = vim.env.XDG_CONFIG_HOME
	local base = (xdg and #xdg > 0) and xdg or vim.fn.expand("~/.config")
	return base .. "/coc"
end

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
	local pkg = coc_config_dir() .. "/extensions/package.json"
	if vim.fn.filereadable(pkg) ~= 1 then
		return {}
	end
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

local function is_headless()
	return #vim.api.nvim_list_uis() == 0
end

function M.bootstrap(opts)
	opts = opts or {}
	-- if headless, force sync
	local sync = opts.sync or is_headless()
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

	local ex = "CocInstall -sync " .. table.concat(missing, " ")

	if sync then
		-- synchronous (installer/CI)
		local cmd = ('nvim --headless -c "%s" -c "qall"'):format(ex)
		local _ = vim.fn.system(cmd)
		local code = vim.v.shell_error
		if code == 0 then
			UI.add("coc.nvim", vim.log.levels.INFO, { "Installed: " .. table.concat(missing, ", ") })
		else
			UI.add("coc.nvim", vim.log.levels.WARN, { "CocInstall exit code " .. code })
		end
	else
		-- async (interactive): open UI so you see progress, but don’t freeze
		UI.ensure_open()
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
				pcall(require("bootstrap_ui").update_quickfix)
			end)
		else
			vim.fn.jobstart({ "nvim", "--headless", "-c", ex, "-c", "qall" }, {
				on_exit = function(_, code)
					if code == 0 then
						UI.add("coc.nvim", vim.log.levels.INFO, { "Installed: " .. table.concat(missing, ", ") })
					else
						UI.add("coc.nvim", vim.log.levels.WARN, { "CocInstall exit code " .. code })
					end
					pcall(require("bootstrap_ui").update_quickfix)
				end,
			})
		end
	end
end

vim.g.coc_disable_progress = 1
return M
