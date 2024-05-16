local keymap = vim.keymap.set
--Remap space as leader key
keymap("", "<Space>", "<Nop>")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- navigation between windows
keymap("n", "<leader>j", "<C-w>j")
keymap("n", "<leader>k", "<C-w>k")
keymap("n", "<leader>l", "<C-w>l")
keymap("n", "<leader>h", "<C-w>h")

-- move lines up and down
keymap("n", "-", ":m .+1<cr>==")
keymap("n", "_", ":m .-2<cr>==")

-- delete without yank
keymap("n", "<leader>d", '"_d')
keymap("n", "<leader>D", '"_D')
keymap("n", "x", '"_x')
keymap("x", "<leader>p", '"_dP')

-- yank from cursor
keymap("n", "Y", "yg$")

-- yank from cursor
keymap("n", "<leader>yl", 'f/"+yiW', { desc = "[Y]ank [L]ink" })

-- keep the screen centered while searching
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")
keymap("n", "J", "mzJ`z")

-- smooth movements
keymap("n", "<c-d>", "10j")
keymap("n", "<c-u>", "10k")
keymap("v", "<c-d>", "10j")
keymap("v", "<c-u>", "10k")

-- clear search highligh
keymap("n", "<leader>'", ":noh<CR>")
-- Quicker save
keymap("n", "<leader>w", ":up<CR>") -- use update instead of write to avoid extra writing if buffer hasnt been changed
keymap("n", "<leader>ww", ":wa<CR>")

keymap("n", "ñ", "~")

-- Insert --
-- delete a single line when in insert mode
keymap("i", "<c-d>", "<esc>ddi")
keymap("i", "jk", "<ESC>")

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- move lines up and down
keymap("v", "-", ":m '>+1<CR>gv=gv")
keymap("v", "_", ":m '<-2<CR>gv=gv")
