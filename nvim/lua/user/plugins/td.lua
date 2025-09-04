local local_path = vim.fn.expand("~/repos/td.nvim")

if vim.fn.isdirectory(local_path) == 1 then
  return {
    dir = local_path,
  }
else
  return {
    "efueyo/td.nvim",
  }
end
