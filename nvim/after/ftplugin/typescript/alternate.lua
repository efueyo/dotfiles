local go_to_alternate = require"user.alternate"

vim.keymap.set("n", "<leader>ga", function () go_to_alternate(".ts", ".test.ts") end)
vim.keymap.set("n", "<leader>gav", function () go_to_alternate(".ts", ".test.ts", "vsplit") end)

