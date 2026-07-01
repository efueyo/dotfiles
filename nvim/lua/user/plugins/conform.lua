-- Formatting is centralized here so that, per repo, we use whatever formatter
-- the project actually configures:
--   * oxfmt   -> only runs when the repo has an .oxfmtrc(.jsonc) at its root
--   * prettier -> fallback for repos that don't use oxfmt
--   * LSP      -> fallback for everything else (lua, python, rust, ...)
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      local conform = require("conform")
      local util = require("conform.util")

      -- oxfmt isn't a conform builtin, so define it. Prefer the repo-local
      -- binary, and only run it when the repo opted into oxfmt (require_cwd).
      conform.formatters.oxfmt = {
        command = util.from_node_modules("oxfmt"),
        args = { "--stdin-filepath", "$FILENAME" },
        stdin = true,
        cwd = util.root_file({ ".oxfmtrc.jsonc", ".oxfmtrc.json", ".oxfmtrc" }),
        require_cwd = true,
      }

      -- For each web filetype, try formatters in order and use the first one
      -- that's available + applicable. oxfmt self-skips (require_cwd) in repos
      -- without an .oxfmtrc, so prettier takes over there.
      local web = { "oxfmt", "prettierd", "prettier", stop_after_first = true }
      local prettier_only = { "prettierd", "prettier", stop_after_first = true }

      -- Filetypes that should be formatted ONLY by oxfmt/prettier, never the LSP.
      local web_filetypes = {
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
        json = true,
        jsonc = true,
        yaml = true,
        css = true,
        scss = true,
        less = true,
        html = true,
        markdown = true,
        graphql = true,
        handlebars = true,
      }

      conform.setup({
        formatters_by_ft = {
          javascript = web,
          javascriptreact = web,
          typescript = web,
          typescriptreact = web,
          json = web,
          jsonc = web,
          yaml = prettier_only,
          css = prettier_only,
          scss = prettier_only,
          less = prettier_only,
          html = prettier_only,
          markdown = prettier_only,
          graphql = prettier_only,
          handlebars = prettier_only,
          terraform = { "terraform_fmt" },
          ["terraform-vars"] = { "terraform_fmt" },
        },
        -- Single source of truth for format-on-save.
        --   * web filetypes: use ONLY oxfmt/prettier (lsp_format = "never"), so
        --     a missing formatter never falls back to noisy ts_ls formatting.
        --   * everything else: lsp_format = "fallback" keeps lua/python/rust
        --     formatting working via their language servers.
        format_on_save = function(bufnr)
          local ft = vim.bo[bufnr].filetype
          -- go is handled by go.nvim's own goimport-on-save.
          if ft == "go" or ft == "gomod" then
            return nil
          end
          return {
            timeout_ms = 2000,
            lsp_format = web_filetypes[ft] and "never" or "fallback",
          }
        end,
      })
    end,
  },
}
