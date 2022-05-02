local ls = require"luasnip"
local extras = require "luasnip.extras"

local ts_funcs = require"user.treesitter.go"

local shared = require "user.snips"
local snake_case = shared.snake_case
local camel_split = shared.camel_split
local choices_from_list = shared.choices_from_list

local s = ls.s
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local c = ls.choice_node
local f = ls.function_node
local rep = extras.rep

return {
  s({
    trig = "expecterror",
    name = "Expect(err).To(HaveOccurred())",
  },{
    t("Expect(err)."), c(1, {t("ToNot"), t("To")}), t({"(HaveOccurred())",""}),
  }),
  s({
    trig = "expectequal",
    name = "Expect(A).To(Equal(B))",
  },{
    t("Expect("), i(1), t(").To(Equal("), i(2), t("))"),
  }),
  s({
    trig = "expectlen",
    name = "Expect(A).To(HaveLen(B))",
  },{
    t("Expect("), i(1), t(").To(HaveLen("), i(2, "0"), t("))"),
  }),
  s({
    trig = "expectnil",
    name = "Expect(A).To(BeNil())",
  },{
    t("Expect("), i(1), t(").To(BeNil())"),
  }),
  s({
    trig = "eventually",
    name = "Eventually block for ginkgo",
  },{
		t({"Eventually(func(g Gomega) {","\t"}),
		i(1, "g.Expect(true).To(Equal(true))"),
		t({"", "}).Should(Succeed())",""}),
  }),
  s({
    trig = "expectconsistof",
    name = "Expect(A).To(ConsistOf({...})",
  },{
    t("Expect("), i(1), t({").To(ConsistOf(","\t"}),
    i(2),
    t({"","))"}),
  }),
  s({
    trig = "betemporally",
    name = "BeTemporally(\"~\", value, time.Millisecond),",
  },{
    t("BeTemporally(\"~\", "), i(1, "value"), t(", time.Millisecond)"),
  }),
  s({
    trig = "desc",
    name = "Describe(\"\", func () {...})",
  },{
    t("Describe(\""), i(1), t({"\", func() {", "\t"}), i(2), t({"","})"})
  }),
  s({
    trig = "it",
    name = "It(\"\", func () {...})",
  },{
    t("It(\""), i(1), t({"\", func() {", "\t"}), i(2), t({"","})"})
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
    trig = "typestruct",
    name = "type A struct {}",
  },{
    t("type "), i(1), t({" struct {", "\t"}),
    i(2),
    t({"","}",""}),
  }),
  s({
    trig = "typeinterface",
    name = "type A interface {}",
  },{
    t("type "), i(1), t({" interface {", "\t"}),
    i(2),
    t({"","}",""}),
  }),
  s({
    trig = "forrange",
    name = "for _, a := range X {...}",
  },{
    t("for "), c(1, {
      sn(nil, {t("_, "), i(1,"e")}),
      sn(nil, {t("i, "), i(1,"e")}),
      t("i"),
    }), t(" := range "), i(2), t({" {", "\t"}),
    i(3),
    t({"","}",""}),
  }),
  s({
    trig = "map",
    name = "map[A]B{}",
  },{
    t("map["), i(1), t("]"), i(2), t("{}"),
  }),
  s({
    trig = "if",
    name = "if condition {}",
  },{
    t("if "), i(1, "condition"), t({" {", "\t"}),
    i(2),
    t({"", "}"}),
  }),
  s({
    trig = "funcm",
    name = "Func method",
  },{
    t("func ("),
    d(1, function ()
      local values = ts_funcs.find_structs()
      local choices = {}
      for _, v in pairs(values) do
        -- get last word of a camelCased name (words[#words])
        -- get the first character of this word (string.sub(word,(1,1))
        -- lowercase it
        -- ThisAmazingHandler => h
        -- SomeInternalServer => s
        local words = camel_split(v)
        local p = string.lower( string.sub(words[#words], 1, 1))
        table.insert(choices, t(p.." *"..v))
      end
      table.insert(choices, i(nil, "p OtherReceiver"))

      return sn(nil, {
        c(1, choices),
      })
    end),
    t(") "), i(2, "funcName"), t("("), i(3,"arguments"), t(") "), c(4, {t(""), t("error"), i(1, "retValue")}), t({" {",""}),
    t("\t"),i(5),
    t({"","}"}),
  }),
  s({
    trig = "funca",
    name = "Annonymous Func",
  },{
    t({"func () {", ""}),
    t("\t"),i(1),
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
  s({
    trig = "printvar",
    name = "fmt.Printf(\"A; %+v\\n\", A)",
  },{
    t("fmt.Printf(\""), rep(1), t(": %+v\\n\", "), i(1, "variable"), t(")"),
  }),
  s({
    trig = "moq",
    name = "go:generate moq interface",
  },{
    t("//go:generate moq -rm -out "),
    f(function(args)
      return snake_case(args[1][1])
    end, {1}),
    t("_mock.go . "),
    d(1, function ()
      local values = ts_funcs.find_interfaces()
      return sn(nil, {
        choices_from_list(1, values, {i(nil, "OtherInterface")})
      })
    end )
  }),
  s({
    trig = "vars",
    name = "Block of var declaration",
  },{
    t({"var (", "\t"}),
    i(1),
    t({"",")",""}),
  }),
}
