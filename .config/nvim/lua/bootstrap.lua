-- lua/bootstrap.lua
local M = {}
local UI = require("bootstrap_ui")

local function is_headless()
	return #vim.api.nvim_list_uis() == 0
end

-- discover modules under lua/plugins/**.lua and any _G.plugin_bootstrap hooks
local function discover()
	local mods = {}

	local base = vim.fn.stdpath("config") .. "/lua/plugins"
	local files = vim.fn.glob(base .. "/**/*.lua", true, true)
	for _, f in ipairs(files) do
		local rel = f:sub(#(vim.fn.stdpath("config") .. "/lua/") + 1, -5) -- strip prefix + ".lua"
		table.insert(mods, (rel:gsub("/", "."))) -- "plugins.foo.bar"
	end

	if type(_G.plugin_bootstrap) == "table" then
		for name, _ in pairs(_G.plugin_bootstrap) do
			table.insert(mods, "__GLOBAL__:" .. name)
		end
	end
	return mods
end

-- run a single hook (module.bootstrap(opts) or _G.plugin_bootstrap[name](opts)) and record in UI
local function run_one(id, opts)
	local start = vim.loop.hrtime()
	local ok, err

	if id:match("^__GLOBAL__:") then
		local name = id:sub(12)
		local fn = _G.plugin_bootstrap and _G.plugin_bootstrap[name]
		if type(fn) == "function" then
			ok, err = pcall(fn, opts)
		else
			ok, err = false, "no function"
		end
	else
		local ok_load, m = pcall(require, id)
		if ok_load and type(m) == "table" and type(m.bootstrap) == "function" then
			ok, err = pcall(m.bootstrap, opts)
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

-- public: run all bootstraps; opts.sync forces synchronous execution
function M.run(opts)
	opts = opts or {}
	local sync = opts.sync or is_headless()

	-- reset the UI report for this run
	UI.entries = {}
	UI.have_warn = false

	local items = discover()
	if #items == 0 then
		UI.add("Bootstrap", vim.log.levels.INFO, { "No bootstrap hooks found." })
		if not sync then
			UI.open()
		end
		return
	end

	if sync then
		-- Synchronous: good for headless installer/CI
		for _, id in ipairs(items) do
			local ok, err = pcall(run_one, id, { sync = true })
			if not ok then
				UI.add(id .. " ✗", vim.log.levels.WARN, { tostring(err) })
			end
		end
		-- No window ops/headless UI here; just surface warnings in quickfix if interactive
		if UI.have_warn and not is_headless() then
			UI.update_quickfix()
			UI.open()
			vim.cmd("copen")
		end
		return
	end

	-- Async chain (interactive): keep UI responsive; plugins can UI.ensure_open() when they do real work
	local i = 1
	local function step()
		if i > #items then
			if UI.have_warn then
				UI.update_quickfix()
				UI.open()
				vim.cmd("copen")
			else
				-- only notify if nothing emitted UI entries
				vim.notify("Bootstrap complete ✓", vim.log.levels.INFO)
			end
			return
		end
		local id = items[i]
		i = i + 1
		vim.schedule(function()
			run_one(id, { sync = false })
			vim.defer_fn(step, 30)
		end)
	end

	vim.notify(("Running %d bootstrap hooks…"):format(#items), vim.log.levels.INFO)
	step()
end

-- optional: a user command that auto-detects headless and forwards "sync"
vim.api.nvim_create_user_command("BootstrapAll", function(cmdopts)
	local arg = (cmdopts.args or ""):lower()
	local force_sync = (arg == "sync")
	M.run({ sync = force_sync }) -- if not forced, headless will still auto-sync
end, {
	nargs = "?",
	complete = function()
		return { "sync" }
	end,
})

return M
