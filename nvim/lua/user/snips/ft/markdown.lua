local ls = require("luasnip")

local s = ls.s
local f = ls.f

return {
	s("currentdate", {
		f(function()
			return os.date("%Y %b %d")
		end),
	}),
}
