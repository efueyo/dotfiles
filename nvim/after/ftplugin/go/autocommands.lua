local group = vim.api.nvim_create_augroup("go_files", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  command = "setlocal noexpandtab shiftwidth=8 tabstop=8",
  group = group,
})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function ()
   require('go.format').goimport()
  end,
  group = group,
})
