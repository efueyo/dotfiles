-- config got from tjdevries

local ls = require"luasnip"
local types = require "luasnip.util.types"

ls.config.set_config {
  -- This tells LuaSnip to remember to keep around the last snippet.
  -- You can jump back into it even if you move outside of the selection
  history = true,

  -- This one is cool cause if you have dynamic snippets, it updates as you type!
  updateevents = "TextChanged,TextChangedI",

  -- Autosnippets:
  enable_autosnippets = true,
  ext_opts = {
    [types.choiceNode] = {
      active = {
        virt_text = { { " <<-", "NonTest" } },
      },
    },
  },
}

for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/user/snips/ft/*.lua", true)) do
  local ft = vim.fn.fnamemodify(ft_path, ":t:r")
  local snips = loadfile(ft_path)()
  ls.add_snippets(ft, snips, {key = ft})
  if ft == "typescript" then
    ls.add_snippets("typescriptreact", snips, {key = "typescriptreact"})
  end
end

-- <c-k> is expansion key
-- this will expand the current item or jump to the next item within the snippet.
vim.keymap.set({ "i", "s" }, "<c-k>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true })

-- <c-j> is jump backwards key.
-- this always moves to the previous item within the snippet
vim.keymap.set({ "i", "s" }, "<c-j>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })

-- <c-l> is selecting within a list of options.
-- This is useful for choice nodes
vim.keymap.set({"i", "s"}, "<c-l>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)


-- shorcut to source my luasnips file again, which will reload snippets
vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")
