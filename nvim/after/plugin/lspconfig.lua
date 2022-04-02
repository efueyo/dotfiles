local my_lsp = require("user.lsp")

my_lsp.setup()

local servers = {'pyright', 'gopls', 'tsserver'}

for _, lsp in ipairs(servers) do
  require('lspconfig')[lsp].setup {
    on_attach = my_lsp.on_attach,
    capabilities = my_lsp.capabilities,
  }
end
