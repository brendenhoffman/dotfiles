vim.g.mapleader = " "

require("core.env")
require("core.options")
require("plug")
require("core.keys")
require("core.autocmds")
require("core.commands")

vim.api.nvim_create_user_command("BootstrapAll", function()
	require("bootstrap").run()
end, {})

pcall(require, "plugins.tools_check")
pcall(require, "plugins.telescope_fzf")
