-- Here I have some specifics that are less standard and less likely to be used by others.

local keymap = vim.keymap.set

-- my TODO file
keymap("n", "<leader>et", ":e ~/notes/TODO.md<CR>")
local todo_group = vim.api.nvim_create_augroup("TODO-au", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "TODO.md",
	callback = function()
		keymap("n", "<leader>ci", "jm`kddGp'`zz", { desc = "[C]omplete [I]tem", buffer = 0 })
		-- <C-u> is used to clear the range when : is pressed in visual mode
		keymap("v", "<leader>ci", ":<C-u>'<,'>d<CR>m`Gp'`zz", { desc = "[C]omplete [I]tem", buffer = 0 })
		keymap(
			"n",
			"<leader>ab",
			"I- L Review Notion<CR>- L Review Linear<CR>- L Review PRs<CR><ESC>",
			{ desc = "[A]dd [B]asic items", buffer = 0 }
		)
		-- Define highlight groups for TODO list markers
		vim.api.nvim_set_hl(0, "TodoL", { fg = "#3b82f6" })
		vim.api.nvim_set_hl(0, "TodoP", { fg = "#22c55e" })

		-- Create syntax matching for the markers
		vim.cmd([[
			syntax match TodoL /^- L/ contained
			syntax match TodoP /^- P/ contained
			syntax cluster TodoMarkers contains=TodoL,TodoP
			syntax region TodoItem start=/^-/ end=/$/ contains=@TodoMarkers
		]])
	end,
	group = todo_group,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "TODO.md", ".envrc" },
	command = "let b:copilot_enabled = v:false",
	group = todo_group,
})
