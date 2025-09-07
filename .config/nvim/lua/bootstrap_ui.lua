local M = { entries = {}, have_warn = false }

local function lvl_name(lvl)
	local map = {
		[vim.log.levels.INFO] = "INFO",
		[vim.log.levels.WARN] = "WARN",
		[vim.log.levels.ERROR] = "ERROR",
	}
	return map[lvl] or "INFO"
end

function M.add(title, level, lines)
	if type(lines) == "string" then
		lines = { lines }
	end
	table.insert(M.entries, { title = title, level = level or vim.log.levels.INFO, lines = lines or {} })
	if level == vim.log.levels.WARN or level == vim.log.levels.ERROR then
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

	-- show in a right split
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
