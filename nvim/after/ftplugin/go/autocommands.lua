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

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "wire.go",
  callback = function ()
    local log_data = function (data, level)
      if data then
        for _, m in ipairs(data) do
          if #m > 0 then
            vim.api.nvim_notify(m, level, {})
          end
        end
      end
    end
    log_data({ "wire output:" }, vim.log.levels.INFO)
    local cmd = "wire " .. vim.fn.expand("<amatch>:h")
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function (_, data) log_data(data, vim.log.levels.INFO) end,
      on_stderr = function (_, data) log_data(data, vim.log.levels.ERROR) end,
      on_exit = function () log_data({"wire done", "#######"}, vim.log.levels.INFO) end,
    })
  end,
  group = group,
})
