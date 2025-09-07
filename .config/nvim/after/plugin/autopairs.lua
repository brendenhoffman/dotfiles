local ok, npairs = pcall(require, "nvim-autopairs")
if not ok then
	return
end

npairs.setup({
	check_ts = true,
	fast_wrap = {
		map = "<M-e>",
		chars = { "{", "[", "(", '"', "'" },
		end_key = "$",
	},
})

-- If Enter behaves weirdly with CoC, disable mapping:
-- npairs.setup({ map_cr = false })
