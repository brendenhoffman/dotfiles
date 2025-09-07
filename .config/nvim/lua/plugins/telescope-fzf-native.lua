local M = {}

-- Return first existing path from a list
local function first_existing(paths)
	for _, p in ipairs(paths) do
		if vim.fn.isdirectory(p) == 1 then
			return p
		end
	end
end

-- Try to locate the plugin dir across common managers
local function find_plugin_dir()
	local data = vim.fn.stdpath("data")
	local candidates = {
		-- vim-plug default
		data .. "/plugged/telescope-fzf-native.nvim",
		-- packer/lazy style
		data .. "/site/pack/packer/start/telescope-fzf-native.nvim",
		data .. "/site/pack/packer/opt/telescope-fzf-native.nvim",
		data .. "/site/pack/plugged/telescope-fzf-native.nvim",
		data .. "/lazy/telescope-fzf-native.nvim",
	}

	local dir = first_existing(candidates)
	if dir then
		return dir
	end

	-- Fallback: scan runtimepath for any match
	local matches = vim.fn.globpath(vim.o.runtimepath, "**/telescope-fzf-native.nvim", true, true)
	if #matches > 0 then
		return matches[1]
	end

	return nil
end

local function is_built(dir)
	-- look for any compiled fzf library under build/
	local hits = vim.fn.glob(dir .. "/build/*fzf*.*", true, true)
	return #hits > 0, hits[1]
end

function M.bootstrap()
	local UI = require("bootstrap_ui")
	local dir = find_plugin_dir()
	if not dir then
		UI.add("telescope-fzf-native", vim.log.levels.WARN, { "Plugin directory not found" })
		return
	end

	local built, lib = is_built(dir)
	if built then
		UI.add(
			"telescope-fzf-native",
			vim.log.levels.INFO,
			{ "Compiled ✓ (" .. vim.fn.fnamemodify(lib, ":t") .. ")" }
		)
	else
		-- Show the exact build command you configured in plug.lua as a reminder
		UI.add("telescope-fzf-native", vim.log.levels.WARN, {
			"Installed at: " .. dir,
			"Not compiled — run your build step:",
			"  :PlugUpdate telescope-fzf-native.nvim",
			"  (or) :!cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
		})
	end
end

-- Manual command so you can re-check without :BootstrapAll
vim.api.nvim_create_user_command("CheckFZFBuild", function()
	local UI = require("bootstrap_ui")
	-- clear a header entry so the report shows this run distinctly
	UI.add("telescope-fzf-native (manual check)", vim.log.levels.INFO, {})
	M.bootstrap()
	UI.open()
	UI.update_quickfix()
	vim.cmd("copen")
end, {})

return M
