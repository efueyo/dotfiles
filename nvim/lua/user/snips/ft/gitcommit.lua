
local ls = require"luasnip"

local s = ls.s
local t = ls.text_node
local i = ls.insert_node


return {
  s("feat", {t("feat("), i(1), t("): "), i(2)}),
  s("fix", {t("fix("), i(1), t("): "), i(2)}),
  s("chore", {t("chore("), i(1), t("): "), i(2)}),
  s("hack", {t("hack("), i(1), t("): "), i(2)}),
}
