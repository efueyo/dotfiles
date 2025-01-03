local ls = require("luasnip")
local extras = require("luasnip.extras")

local ts_funcs = require("user.treesitter.go")

local shared = require("user.snips")
local snake_case = shared.snake_case
local camel_split = shared.camel_split
local choices_from_list = shared.choices_from_list
local lowercase_first = shared.lowercase_first
local append_to_list = shared.append_to_list

local s = ls.s
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local c = ls.choice_node
local f = ls.function_node
local rep = extras.rep

local receiver_name = function(v)
	-- get last word of a camelCased name (words[#words])
	-- get the first character of this word (string.sub(word,(1,1))
	-- lowercase it
	-- ThisAmazingHandler => h
	-- SomeInternalServer => s
	local words = camel_split(v)
	local p = string.lower(string.sub(words[#words], 1, 1))
	return p
end
return {
	s({
		trig = "expecterror",
		name = "Expect(err).To(HaveOccurred())",
	}, {
		t("Expect(err)."),
		c(1, { t("ToNot"), t("To") }),
		t({ "(HaveOccurred())", "" }),
	}),
	s({
		trig = "expectequal",
		name = "Expect(A).To(Equal(B))",
	}, {
		t("Expect("),
		i(1),
		t(").To(Equal("),
		i(2),
		t("))"),
	}),
	s({
		trig = "expectlen",
		name = "Expect(A).To(HaveLen(B))",
	}, {
		t("Expect("),
		i(1),
		t(").To(HaveLen("),
		i(2, "0"),
		t("))"),
	}),
	s({
		trig = "expectnil",
		name = "Expect(A).To(BeNil())",
	}, {
		t("Expect("),
		i(1),
		t(").To(BeNil())"),
	}),
	s({
		trig = "eventually",
		name = "Eventually block for ginkgo",
	}, {
		t({ "Eventually(func(g Gomega) {", "\t" }),
		i(1, "g.Expect(true).To(Equal(true))"),
		t({ "", "}).Should(Succeed())", "" }),
	}),
	s({
		trig = "expectconsistof",
		name = "Expect(A).To(ConsistOf({...})",
	}, {
		t("Expect("),
		i(1),
		t({ ").To(ConsistOf(", "\t" }),
		i(2),
		t({ "", "))" }),
	}),
	s({
		trig = "selecttimeout",
		name = "select { cases with timeout}",
	}, {
		t({ "select {", "" }),
		t("case "),
		i(1, "<- syncChan"),
		t({ ":", "" }),
		t({ "case <- time.After(1 * time.Second):", '\tFail("timeout")' }),
		t({ "", "}" }),
	}),
	s({
		trig = "betemporally",
		name = 'BeTemporally("~", value, time.Millisecond),',
	}, {
		t('BeTemporally("~", '),
		i(1, "value"),
		t(", time.Millisecond)"),
	}),
	s({
		trig = "describe",
		name = 'Describe("", func () {...})',
	}, {
		t('Describe("'),
		i(1),
		t({ '", func() {', "\t" }),
		i(2),
		t({ "", "})" }),
	}),
	s({
		trig = "context",
		name = 'Context("", func () {...})',
	}, {
		t('Context("'),
		i(1),
		t({ '", func() {', "\t" }),
		i(2),
		t({ "", "})" }),
	}),
	s({
		trig = "when",
		name = 'When("", func () {...})',
	}, {
		t('When("'),
		i(1),
		t({ '", func() {', "\t" }),
		i(2),
		t({ "", "})" }),
	}),
	s({
		trig = "beforeeach",
		name = "BeforeEach(func () {...})",
	}, {
		t({ "BeforeEach(func() {", "\t" }),
		i(1),
		t({ "", "})" }),
	}),
	s({
		trig = "itshould",
		name = 'It("should", func () {...})',
	}, {
		t('It("should '),
		i(1),
		t({ '", func() {', "\t" }),
		i(2),
		t({ "", "})" }),
	}),
	s({
		trig = "impginkgo",
		name = "Ginkgo and Gomega import",
	}, {
		t({
			"import (",
			'  . "github.com/onsi/ginkgo/v2"',
			'  . "github.com/onsi/gomega"',
			")",
		}),
	}),
	s({
		trig = "typestruct",
		name = "type A struct {}",
	}, {
		t("type "),
		i(1),
		t({ " struct {", "\t" }),
		i(2),
		t({ "", "}", "" }),
	}),
	s({
		trig = "newstruct",
		name = "struct function initializer",
	}, {
		d(1, function()
			local nodes_for_struct = function(struct_info, return_pointer_value)
				local struct_name = struct_info.name
				local nodes = {
					t("func New"),
					t(struct_name),
					t("("),
				}
				local arguments = {}
				for _, field in pairs(struct_info.fields) do
					local argument = lowercase_first(field.fname) .. " " .. field.ftype
					table.insert(arguments, argument)
				end
				-- more than 3 arugments, split them in several rows
				if #arguments > 3 then
					for _, argument in pairs(arguments) do
						table.insert(nodes, t({ "", "\t" .. argument .. "," }))
					end
					table.insert(nodes, t({ "", ") " }))
				else
					table.insert(nodes, t(table.concat(arguments, ", ")))
					table.insert(nodes, t(") "))
				end

				if return_pointer_value then
					table.insert(nodes, t("*"))
				end
				append_to_list(nodes, {
					t(struct_name),
					t({ " {", "\t" }),
					t("res := "),
				})

				if return_pointer_value then
					table.insert(nodes, t("&"))
				end
				append_to_list(nodes, { t(struct_name), t({ "{", "\t" }) })
				for _, field in pairs(struct_info.fields) do
					local field_assignation = "\t" .. field.fname .. ": " .. lowercase_first(field.fname) .. ","
					table.insert(nodes, t({ field_assignation, "\t" }))
				end
				table.insert(nodes, t({ "}", "\treturn res", "}", "" }))
				-- this last insert node is necessary!
				-- we need something to jump and here there are only text nodes
				table.insert(nodes, i(1))
				return nodes
			end
			local choices = {}
			for _, struct_info in pairs(ts_funcs.find_structs_info()) do
				table.insert(choices, sn(nil, nodes_for_struct(struct_info, false)))
				table.insert(choices, sn(nil, nodes_for_struct(struct_info, true)))
			end
			return sn(nil, {
				c(1, choices),
			})
		end),
	}),
	s({
		trig = "typeinterface",
		name = "type A interface {}",
	}, {
		t("type "),
		i(1),
		t({ " interface {", "\t" }),
		i(2),
		t({ "", "}", "" }),
	}),
	s({
		trig = "forrange",
		name = "for _, a := range X {...}",
	}, {
		t("for "),
		c(1, {
			sn(nil, { t("_, "), i(1, "e") }),
			sn(nil, { t("i, "), i(1, "e") }),
			i(1, "k, v"),
			t("i"),
		}),
		t(" := range "),
		i(2),
		t({ " {", "\t" }),
		i(3),
		t({ "", "}", "" }),
	}),
	s({
		trig = "map",
		name = "map[A]B{}",
	}, {
		t("map["),
		i(1),
		t("]"),
		i(2),
		t("{}"),
	}),
	s({
		trig = "mapstringany",
		name = "map[string]any{}",
	}, {
		t("map[string]any{}"),
	}),
	s({
		trig = "if",
		name = "if condition {}",
	}, {
		t("if "),
		i(1, "condition"),
		t({ " {", "\t" }),
		i(2),
		t({ "", "}" }),
	}),
	s({
		trig = "iferr",
		name = "if err != nil { return values }",
	}, {
		t({ "if err != nil {", "\t" }),
		f(function()
			local ret_values = ts_funcs.ret_values()
			return { "return " .. table.concat(ret_values, ", "), "" }
		end),
		t({ "}", "" }),
	}),
	s({
		trig = "funcm",
		name = "Func method",
	}, {
		t("func ("),
		d(1, function()
			local values = ts_funcs.find_structs()
			local choices = {}
			for _, v in pairs(values) do
				local p = receiver_name(v)
				table.insert(choices, t(p .. " *" .. v)) -- with pointer receiver
				table.insert(choices, t(p .. " " .. v)) -- without pointer receiver
			end
			table.insert(choices, i(nil, "p OtherReceiver"))

			return sn(nil, {
				c(1, choices),
			})
		end),
		t(") "),
		i(2, "funcName"),
		t("("),
		i(3, "arguments"),
		t(") "),
		c(4, { t(""), t("error"), i(1, "retValue") }),
		t({
			" {",
			"",
		}),
		t("\t"),
		i(5),
		t({ "", "}" }),
	}),
	s({
		trig = "funca",
		name = "Annonymous Func",
	}, {
		t({ "func () {", "" }),
		t("\t"),
		i(1),
		t({ "", "}" }),
	}),
	s({
		trig = "accessor",
		name = "func (x X) ID {return ID} to access fields",
	}, {
		d(1, function()
			local accessor_func = function(sname, fname, ftype)
				local p = receiver_name(sname)
				-- uppercase first character
				local func_name = string.gsub(fname, "^.", string.upper)
				if fname == "id" then
					func_name = "ID"
				end

				local nodes = {
					t({ "", "func (" .. p .. " " .. sname .. ") " .. func_name .. "() " .. ftype .. " {", "\t" }),
					t({ "return " .. p .. "." .. fname, "}", "" }),
				}
				-- this last insert node is necessary!
				-- we need something to jump and here there are only text nodes
				table.insert(nodes, i(1))
				return nodes
			end
			local choices = {}
			for _, struct_info in pairs(ts_funcs.find_structs_info()) do
				for _, field in pairs(struct_info.fields) do
					-- only private fields (first letter is lowercase)
					if string.find(field.fname, "^%l") then
						table.insert(choices, sn(nil, accessor_func(struct_info.name, field.fname, field.ftype)))
					end
				end
			end
			return sn(nil, {
				c(1, choices),
			})
		end),
	}),
	s({
		trig = "func",
		name = "Func",
	}, {
		t("func "),
		i(1, "funcName"),
		t("("),
		i(2, "arguments"),
		t(") "),
		c(3, { t(""), t("error"), i(1, "retValue") }),
		t({
			" {",
			"",
		}),
		t("\t"),
		i(4),
		t({ "", "}" }),
	}),
	s({
		trig = "printvar",
		name = 'fmt.Printf("A; %+v\\n", A)',
	}, {
		t('fmt.Printf("'),
		rep(1),
		t(': %+v\\n", '),
		i(1, "variable"),
		t(")"),
	}),
	s({
		trig = "printvarjson",
		name = 'x, _ = json.Marshall(A); fmt.Printf("A; %+v\\n", x)',
	}, {
		t("printValue, _ := json.Marshal("),
		i(1, "variable"),
		t({ ")", 'fmt.Printf("' }),
		rep(1),
		t(': %s\\n", printValue)'),
	}),
	s({
		trig = "moq",
		name = "go:generate moq interface",
	}, {
		t("//go:generate moq -rm -out "),
		f(function(args)
			return snake_case(args[1][1])
		end, { 1 }),
		t("_mock.go . "),
		d(1, function()
			local values = ts_funcs.find_interfaces()
			return sn(nil, {
				choices_from_list(1, values, { i(nil, "OtherInterface") }),
			})
		end),
	}),
	s({
		trig = "vars",
		name = "Block of var declaration",
	}, {
		t({ "var (", "\t" }),
		i(1),
		t({ "", ")", "" }),
	}),
	s({
		trig = "consts",
		name = "Block of const declaration",
	}, {
		t({ "const (", "\t" }),
		i(1),
		t({ "", ")", "" }),
	}),
	s({
		trig = "retnil",
	}, {
		t("return nil"),
	}),
	s({
		trig = "chanstruct",
		name = "chan struct{}",
	}, {
		t("chan struct{}"),
	}),
}
