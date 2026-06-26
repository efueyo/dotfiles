-- nvim-treesitter `main` branch setup (Neovim 0.12+).

local ok, ts = pcall(require, "nvim-treesitter")
if not ok then
  return
end

ts.setup({})

-- Parsers to keep installed. On `main` there is no `ensure_installed`; we ask
-- for them explicitly. This is async and a no-op for parsers already present.
ts.install({
  "go",
  "gomod",
  "gosum",
  "dockerfile",
  "python",
  "requirements",
  "tsx",
  "graphql",
  "json",
  "yaml",
  "query",
  "sql",
  "make",
  "css",
  "bash",
  "toml",
  "gitignore",
  "csv",
  "fish",
  "proto",
})

-- Enable treesitter highlighting for any buffer whose filetype has a parser.
-- `vim.treesitter.start` resolves the language from the filetype; the pcall
-- keeps filetypes without an installed parser from raising.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_treesitter_highlight", { clear = true }),
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Textobjects (`main` branch): `setup` plus manual select keymaps.
local has_textobjects, textobjects = pcall(require, "nvim-treesitter-textobjects")
if has_textobjects then
  textobjects.setup({
    select = {
      lookahead = true,
    },
  })

  local select = require("nvim-treesitter-textobjects.select").select_textobject
  vim.keymap.set({ "x", "o" }, "af", function()
    select("@function.outer", "textobjects")
  end, { desc = "Select outer function" })
  vim.keymap.set({ "x", "o" }, "if", function()
    select("@function.inner", "textobjects")
  end, { desc = "Select inner function" })
end
