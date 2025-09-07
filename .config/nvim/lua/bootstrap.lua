local M = {}

local UI = require("bootstrap_ui")

-- discover modules under lua/plugins/**/*.lua and any _G.plugin_bootstrap hooks
local function discover()
	local mods = {}

	-- lua/plugins/**.lua -> "plugins.foo.bar"
	local base = vim.fn.stdpath("config") .. "/lua/plugins"
	local files = vim.fn.glob(base .. "/**/*.lua", true, true)
	for _, f in ipairs(files) do
		local rel = f:sub(#(vim.fn.stdpath("config") .. "/lua/") + 1, -5) -- strip prefix + ".lua"
		table.insert(mods, (rel:gsub("/", ".")))
	end

	-- global hooks registered from after/plugin/*.lua
	if type(_G.plugin_bootstrap) == "table" then
		for name, _ in pairs(_G.plugin_bootstrap) do
			table.insert(mods, "__GLOBAL__:" .. name)
		end
	end

	return mods
end

-- run a single hook (module.bootstrap or _G.plugin_bootstrap[name]) and record in UI
local function run_one(id)
	local start = vim.loop.hrtime()
	local ok, err

	if id:match("^__GLOBAL__:") then
		local name = id:sub(12)
		local fn = _G.plugin_bootstrap and _G.plugin_bootstrap[name]
		if type(fn) == "function" then
			ok, err = pcall(fn)
		else
			ok, err = false, "no function"
		end
	else
		local ok_load, m = pcall(require, id)
		if ok_load and type(m) == "table" and type(m.bootstrap) == "function" then
			ok, err = pcall(m.bootstrap)
		else
			ok, err = false, "no bootstrap()"
		end
	end

	local ms = (vim.loop.hrtime() - start) / 1e6
	if ok then
		UI.add(id .. " ✓", vim.log.levels.INFO, { ("Completed in %.0f ms"):format(ms) })
	else
		UI.add(id .. " ✗", vim.log.levels.WARN, { tostring(err), ("(%.0f ms)"):format(ms) })
	end
end

function M.run()
	-- reset the UI report for this run
	UI.entries = {}
	UI.have_warn = false

	local items = discover()
	if #items == 0 then
		UI.add("Bootstrap", vim.log.levels.INFO, { "No bootstrap hooks found." })
		UI.open()
		return
	end

	-- async chain: run one item every 30ms so UI stays responsive
	local i = 1
	local function step()
		if i > #items then
			if UI.have_warn then
				UI.update_quickfix()
				UI.open()
				vim.cmd("copen")
			else
				vim.notify("Bootstrap complete ✓", vim.log.levels.INFO)
			end
			return
		end

		local id = items[i]
		i = i + 1
		vim.schedule(function()
			run_one(id)
			vim.defer_fn(step, 30)
		end)
	end

	vim.notify(("Running %d bootstrap hooks…"):format(#items), vim.log.levels.INFO)
	step()
end

return M
