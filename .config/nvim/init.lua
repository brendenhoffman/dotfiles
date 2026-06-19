vim.g.mapleader = " "

require("core.env")
require("core.options")

vim.pack.add({
	-- Core deps
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/MunifTanjim/nui.nvim",

	-- UI
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/rcarriga/nvim-notify",

	-- Editing / analysis
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/Vigemus/iron.nvim",
	"https://github.com/lukas-reineke/indent-blankline.nvim",
	"https://github.com/HiPhish/rainbow-delimiters.nvim",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/numToStr/Comment.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	"https://github.com/kylechui/nvim-surround",
	"https://github.com/stevearc/conform.nvim",
	{ src = "https://github.com/saecki/crates.nvim", version = "stable" },

	-- Completion (coc disabled)
	-- { src = "https://github.com/neoclide/coc.nvim", version = "release" },

	-- Git / pickers
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	"https://github.com/folke/which-key.nvim",

	-- IDE panel
	{ src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
	"https://github.com/akinsho/toggleterm.nvim",
	"https://github.com/akinsho/bufferline.nvim",
}, { load = true, confirm = false })

require("core.keys")
require("core.autocmds")
require("core.commands")

vim.api.nvim_create_user_command("BootstrapAll", function()
	require("bootstrap").run()
end, {})

pcall(require, "plugins.tools_check")
pcall(require, "plugins.telescope_fzf")
