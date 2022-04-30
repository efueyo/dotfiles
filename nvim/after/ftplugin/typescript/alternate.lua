local go_to_alternate = function ()
  local file = vim.fn.expand('%')
  local alt_file = ""
  if #file <= 1 then
    vim.notify("no buffer name", vim.lsp.log_levels.ERROR)
    return
  end
  local s = string.find(file, "%.test%.ts$")
  local s2 = string.find(file, "%.ts$")
  if s ~= nil then
    alt_file = string.gsub(file, ".test.ts", ".ts")
  elseif s2 ~= nil then
    alt_file = vim.fn.expand('%:r') .. ".test.ts"
  else
    vim.notify('not a ts file', vim.lsp.log_levels.ERROR)
  end
  if not vim.fn.filereadable(alt_file) and not vim.fn.bufexists(alt_file) then
    vim.notify("couldn't find " .. alt_file, vim.lsp.log_levels.ERROR)
    return
  else
    local ocmd = "e " .. alt_file
    vim.cmd(ocmd)
  end
end

vim.keymap.set("n", "<leader>ga", go_to_alternate)

