local ok, conform = pcall(require, "conform")
if not ok then
	return
end

-- toggles (kept)
local buf_off = {}
vim.api.nvim_create_user_command("FormatToggle", function()
	local b = vim.api.nvim_get_current_buf()
	buf_off[b] = not buf_off[b]
	print("Format on save (buffer): " .. (buf_off[b] and "OFF" or "ON"))
end, {})
vim.g.format_global_off = vim.g.format_global_off or false
vim.api.nvim_create_user_command("FormatToggleGlobal", function()
	vim.g.format_global_off = not vim.g.format_global_off
	print("Format on save (global): " .. (vim.g.format_global_off and "OFF" or "ON"))
end, {})

-- build formatters_by_ft from externals (superset) but filter by langs.lua
local langs = (pcall(require, "langs") and require("langs")) or {}
local ext = (pcall(require, "externals") and require("externals")) or { by_lang = {}, mappings = {} }

local want_lang = {}
for _, l in ipairs(langs) do
	want_lang[l] = true
end

local formatters_by_ft = {}

for lang, tools in pairs(ext.by_lang or {}) do
	if want_lang[lang] then
		for _, exe in ipairs(tools) do
			local map = (ext.mappings or {})[exe]
			if map and map.conform then
				local fts = map.filetypes
				if not fts or #fts == 0 then
				else
					for _, ft in ipairs(fts) do
						formatters_by_ft[ft] = formatters_by_ft[ft] or {}
						table.insert(formatters_by_ft[ft], map.conform)
					end
				end
			end
		end
	end
end

-- sensible web defaults if nothing mapped:
local defaults = {
	javascript = { "prettier" },
	typescript = { "prettier" },
	tsx = { "prettier" },
	json = { "prettier" },
	html = { "prettier" },
	css = { "prettier" },
	markdown = { "prettier" },
}
for ft, list in pairs(defaults) do
	if not formatters_by_ft[ft] and (want_lang[ft] or true) then
		formatters_by_ft[ft] = list
	end
end

conform.setup({
	formatters_by_ft = formatters_by_ft,
	format_on_save = function(bufnr)
		if vim.g.format_global_off or buf_off[bufnr] then
			return
		end
		return { lsp_fallback = true, timeout_ms = 1200 }
	end,
})

-- format last paste/change (kept)
vim.keymap.set("n", "<leader>cF", function()
	local s = vim.api.nvim_buf_get_mark(0, "[")
	local e = vim.api.nvim_buf_get_mark(0, "]")
	conform.format({ lsp_fallback = true, range = { start = { s[1], 0 }, ["end"] = { e[1], 0 } }, async = true })
end, { desc = "Format last paste/change" })

vim.api.nvim_create_user_command("ShowConformMap", function()
	print(vim.inspect(formatters_by_ft))
end, {})
