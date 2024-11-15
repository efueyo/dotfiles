return {
  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {

      "nvimtools/none-ls.nvim",

      -- Additional lua configuration, makes nvim stuff amazing
      "folke/neodev.nvim",
    },
  },
}
