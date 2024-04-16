-- Here I have some specifics that are less standard and less likely to be used by others.

local keymap = vim.keymap.set

-- my TODO file
keymap("n", "<leader>et", ":e ~/notes/TODO.md<CR>")
local todo_group = vim.api.nvim_create_augroup("TODO-au", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "TODO.md",
	callback = function()
		keymap("n", "<leader>ci", "jm`kddGp'`", { desc = "[C]omplete [I]tem", buffer = 0 })
	end,
	group = todo_group,
})
