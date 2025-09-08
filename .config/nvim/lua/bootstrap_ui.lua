local M = { entries = {}, have_warn = false, _opened = false }

function M.ensure_open()
	if M._opened then
		return
	end
	M._opened = true
	M.open()
end

local function lvl_name(lvl)
	local map = {
		[vim.log.levels.INFO] = "INFO",
		[vim.log.levels.WARN] = "WARN",
		[vim.log.levels.ERROR] = "ERROR",
	}
	return map[lvl] or "INFO"
end

-- NEW: split any multi-line strings into individual lines
local function normalize_lines(lines)
	if type(lines) == "string" then
		lines = { lines }
	end
	local out = {}
	for _, s in ipairs(lines or {}) do
		s = type(s) == "string" and s or vim.inspect(s)
		for _, piece in ipairs(vim.split(s, "\n", { plain = true })) do
			table.insert(out, piece)
		end
	end
	return out
end

function M.add(title, level, lines)
	local lvl = level or vim.log.levels.INFO
	local flat = normalize_lines(lines)
	table.insert(M.entries, { title = title, level = lvl, lines = flat })
	if lvl == vim.log.levels.WARN or lvl == vim.log.levels.ERROR then
		M.have_warn = true
	end
end

-- Open / refresh a scratch buffer with the full report
function M.open()
	if #M.entries == 0 then
		vim.notify("Bootstrap report: nothing to show", vim.log.levels.INFO)
		return
	end
	local buf = vim.api.nvim_create_buf(false, true)
	local out = { "# Bootstrap Report", "" }
	for _, e in ipairs(M.entries) do
		table.insert(out, ("## [%s] %s"):format(lvl_name(e.level), e.title))
		for _, l in ipairs(e.lines) do
			table.insert(out, "  " .. l)
		end
		table.insert(out, "")
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"
	vim.cmd("vsplit")
	vim.api.nvim_win_set_buf(0, buf)
end

-- Push WARN/ERR items into quickfix so they're visible and :copen shows them
function M.update_quickfix()
	local items = {}
	for _, e in ipairs(M.entries) do
		if e.level ~= vim.log.levels.INFO then
			for _, l in ipairs(e.lines) do
				table.insert(items, {
					filename = e.title,
					lnum = 1,
					col = 1,
					text = l,
					type = (e.level == vim.log.levels.ERROR) and "E" or "W",
				})
			end
		end
	end
	if #items > 0 then
		vim.fn.setqflist({}, " ", { title = "Bootstrap Issues", items = items })
	end
end

return M
