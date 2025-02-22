-- adaptation from leoluz/nvim-dap-go to execute ginkgo tests
local function debug_package()
	local dap = require("dap")
	local test_dir = vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
	test_dir = "./" .. test_dir

	local config = {
		type = "go",
		request = "launch",
		mode = "test",
		program = test_dir,
		outputMode = "remote",
	}
	dap.run(config)
end
vim.keymap.set("n", "<leader>dp", debug_package, { desc = "[D]ebug [P]ackage" })
