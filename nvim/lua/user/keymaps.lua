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

-- yank from cursor
keymap("n", "Y", "yg$")

-- keep the screen centered while searching
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")
keymap("n", "J", "mzJ`z")

-- clear search highligh
keymap("n", "<leader>'", ":noh<CR>")
-- Quicker save
keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>ww", ":wa<CR>")

keymap("n", "<leader>et", ":e ~/notes/TODO.md<CR>")

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

