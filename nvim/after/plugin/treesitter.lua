require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
    disable = {},
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<leader>ss",
      node_incremental = "<leader>si",
      scope_incremental = "<leader>sc",
      node_decremental = "<leader>sd",
    },
  },
  textobjects = {
    enable = true,
    keymaps = {
      ["af"] = "@function.outer",
      ["if"] = "@function.inner",
    },
    select = {
      enable = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
      },
    },
  },
  indent = {
    enable = false,
    disable = {},
  },
  ensure_installed = {
    "go",
    "gosum",
    "gomod",
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
  },
  playground = {
    enable = true,
  },
  query_linter = {
    enable = true,
    use_virtual_text = true,
    lint_events = { "BufWrite", "CursorHold" },
  },
})
