local ls = require"luasnip"
local extras = require "luasnip.extras"


local s = ls.s
local t = ls.text_node
local i = ls.insert_node
local rep = extras.rep


return {
  s({
    trig = "consolevar",
    name = "console.log('a', a)",
  },{
    t("console.log(\""), rep(1), t("\", "), i(1, "variable"), t(")"),
  }),
  s({
    trig = "jsonstringify",
    name = "JSON.stringify(variable, null, 2)",
  },{
    t("JSON.stringify("), i(1, "variable"), t(", null, 2)"),
  }),
  s({
    trig = "interface",
    name = "interface A {...}",
  },{
    t("interface "), i(1, "InterfaceName"), t({" {", ""}),
    t("\t"), i(2),
    t({"","}"}),
  }),
}
