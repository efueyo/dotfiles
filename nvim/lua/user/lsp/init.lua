local lsp_keymaps = function(bufnr)
  local nmap = function(keys, func, desc)
    if desc then
      desc = "LSP: " .. desc
    end

    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end
  local builtin = require("telescope.builtin")
  local themes = require("telescope.themes")

  nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  nmap("gr", function()
    return builtin.lsp_references(themes.get_dropdown({ layout_config = { width = 0.9 } }))
  end, "[G]oto [R]eferences")
  nmap("gI", function()
    return builtin.lsp_implementations(themes.get_dropdown({ layout_config = { width = 0.9 } }))
  end, "[G]oto [I]mplementation")
  nmap("<C-n>", function()
    vim.diagnostic.goto_next({ border = "rounded" })
  end, "Go to [N]ext")
  nmap("<C-p>", function()
    vim.diagnostic.goto_prev({ border = "rounded" })
  end, "Go to [P]rev")
  nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")

  -- See `:help K` for why this keymap
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  -- dont use c-k, overrides TmuxNavigate
  -- nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
end

local on_attach = function(_, bufnr)
  lsp_keymaps(bufnr)

  vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })
  if vim.bo.filetype ~= "go" then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format()
      end,
    })
  end
end

local signs = {
  { name = "DiagnosticSignError", text = "" },
  { name = "DiagnosticSignWarn", text = "" },
  { name = "DiagnosticSignHint", text = "" },
  { name = "DiagnosticSignInfo", text = "" },
}

for _, sign in ipairs(signs) do
  vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
end

local config = {
  -- show signs
  signs = {
    active = signs,
  },
  update_in_insert = true,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

vim.diagnostic.config(config)

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded",
})

local servers = {
  gopls = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
      buildFlags = { "-tags=wireinject" },
    },
  },
  ruff = {},
  rust_analyzer = {},
  tsserver = {},
  terraformls = {},

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

-- Setup neovim lua configuration
require("neodev").setup()
--
-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)


for server, config in pairs(servers) do
  require("lspconfig")[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    settings = config,
  })
end

require("user.lsp.null-ls")
