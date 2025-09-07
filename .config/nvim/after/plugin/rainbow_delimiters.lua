local ok, rd = pcall(require, "rainbow-delimiters")
if not ok then
	return
end

vim.g.rainbow_delimiters = {
	strategy = { [""] = rd.strategy["global"], vim = rd.strategy["local"] },
	query = { [""] = "rainbow-delimiters", lua = "rainbow-blocks" },
	priority = { [""] = 110, lua = 210 },
	highlight = {
		"RainbowDelimiterRed",
		"RainbowDelimiterYellow",
		"RainbowDelimiterBlue",
		"RainbowDelimiterOrange",
		"RainbowDelimiterGreen",
		"RainbowDelimiterViolet",
		"RainbowDelimiterCyan",
	},
}
