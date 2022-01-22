if !exists('g:lspconfig') | finish | endif

lua << EOF

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

local nvim_lsp = require('lspconfig')
local servers = {'pyright', 'gopls'}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    capabilities = capabilities,
  }
end

--require'nvim-treesitter.configs'.setup {
--  highlight = {
--      enable = true
--  },
--}
EOF
