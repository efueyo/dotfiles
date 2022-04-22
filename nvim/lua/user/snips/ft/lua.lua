local ls = require"luasnip"

local s = ls.s
local t = ls.t
local i = ls.i

return {
  s({
    trig = "snip",
    name = "A snippet to create snippets",
  }, {
    t({"s({", ""}),
    t("\ttrig = \""), i(1, "trig"), t({"\",", ""}),
    t("\tname = \""), i(2, "Name or Description"), t({"\",", ""}),
    t({"},{", ""}),
    t("\t"), i(3),
    t({"", "}),"}),
  }),
}
