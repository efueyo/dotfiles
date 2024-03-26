local group = vim.api.nvim_create_augroup("file_types", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.es6",
	command = "setf javascript",
	group = group,
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.tsx",
	command = "setf typescriptreact",
	group = group,
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "*.md", "*.mdx" },
	command = "setf markdown",
	group = group,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "yaml",
	command = "setlocal shiftwidth=2 tabstop=2",
	group = group,
})
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = "%s/\\s\\+$//e",
	desc = "Clean whitespaces at the end of the lines",
	group = group,
})
require("user.options")
-- make sure to load keymaps before the plugins (lazy) so leader is set before lazy
require("user.keymaps")
require("user.lazy")
require("user.colorscheme")
require("user.globals")
require("user.telescope")
require("user.lsp")
require("user.go")
