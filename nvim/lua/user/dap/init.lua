local M = {}


local function configure_exts()
  require("nvim-dap-virtual-text").setup {
    commented = true,
  }
  require('dap-go').setup()

  local dap, dapui = require "dap", require "dapui"
  dapui.setup {} -- use default
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end


function M.setup()
  configure_exts()
  require("user.dap.keymaps").setup()
end

return M
