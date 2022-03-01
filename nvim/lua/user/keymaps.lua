local opts = { noremap = true }
-- Shorten function name

local keymap = vim.api.nvim_set_keymap
--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- navigation between windows
keymap("n", "<leader>j", "<C-w>j", opts)
keymap("n", "<leader>k", "<C-w>k", opts)
keymap("n", "<leader>l", "<C-w>l", opts)
keymap("n", "<leader>h", "<C-w>h", opts)

-- move lines up and down
keymap("n", "-", ":m .+1<cr>==", opts)
keymap("n", "_", ":m .-2<cr>==", opts)

-- delete without yank
keymap("n", "<leader>d", '"_d', opts)
keymap("n", "<leader>D", '"_D', opts)
keymap("n", "x", '"_x', opts)

keymap("n", "Y", "yg$", opts)
-- yank from cursor

-- keep the screen centered while searching
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)
keymap("n", "J", "mzJ`z", opts)

-- Insert --
-- delete a single line when in insert mode
keymap("i", "<c-d>", "<esc>ddi", opts)
keymap("i", "jk", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- move lines up and down
keymap("v", "-", ":m '>+1<CR>gv=gv", opts)
keymap("v", "_", ":m '<-2<CR>gv=gv", opts)

