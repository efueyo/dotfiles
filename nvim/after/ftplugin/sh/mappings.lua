local keymap = vim.keymap.set
-- execute and print the output of the current line
-- yank the current line, add two lines below, paste the yanked line in between the lines, execute the line in bash
keymap("n", "<leader>xp", "yy2o<ESC>kpV:!/bin/bash<CR>", { desc = "e[X]ecute and [P]rint", buffer = 0 })
keymap(
	"v",
	"<leader>xp",
	"y'<P'<O<ESC>'>o<ESC>:<C-u>'<,'>!/bin/bash<CR>",
	{ desc = "e[X]ecute and [P]rint", buffer = 0 }
)
