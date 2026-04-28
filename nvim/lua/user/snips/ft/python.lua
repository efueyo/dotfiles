local ls = require("luasnip")
local extras = require("luasnip.extras")

local s = ls.s
local t = ls.text_node
local i = ls.insert_node
local rep = extras.rep
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
  s({
    trig = "printvar",
    name = 'print("A:", A)',
  }, {
    t('print("'),
    rep(1),
    t(':", '),
    i(1, "variable"),
    t(")"),
  }),
  s({
    trig = "printerr",
    name = "print(..., file=sys.stderr)",
  }, {
    t("print("),
    i(1),
    t(", file=sys.stderr)"),
  }),
  s({
    trig = "clftime",
    name = "datetime.strptime(s, CLF format)",
  }, {
    t('datetime.strptime('),
    i(1, "s"),
    t(', "%d/%b/%Y:%H:%M:%S %z")'),
  }),
  s({
    trig = "isotime",
    name = "datetime.fromisoformat(s)",
  }, {
    t("datetime.fromisoformat("),
    i(1, "s"),
    t(")"),
  }),
}
