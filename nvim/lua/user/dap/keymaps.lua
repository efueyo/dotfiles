local M = {}
local keymap = vim.keymap.set

function M.setup()
  local dap = require('dap')
  -- configure dap keymaps
  keymap("n", "<F1>", function() dap.step_back() end)
  keymap("n", "<F2>", function() dap.step_into() end)
  keymap("n", "<F3>", function() dap.step_over() end)
  keymap("n", "<F4>", function() dap.step_out() end)
  keymap("n", "<F5>", function() dap.continue() end)
  keymap("n", "<leader>b", function() require'dap'.toggle_breakpoint() end)
  keymap("n", "<leader>B", function() require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end)
  keymap("n", "<leader>dt", function() require'dap-go'.debug_test() end)
end

return M
