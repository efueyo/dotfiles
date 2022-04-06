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

}


local s = ls.s
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node

ls.add_snippets("all", {
})

ls.add_snippets("gitcommit", {
  s("feat", {t("feat("), i(1), t("): "), i(2)}),
  s("fix", {t("fix("), i(1), t("): "), i(2)}),
  s("chore", {t("chore("), i(1), t("): "), i(2)}),
  s("hack", {t("hack("), i(1), t("): "), i(2)}),
})
-- Go
ls.add_snippets("go", {
  s({
    trig = "experr",
    name = "Expect(err).To(HaveOccurred())",
  },{
    t("Expect(err)."), c(1, {t("ToNot"), t("To")}), t("(HaveOccurred())")
  }),
  s({
    trig = "expeq",
    name = "Expect(A).To(Equal(B))",
  },{
    t("Expect("), i(1), t(").To(Equal("), i(2), t("))")
  }),
  s({
    trig = "desc",
    name = "Describe(\"\", func () {...})",
  },{
    t("Describe(\""), i(1), t({"\", func() {", ""}), i(2), t({"","})"})
  }),
  s({
    trig = "it",
    name = "It(\"\", func () {...})",
  },{
    t("It(\""), i(1), t({"\", func() {", ""}), i(2), t({"","})"})
  }),
  s({
    trig = "impginkgo",
    name = "Ginkgo and Gomega import",
  },{
    t({
      "import (",
      "  . \"github.com/onsi/ginkgo/v2\"",
      "  . \"github.com/onsi/gomega\"",
      ")"
    })
  }),
  s({
    trig = "funcm",
    name = "Func method",
  },{
    t("func ("), i(1), t(") "), i(2, "funcName"), t("("), i(3,"arguments"), t(") "), c(4, {t(""), t("error"), i(1, "retValue")}), t({" {",""}),
    t("\t"),i(5),
    t({"","}"}),
  }),
  s({
    trig = "func",
    name = "Func",
  },{
    t("func "), i(1, "funcName"), t("("), i(2,"arguments"), t(") "), c(3, {t(""), t("error"), i(1, "retValue")}), t({" {",""}),
    t("\t"),i(4),
    t({"","}"}),
  }),
})


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
-- This is useful for choice nodes (introduced in the forthcoming episode 2)
vim.keymap.set("i", "<c-l>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)


-- shorcut to source myluasnips file again, which will reload my snippets
vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")
