local keymap = vim.keymap.set
return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"leoluz/nvim-dap-go",
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local dapgo = require("dap-go")
		dapui.setup()
		dapgo.setup()
		require("nvim-dap-virtual-text").setup()

		keymap("n", "<F1>", dap.step_back)
		keymap("n", "<F2>", dap.step_into)
		keymap("n", "<F3>", dap.step_over)
		keymap("n", "<F4>", dap.step_out)
		keymap("n", "<F5>", dap.continue)
		keymap("n", "<leader>b", dap.toggle_breakpoint)

		dap.listeners.before.attach.dapui_config = dapui.open
		dap.listeners.before.launch.dapui_config = dapui.open
		dap.listeners.before.event_terminated.dapui_config = dapui.close
		dap.listeners.before.event_exited.dapui_config = dapui.close
	end,
}
