local ls = require"luasnip"

local s = ls.s
local t = ls.text_node
local f = ls.f
local i = ls.insert_node


local capture_cmd = function (cmd)
  local file = io.popen(cmd, "r")
  local content = assert(file:read('*a'))
  file:close()
  content = string.gsub(content, '^%s+', '')
  content = string.gsub(content, '[\n\r]+', ' ')
  content = string.gsub(content, '%s+$', '')
  return content
end

return {
  s("feat", {t("feat("), i(1), t("): "), i(2)}),
  s("fix", {t("fix("), i(1), t("): "), i(2)}),
  s("refactor", {t("refactor("), i(1), t("): "), i(2)}),
  s("chore", {t("chore("), i(1), t("): "), i(2)}),
  s("hack", {t("hack("), i(1), t("): "), i(2)}),
  s("test", {t("test("), i(1), t("): "), i(2)}),
  s("docs", {t("docs("), i(1), t("): "), i(2)}),
  s("branchtag", {
    f(function ()
      local branch = capture_cmd("git branch --show-current")
      -- from branch names like feature/abc-123-include-this-feature
      -- extract #ABC-123
      local tag = string.gsub(branch, "^.*/(%a+)-(%d+).*", function (c1, c2)
        return string.upper(c1) .. "-" .. c2
      end)

      return "#"..tag
    end)
  }),
  s("noci", {t("[no ci]")}),
  s("wip", {t("#WIP")}),
  s("revertme", {t("#REVERTME")}),
}
