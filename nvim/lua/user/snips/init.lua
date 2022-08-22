local ls = require"luasnip"
local t = ls.text_node
local c = ls.choice_node

local M = {}

M.snake_case = function (word)
  -- (%u) caputres any Uppercase, (%l) captures any lowercase.
  return string.lower(string.gsub(word, "(%l)(%u)", "%1_%2"))
end

M.camel_split = function (text)
  local words = {}
  for word in string.gmatch(text, "(%u%l*)") do
    table.insert(words, word)
  end
  if #words == 0 then
    return {text}
  end
  return words
end

M.lowercase_first = function (text)
  return string.gsub(text, "^.", function (s)
    return string.lower(s)
  end)
end

-- add all elements from table b at the end of table a
M.append_to_list = function (a,b)
  return table.move(b, 1 ,#b, #a+1, a)
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
