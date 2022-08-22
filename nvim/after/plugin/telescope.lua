local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local builtin = require('telescope.builtin')
local themes = require('telescope.themes')
local user_telescope = require('user.telescope')
vim.keymap.set("n", "<leader>ff", builtin.find_files)
vim.keymap.set("n", "<leader>fg", builtin.git_files)
vim.keymap.set("n", "<leader>fs", builtin.live_grep)
vim.keymap.set("n", "<leader>fb", user_telescope.buffers)
vim.keymap.set("n", "<leader>fh", builtin.help_tags)
vim.keymap.set("n", "<leader>fr", function () return builtin.lsp_references(themes.get_dropdown({ layout_config = { width = 0.8 } })) end)
vim.keymap.set("n", "<leader>fi", function () return builtin.lsp_implementations(themes.get_dropdown({ layout_config = { width = 0.8 } })) end)
vim.keymap.set("n", "<leader>fts", builtin.treesitter)
vim.keymap.set("n", "<leader>gc", user_telescope.git_branches)

