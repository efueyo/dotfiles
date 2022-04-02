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
        virt_text = { { " <- Current Choice", "NonTest" } },
      },
    },
  },
}


local s = ls.s
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node

ls.add_snippets("all", {
})

-- Go
ls.add_snippets("go", {
  s({
    trig = "expe",
    name = "Expect(err).To(HaveOccurred())",
  },{
    t("Expect(err)."), c(1, {t("To"), t("ToNot")}), t("(HaveOccurred())")
  }),
  s({
    trig = "expeq",
    name = "Expect(A).To(Equal(B))",
  },{
    t("Expect("), i(1), t(")."), t("To(Equal("), i(2), t("))")
  }),
})

-- shorcut to source myluasnips file again, which will reload my snippets
vim.api.nvim_set_keymap("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>", { noremap = true })
