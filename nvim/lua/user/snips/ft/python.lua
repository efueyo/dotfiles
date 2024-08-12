local ls = require("luasnip")

local s = ls.s
local t = ls.text_node
local i = ls.insert_node
return {
  s({
    trig = "assertcallcount",
    name = "assert X.call_count == Y",
  }, {
    t("assert "),
    i(1),
    t(".call_count == "),
    i(2, "1"),
  }),
  s({
    trig = "assertcallargs",
    name = "assert X.call_args[N] == Y",
  }, {
    t("assert "),
    i(1),
    t(".call_args["),
    i(2, "1"),
    t("] == "),
    i(3),
  }),
}
