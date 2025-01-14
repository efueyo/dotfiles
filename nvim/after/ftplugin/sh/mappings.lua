local keymap = vim.keymap.set
-- execute and print the output of the current line
-- yank the current line, add two lines below, paste the yanked line in between the lines, execute the line in bash
keymap("n", "<leader>x", "yy2o<ESC>kpV:!/bin/bash<CR>", { desc = "Execute the current line", buffer = 0 })
keymap(
	"v",
	"<leader>x",
	"y'<P'<O<ESC>'>o<ESC>:<C-u>'<,'>!/bin/bash<CR>",
	{ desc = "Execute the current selection", buffer = 0 }
)
