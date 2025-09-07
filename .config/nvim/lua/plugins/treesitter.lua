local M = {}

-- Only bootstrap logic here (your runtime config stays in after/plugin/treesitter.lua)
function M.bootstrap()
	-- Ensure parsers are present/updated for the langs list
	pcall(vim.cmd, "TSUpdate")
end

return M
