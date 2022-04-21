
local M = {}

M.snake_case = function (word)
  -- (%u) caputres any Uppercase, (%l) captures any lowercase.
  return string.lower(string.gsub(word, "(%l)(%u)", "%1_%2"))
end

return M
