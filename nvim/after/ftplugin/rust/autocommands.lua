local group = vim.api.nvim_create_augroup("rust_files", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.rs",
	callback = function()
		vim.lsp.buf.format()
	end,
	group = group,
})
