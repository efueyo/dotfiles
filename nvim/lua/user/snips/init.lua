local ls = require"luasnip"
local t = ls.text_node
local c = ls.choice_node

local M = {}

M.snake_case = function (word)
  -- (%u) caputres any Uppercase, (%l) captures any lowercase.
  return string.lower(string.gsub(word, "(%l)(%u)", "%1_%2"))
end

-- returns a choice node with all options as text nodes from opts and optional extra_nodes appended as last choices
-- useful for choices_from_list(1, {"opt1", "opt2"}, i(nil, "otherValueYouCanEdit"))
M.choices_from_list = function (position, opts, extra_nodes)
  extra_nodes = extra_nodes or {}
  local choices =  {}
  for _,v in pairs(opts) do
    table.insert(choices, t(v))
  end
  for _,v in pairs(extra_nodes) do
    table.insert(choices, v)
  end

  return c(position, choices)
end

M.starts_with = function (s, prefix)
  return string.find(s, prefix, 1) == 1
end
M.ends_with = function (s, suffix)
  return string.sub(s, -string.len(suffix)) == suffix
end


return M
