-- Here I have some specifics that are less standard and less likely to be used by others.

local keymap = vim.keymap.set

local function setup_todo_highlights()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Extract, sort, and assign colors to tags
  local unique_tags = {}
  for _, line in ipairs(lines) do
    for tag_capture in string.gmatch(line, "#([%w%-]+)") do
      local lower_tag = string.lower(tag_capture)
      if unique_tags[lower_tag] == nil then
        unique_tags[lower_tag] = true
      end
    end
  end
  local tags = {}
  for tag in pairs(unique_tags) do
    table.insert(tags, tag)
  end
  table.sort(tags, function(a, b)
    return string.lower(a) < string.lower(b)
  end)


  local colors = { "#FF8F30", "#B966E8", "#9AFF32", "#FF5B37", "#FFB337", "#F0FF30" }
  local tag_colors = {}
  for i, tag in ipairs(tags) do
    tag_colors[tag] = colors[(i - 1) % #colors + 1]
  end

  local syntax_match_cmds = {}
  local dynamic_hl_group_names = {}
  for _, tag in ipairs(tags) do
    local color = tag_colors[tag]
    -- Normalize tag for highlight group name: remove non-alphanumeric, prepend "TodoTag_"
    local normalized_tag_name = string.gsub(tag, "[^%w]", "")
    local hl_group_name = "TodoTag_" .. normalized_tag_name

    table.insert(dynamic_hl_group_names, hl_group_name)
    vim.api.nvim_set_hl(0, hl_group_name, { fg = color })

    -- Escape tag for use in regex pattern
    -- \V for very nomagic, \c for case-insensitive
    -- local match_cmd = string.format("syntax match %s /\\V#%s\\c/ contained", hl_group_name, tag)
    local match_cmd = string.format("syntax match %s /#%s\\c/ contained", hl_group_name, tag)
    table.insert(syntax_match_cmds, match_cmd)
  end

  -- Define highlight groups for static TODO list markers
  vim.api.nvim_set_hl(0, "TodoL", { fg = "#3b82f6" })
  vim.api.nvim_set_hl(0, "TodoP", { fg = "#22c55e" })

  -- Dynamically build and apply syntax commands
  local all_syntax_cmds = {
    "syntax match TodoL /^- L / contained",
    "syntax match TodoP /^- P / contained",
  }

  for _, cmd in ipairs(syntax_match_cmds) do
    table.insert(all_syntax_cmds, cmd)
  end

  local todo_markers_contains = "TodoL,TodoP"
  if #dynamic_hl_group_names > 0 then
    todo_markers_contains = todo_markers_contains .. "," .. table.concat(dynamic_hl_group_names, ",")
  end
  table.insert(all_syntax_cmds, string.format("syntax cluster TodoMarkers contains=%s", todo_markers_contains))

  table.insert(all_syntax_cmds, "syntax region TodoItem start=/^-/ end=/$/ contains=@TodoMarkers")

  vim.cmd(table.concat(all_syntax_cmds, "\n"))
end

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
vim.api.nvim_create_autocmd({ "BufLeave" }, {
  pattern = "TODO.md",
  -- Write the content
  callback = function()
    vim.cmd("silent! write")
  end,
  group = todo_group,
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "TODO.md",
  callback = function()
    setup_todo_highlights()
    keymap("n", "<leader>ci", "jm`kddGp'`zz", { desc = "[C]omplete [I]tem", buffer = 0 })
    -- <C-u> is used to clear the range when : is pressed in visual mode
    keymap("v", "<leader>ci", ":<C-u>'<,'>d<CR>m`Gp'`zz", { desc = "[C]omplete [I]tem", buffer = 0 })
    keymap(
      "n",
      "<leader>ab",
      "I- L Review Notion<CR>- L Review Linear<CR>- L Review PRs<CR><ESC>",
      { desc = "[A]dd [B]asic items", buffer = 0 }
    )
    keymap("n", "<leader>al", "o- L ", { desc = "[A]dd [L] item", buffer = 0 })
    keymap("n", "<leader>ap", "o- P ", { desc = "[A]dd [P] item", buffer = 0 })
  end,
  group = todo_group,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "TODO.md", ".envrc" },
  command = "let b:copilot_enabled = v:false",
  group = todo_group,
})
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "TODO.md",
  group = todo_group,
  callback = setup_todo_highlights,
})
