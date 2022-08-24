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

local wire_output_buf = vim.api.nvim_create_buf(false, true)
-- execute wire on wire.go save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "wire.go",
  callback = function ()
    local buf = wire_output_buf
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "wire output:" })
    local log_data = function (_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      end
    end
    vim.cmd('botright split')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    local cmd = "wire " .. vim.fn.expand("<amatch>:h")
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = log_data,
      on_stderr = log_data,
      on_exit = function ()
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"wire done", "#######"})
      end
    })
  end,
  group = group,
})
