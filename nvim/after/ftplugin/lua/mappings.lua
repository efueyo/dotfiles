local keymap = vim.keymap.set

-- from https://github.com/tjdevries/config.nvim/blob/37c9356fd40a8d3589638c8d16a6a6b1274c40ca/plugin/keymaps.lua
keymap("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
keymap("v", "<leader>x", ":lua<CR>", { desc = "Execute the selection line" })
keymap("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })
