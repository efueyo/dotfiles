local group = vim.api.nvim_create_augroup("python_files", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.py",
  -- this should be FileType and pattern="python" but it doesn't work and
  -- someone must be overriding shiftwidth
  command = "setlocal noexpandtab shiftwidth=4 tabstop=4",
  group = group,
})
