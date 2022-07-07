local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

local formatting = null_ls.builtins.formatting

local lsp_formatting = function(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
  })
end
local augroup = vim.api.nvim_create_augroup("LspFormatting", {clear = true})
null_ls.setup({
	debug = false,
	sources = {
    formatting.prettier.with({
      extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "css",
        "scss",
        "less",
        "html",
        "jsonc",
        "markdown",
        "graphql",
        "handlebars",
      }
    }),
	},
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        -- on 0.8, you should use vim.lsp.buf.format instead
        callback = function()
          lsp_formatting(bufnr)
        end,
      })
    end
  end,
})

