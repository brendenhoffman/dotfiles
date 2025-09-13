-- after/plugin/spots.lua — persistent, fuzzy-searchable “spots”
local ns = vim.api.nvim_create_namespace("spots")
local ns_preview = vim.api.nvim_create_namespace("spots_preview")
local spots = {} -- in-memory: { {buf, id, file, label} ... }

-- ========= persistence =========
local store_path = vim.fn.stdpath("data") .. "/spots.json"
local function Jenc(x)
	return (vim.json and vim.json.encode or vim.fn.json_encode)(x)
end
local function Jdec(s)
	return (vim.json and vim.json.decode or vim.fn.json_decode)(s)
end

local function load_store()
	local ok, lines = pcall(vim.fn.readfile, store_path)
	if not ok or #lines == 0 then
		return {}
	end
	local ok2, obj = pcall(Jdec, table.concat(lines, "\n"))
	return (ok2 and type(obj) == "table") and obj or {}
end

local function save_store(tbl)
	local ok, raw = pcall(Jenc, tbl)
	if not ok then
		return
	end
	vim.fn.mkdir(vim.fn.fnamemodify(store_path, ":h"), "p")
	vim.fn.writefile(vim.split(raw, "\n"), store_path)
end

-- snapshot current extmarks -> store; replace per-file arrays (no label merging)
local function persist_now()
	-- aggregate by file
	local agg = {} -- { [file] = { {lnum=, label=} ... } }
	for i = #spots, 1, -1 do
		local sp = spots[i]
		local pos = vim.api.nvim_buf_get_extmark_by_id(sp.buf, ns, sp.id, {})
		if pos and #pos == 2 then
			local lnum = pos[1] + 1
			agg[sp.file] = agg[sp.file] or {}
			table.insert(agg[sp.file], { lnum = lnum, label = sp.label or "" })
		else
			-- extmark is gone; drop from memory
			table.remove(spots, i)
		end
	end
	-- merge with existing store but replace files we have snapshots for
	local base = load_store()
	for file, arr in pairs(agg) do
		table.sort(arr, function(a, b)
			return a.lnum < b.lnum
		end)
		base[file] = arr
	end
	save_store(base)
end

local function restore_for_buffer(buf)
	local file = vim.api.nvim_buf_get_name(buf)
	if file == "" then
		return
	end
	local recs = load_store()[file]
	if not recs then
		return
	end
	for _, rec in ipairs(recs) do
		local total = vim.api.nvim_buf_line_count(buf)
		local lnum = math.max(1, math.min(rec.lnum or 1, total))
		local id = vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, { right_gravity = false })
		table.insert(spots, { buf = buf, id = id, file = file, label = rec.label or "" })
	end
end

vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(a)
		restore_for_buffer(a.buf)
	end,
})
vim.api.nvim_create_autocmd({ "BufWritePost", "BufUnload", "VimLeavePre" }, {
	callback = function()
		pcall(persist_now)
	end,
})

-- ========= helpers =========
local function curpos()
	local buf = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	return buf, row, 0
end

local function line_preview(buf, row)
	local ok, l = pcall(vim.api.nvim_buf_get_lines, buf, row, row + 1, false)
	local s = (ok and l[1]) and l[1] or ""
	s = s:gsub("^%s*", ""):gsub("%s*$", "")
	return (#s > 120) and (s:sub(1, 117) .. "…") or s
end

local function spot_at_line(buf, row)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, {})
	if #marks > 0 then
		local id = marks[1][1]
		for i, sp in ipairs(spots) do
			if sp.buf == buf and sp.id == id then
				return i, sp
			end
		end
	end
end

-- ========= API =========
local function add_spot(label)
	local buf, row, col = curpos()
	local file = vim.api.nvim_buf_get_name(buf)
	if file == "" then
		vim.notify("Save the buffer first.", vim.log.levels.WARN)
		return
	end
	local id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, { right_gravity = false })
	table.insert(spots, { buf = buf, id = id, file = file, label = label or "" })
	vim.notify("Spot added" .. (label and (": " .. label) or ""), vim.log.levels.INFO)
	persist_now()
end

local function toggle_spot()
	local buf, row = curpos()
	local idx, sp = spot_at_line(buf, row)
	if idx then
		pcall(vim.api.nvim_buf_del_extmark, buf, ns, sp.id)
		table.remove(spots, idx)
		vim.notify("Spot removed", vim.log.levels.INFO)
		persist_now()
	else
		add_spot()
	end
end

local function add_spot_prompt()
	vim.cmd("redraw")
	vim.fn.inputsave()
	local input = vim.fn.input("Spot label (optional): ")
	vim.fn.inputrestore()
	if input == nil then
		return
	end
	add_spot(input)
end

local function collect_entries()
	local entries, keep = {}, {}
	for _, sp in ipairs(spots) do
		local pos = vim.api.nvim_buf_get_extmark_by_id(sp.buf, ns, sp.id, {})
		if pos and #pos == 2 then
			local row = pos[1]
			table.insert(entries, {
				file = sp.file,
				bufnr = sp.buf,
				lnum = row + 1,
				col = 1,
				label = sp.label or "",
				preview = line_preview(sp.buf, row),
				id = sp.id,
			})
			keep[sp.id] = true
		end
	end
	if #keep ~= #spots then
		local new = {}
		for _, sp in ipairs(spots) do
			if keep[sp.id] then
				table.insert(new, sp)
			end
		end
		spots = new
	end
	return entries
end

local function pick_spot()
	local entries = collect_entries()
	if #entries == 0 then
		vim.notify("No spots yet. Press 'mm' to add one.", vim.log.levels.INFO)
		return
	end

	local ok, telescope = pcall(require, "telescope")
	if not ok then
		-- fallback simple list
		local items = {}
		for i, e in ipairs(entries) do
			items[i] = string.format(
				"%s:%d  %s  | %s",
				vim.fn.fnamemodify(e.file, ":t"),
				e.lnum,
				(e.label ~= "" and ("[" .. e.label .. "]") or ""),
				e.preview
			)
		end
		local sel = vim.fn.inputlist(vim.list_extend({ "Pick a spot:" }, items))
		local e = entries[sel]
		if e then
			vim.cmd("edit " .. vim.fn.fnameescape(e.file))
			vim.api.nvim_win_set_cursor(0, { e.lnum, 0 })
			vim.cmd("normal! zz")
		end
		return
	end

	local pickers, finders, conf =
		require("telescope.pickers"), require("telescope.finders"), require("telescope.config").values
	local actions, action_state = require("telescope.actions"), require("telescope.actions.state")
	local previewers = require("telescope.previewers")
	local entry_display = require("telescope.pickers.entry_display")
	local displayer = entry_display.create({
		separator = " │ ",
		items = {
			{ width = 28 }, -- filename
			{ width = 5 }, -- line
			{ width = 18 }, -- [label]
			{ remaining = true }, -- snippet
		},
	})

	local function delete_current(pb)
		local e = action_state.get_selected_entry().value
		actions.close(pb)
		local b = vim.fn.bufnr(e.file)
		if b == -1 then
			b = vim.fn.bufadd(e.file)
			vim.fn.bufload(b)
		end
		pcall(vim.api.nvim_buf_del_extmark, b, ns, e.id)
		for i, sp in ipairs(spots) do
			if sp.id == e.id and sp.buf == b then
				table.remove(spots, i)
				break
			end
		end
		persist_now()
		vim.schedule(function()
			pick_spot()
		end)
	end

	pickers
		.new({}, {
			prompt_title = "Spots",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(e)
					-- pick one:
					local name = vim.fn.fnamemodify(e.file, ":t") -- filename only
					-- local name = vim.fn.fnamemodify(e.file, ":.") -- relative path

					local label = (e.label ~= "" and ("[" .. e.label .. "] ")) or ""
					local disp = string.format("%s:%d %s%s", name, e.lnum, label, e.preview)

					return {
						value = e,
						display = disp, -- <- plain string, no column padding
						ordinal = table.concat({ e.label, name, tostring(e.lnum), e.preview }, " "),
						filename = e.file,
						lnum = e.lnum,
					}
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry)
					local e = entry.value
					local src = e.bufnr
					local CENTER = e.lnum - 1
					local START, FINISH, lines, ft

					if src and vim.api.nvim_buf_is_loaded(src) then
						ft = vim.bo[src].filetype
						local total = vim.api.nvim_buf_line_count(src)
						START = math.max(0, CENTER - 5)
						FINISH = math.min(total, CENTER + 6)
						lines = vim.api.nvim_buf_get_lines(src, START, FINISH, false)
					else
						local all = vim.fn.readfile(e.file)
						ft = vim.filetype.match({ filename = e.file })
						local total = #all
						START = math.max(0, e.lnum - 1 - 5)
						FINISH = math.min(total, e.lnum - 1 + 6)
						lines = {}
						for i = START + 1, FINISH do
							lines[#lines + 1] = all[i] or ""
						end
					end

					vim.bo[self.state.bufnr].modifiable = true
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines or { "" })
					vim.bo[self.state.bufnr].modifiable = false
					if ft and ft ~= "" then
						vim.bo[self.state.bufnr].filetype = ft
					end

					pcall(vim.api.nvim_buf_clear_namespace, self.state.bufnr, ns_preview, 0, -1)
					local rel = CENTER - START
					if rel >= 0 then
						pcall(vim.api.nvim_buf_add_highlight, self.state.bufnr, ns_preview, "Visual", rel, 0, -1)
					end
					local total_lines = vim.api.nvim_buf_line_count(self.state.bufnr)
					local lnum = math.max(1, math.min(rel + 1, total_lines))
					pcall(vim.api.nvim_win_set_cursor, self.state.winid, { lnum, 0 })
					pcall(vim.cmd, "normal! zz")
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(pb)
					local e = action_state.get_selected_entry().value
					actions.close(pb)
					vim.cmd("edit " .. vim.fn.fnameescape(e.file))
					vim.api.nvim_win_set_cursor(0, { e.lnum, 0 })
					vim.cmd("normal! zz")
				end)
				map("i", "<C-d>", delete_current)
				return true
			end,
		})
		:find()
end

local function next_spot(dir)
	local list = collect_entries()
	if #list == 0 then
		return
	end
	table.sort(list, function(a, b)
		return (a.file == b.file) and (a.lnum < b.lnum) or (a.file < b.file)
	end)
	local curfile = vim.api.nvim_buf_get_name(0)
	local curline = vim.api.nvim_win_get_cursor(0)[1]
	local best
	if dir > 0 then
		for _, e in ipairs(list) do
			if e.file > curfile or (e.file == curfile and e.lnum > curline) then
				best = e
				break
			end
		end
		best = best or list[1]
	else
		for i = #list, 1, -1 do
			local e = list[i]
			if e.file < curfile or (e.file == curfile and e.lnum < curline) then
				best = e
				break
			end
		end
		best = best or list[#list]
	end
	vim.cmd("edit " .. vim.fn.fnameescape(best.file))
	vim.api.nvim_win_set_cursor(0, { best.lnum, 0 })
	vim.cmd("normal! zz")
end

-- Commands & keymaps
vim.api.nvim_create_user_command("SpotToggle", toggle_spot, {})
vim.api.nvim_create_user_command("SpotAdd", add_spot_prompt, {})
vim.api.nvim_create_user_command("SpotPick", pick_spot, {})
vim.api.nvim_create_user_command("SpotNext", function()
	next_spot(1)
end, {})
vim.api.nvim_create_user_command("SpotPrev", function()
	next_spot(-1)
end, {})

vim.keymap.set("n", "mm", toggle_spot, { desc = "Toggle spot here" })
vim.keymap.set("n", "]s", function()
	next_spot(1)
end, { desc = "Next spot" })
vim.keymap.set("n", "[s", function()
	next_spot(-1)
end, { desc = "Prev spot" })
vim.keymap.set("n", "<leader>sp", pick_spot, { desc = "Pick a spot (Telescope)" })
vim.keymap.set("n", "<leader>sa", add_spot_prompt, { desc = "Add spot with label" })
