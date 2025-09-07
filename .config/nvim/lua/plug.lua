local Plug = vim.fn["plug#"]
vim.call("plug#begin")

-- Core deps
Plug("nvim-lua/plenary.nvim")
Plug("nvim-tree/nvim-web-devicons")
Plug("nvim-lua/plenary.nvim")
Plug("MunifTanjim/nui.nvim")

-- UI/UX
Plug("nvim-lualine/lualine.nvim")
Plug("rcarriga/nvim-notify")

-- Editing / analysis
Plug("dense-analysis/ale")
Plug("nvim-treesitter/nvim-treesitter", { ["do"] = ":TSUpdate" })
Plug("Vigemus/iron.nvim")
Plug("lukas-reineke/indent-blankline.nvim")
Plug("HiPhish/rainbow-delimiters.nvim")
Plug("windwp/nvim-autopairs")
Plug("numToStr/Comment.nvim")
Plug("nvim-treesitter/nvim-treesitter-context")
Plug("kylechui/nvim-surround")
Plug("stevearc/conform.nvim")

-- Completion
Plug("neoclide/coc.nvim", { ["branch"] = "master", ["do"] = "npm ci" })

-- Git / pickers
Plug("nvim-telescope/telescope.nvim", { ["tag"] = "0.1.8" })
Plug(
	"nvim-telescope/telescope-fzf-native.nvim",
	{ ["do"] = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release" }
)
Plug("folke/which-key.nvim")

-- IDE panel
Plug("nvim-neo-tree/neo-tree.nvim", { ["branch"] = "v3.x" })
Plug("akinsho/toggleterm.nvim", { ["tag"] = "*" })
Plug("akinsho/bufferline.nvim", { ["tag"] = "*" })

vim.call("plug#end")
