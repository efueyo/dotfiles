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

	-- telescope requirements
	"nvim-lua/popup.nvim",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
	"nvim-telescope/telescope-fzy-native.nvim",
	"nvim-telescope/telescope-ui-select.nvim",

	"nvim-tree/nvim-web-devicons",

	{ "catppuccin/nvim", name = "catppuccin" },

	{
		"ray-x/go.nvim",
		config = function()
			require("go").setup({ lsp_codelens = false })
		end,
		ft = { "go", "gomod" },
	},

	"hashivim/vim-terraform",
	"towolf/vim-helm",

	{
		"github/copilot.vim",
		cond = function()
			local isDisabled = vim.fn.getenv("COPILOT_DISABLED") ~= vim.NIL
			return not isDisabled
		end,
	},
	-- 'David-Kunz/gen.nvim',
}
