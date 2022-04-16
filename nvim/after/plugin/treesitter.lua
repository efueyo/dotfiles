require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = false,
    disable = {},
  },
  ensure_installed = {
    "go",
    "dockerfile",
    "python",
    "tsx",
    "json",
    "yaml"
  },
}

