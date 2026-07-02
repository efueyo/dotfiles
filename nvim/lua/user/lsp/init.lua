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

local on_attach = function(client, bufnr)
  lsp_keymaps(bufnr)

  if client:supports_method("textDocument/foldingRange") then
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
  end
  vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })
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

-- Rounded borders for all floating windows (hover, signature help, etc.).
-- Replaces the removed `vim.lsp.with(...)` handler wrapping.
vim.o.winborder = "rounded"

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
  rust_analyzer = {},
  ts_ls = {
    typescript = {
      preferences = {
        includePackageJsonAutoImports = "on",
        includeCompletionsForModuleExports = true,
        includeCompletionsForImportStatements = true,
        importModuleSpecifierPreference = "non-relative",
      },
    },
    javascript = {
      preferences = {
        includePackageJsonAutoImports = "on",
        includeCompletionsForModuleExports = true,
      },
    },
  },
  terraformls = {},
  basedpyright = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none",
          -- Catches discarded return of pure calls like `dt.replace(tzinfo=tz)`.
          reportUnusedCallResult = "warning",
          -- Catches always-True/False conditions like `ts.timetz() is None`.
          reportUnnecessaryComparison = "warning",
        },
      },
      disableOrganizeImports = true,
    },
  },
  ruff = {},

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },

      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
        },
      },
    },
  },
}

-- Setup neovim lua configuration
require("neodev").setup()
--
-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Setup mason so it can manage external tooling
require("mason").setup()

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
  ensure_installed = vim.tbl_keys(servers),
})

-- Per-server init_options (sent at initialize, before workspace/configuration).
-- typescript-language-server reads its tsserver memory budget from here.
local init_options = {
  ts_ls = {
    maxTsServerMemory = 8192,
  },
}

for server_name, settings in pairs(servers) do
  vim.lsp.config(server_name, {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = settings,
    init_options = init_options[server_name],
  })
end

-- :LspRestart [name] — stop LSP client(s) and re-attach across loaded buffers.
-- Useful after tsserver dies (SIGABRT) and Nvim gives up auto-restarting.
-- Re-attaches by re-firing FileType (via vim.lsp.enable) rather than :edit,
-- so unsaved buffer changes are preserved.
vim.api.nvim_create_user_command("LspRestart", function(opts)
  local filter = opts.args ~= "" and { name = opts.args } or nil
  local clients = vim.lsp.get_clients(filter)
  if vim.tbl_isempty(clients) then
    vim.notify("LspRestart: no active LSP clients", vim.log.levels.WARN)
    return
  end

  local ids = {}
  for _, client in ipairs(clients) do
    ids[#ids + 1] = client.id
    client:stop(true)
  end

  local stopped = vim.wait(5000, function()
    for _, id in ipairs(ids) do
      local c = vim.lsp.get_client_by_id(id)
      if c and not c:is_stopped() then
        return false
      end
    end
    return true
  end, 50)

  if not stopped then
    vim.notify("LspRestart: clients did not stop within 5s", vim.log.levels.ERROR)
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
      vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
    end
  end
  vim.notify("LspRestart: restarted " .. #ids .. " client(s)", vim.log.levels.INFO)
end, {
  nargs = "?",
  desc = "Restart LSP client(s) and re-attach loaded buffers",
  complete = function()
    return vim.tbl_map(function(c)
      return c.name
    end, vim.lsp.get_clients())
  end,
})
