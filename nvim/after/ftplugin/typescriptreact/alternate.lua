local go_to_alternate = require "user.alternate"

vim.keymap.set("n", "<leader>ga", function() go_to_alternate(".tsx", ".test.tsx") end)
vim.keymap.set("n", "<leader>gav", function() go_to_alternate(".tsx", ".test.tsx", "vsplit") end)
