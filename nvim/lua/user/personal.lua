-- Here I have some specifics that are less standard and less likely to be used by others.

local keymap = vim.keymap.set

-- my TODO file
local todo_group = vim.api.nvim_create_augroup("TODO-au", { clear = true })
local function open_todo_win()
  local todo = vim.fn.expand("~/notes/TODO.md")
  local bufn = vim.fn.bufnr(todo, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local win_id = vim.api.nvim_open_win(bufn, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "My TODO list",
    title_pos = "center",
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    callback = function()
      if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
      end
      return true
    end,
    buffer = bufn,
    group = todo_group,
  })
end

keymap("n", "<leader>et", open_todo_win)
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
      syntax match TodoL /^- L / contained
      syntax match TodoP /^- P / contained
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
