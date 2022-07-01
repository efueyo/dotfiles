local go_to_alternate = require"user.alternate"

vim.keymap.set("n", "<leader>ga", function () go_to_alternate(".go", "_test.go") end)
vim.keymap.set("n", "<leader>gav", function () go_to_alternate(".go", "_test.go", "vsplit") end)
-- go to test suite file
local go_to_test_suite = function ()
  local test_suite_path = vim.fn.expand("%:h") .. "/*suite_test.go"
  vim.cmd("e ".. test_suite_path)

end
vim.keymap.set("n", "<leader>ts", function () go_to_test_suite() end)

