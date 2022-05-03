local go_to_alternate = function (file_pattern, test_file_pattern, cmd)
  local file = vim.fn.expand('%')
  local alt_file = ""
  if #file <= 1 then
    vim.notify("no buffer name", vim.lsp.log_levels.ERROR)
    return
  end
  local is_test_file = string.sub(file, -#test_file_pattern) == test_file_pattern
  local is_testable_file = string.sub(file, -#file_pattern) == file_pattern
  if is_test_file then
    alt_file = string.gsub(file, test_file_pattern, file_pattern)
  elseif is_testable_file then
    alt_file = vim.fn.expand('%:r') .. test_file_pattern
  else
    vim.notify('not a valid file', vim.lsp.log_levels.ERROR)
  end
  if not vim.fn.filereadable(alt_file) and not vim.fn.bufexists(alt_file) then
    vim.notify("couldn't find " .. alt_file, vim.lsp.log_levels.ERROR)
    return
  elseif cmd == nil or #cmd <=1 then
    local ocmd = "e " .. alt_file
    vim.cmd(ocmd)
  else
    local ocmd = cmd .. " " .. alt_file
    vim.cmd(ocmd)
  end
end


return go_to_alternate

