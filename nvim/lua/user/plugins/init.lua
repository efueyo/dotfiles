return {

	-- GIT
	"tpope/vim-fugitive",

	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
	},

	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = function()
			pcall(require("nvim-treesitter.install").update({ with_sync = true }))
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
	},

	{
		"nvim-treesitter/playground",
		config = function()
			require("nvim-treesitter.configs").setup({})
		end,
	},
	-- telescope requirements
	"nvim-lua/popup.nvim",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
	"nvim-telescope/telescope-fzy-native.nvim",
	"nvim-telescope/telescope-ui-select.nvim",

	"nvim-tree/nvim-web-devicons",

	{ "catppuccin/nvim", name = "catppuccin" },

	"ray-x/go.nvim",

	{
		"mfussenegger/nvim-dap",
		config = function()
			require("user.dap").setup()
		end,
	},
	"leoluz/nvim-dap-go",
	"rcarriga/nvim-dap-ui",
	"theHamsta/nvim-dap-virtual-text",
	"nvim-telescope/telescope-dap.nvim",

	"hashivim/vim-terraform",
	"towolf/vim-helm",

	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	"github/copilot.vim",
	-- 'David-Kunz/gen.nvim',
}
