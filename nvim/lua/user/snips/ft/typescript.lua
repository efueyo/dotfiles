local ls = require"luasnip"
local extras = require "luasnip.extras"


local s = ls.s
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local rep = extras.rep


return {
  s({
    trig = "consolevar",
    name = "console.log('a', a)",
  },{
    t("console.log(\""), rep(1), t("\", "), i(1, "variable"), t(")"),
  }),
  s({
    trig = "consolevarjson",
    name = "console.log('a', JSON.stringify(a, null, 2))",
  },{
    t("console.log('"), rep(1), t("', JSON.stringify("), i(1, "variable"), t(", null, 2))"),
  }),
  s({
    trig = "if",
    name = "if(...) {...}",
  },{
    t("if ("), i(1, "condition"), t({") {","\t"}),
    i(2),
    t({"","}"}),
  }),
  s({
    trig = "interface",
    name = "interface A {...}",
  },{
    t("interface "), i(1, "InterfaceName"), t({" {", ""}),
    t("\t"), i(2),
    t({"","}"}),
  }),
  s({
    trig = "describe",
    name = "describe(a, () => {})",
  },{
    t("describe('"), i(1), t({"', () => {", "\t"}),
    i(2),
    t({"","})"}),
  }),
  s({
    trig = "itshould",
    name = "it(should..., () => {})",
  },{
    t("it('should "), i(1), t("', "), c(2,{ t(""), t("async ")}), t({"() => {", "\t"}),
    i(3),
    t({"","})"}),
  }),
  s({
    trig = "expect",
    name = "expect(A).toEqual(B)",
  },{
    t("expect("), i(1), t(").toEqual("), i(2), t(")"),
  }),
  s({
    trig = "expectlen",
    name = "expect(A).toHaveLength(B)",
  },{
    t("expect("), i(1), t(").toHaveLength("), i(2,"0"), t(")"),
  }),
  s({
    trig = "funca",
    name = "()=>{}",
  },{
    t({"() => {","\t"}),
    i(1),
    t({"","}"}),
  }),
}
