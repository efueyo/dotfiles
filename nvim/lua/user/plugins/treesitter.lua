return {
	{
		-- Highlight, edit, and navigate code.
		-- Pinned to the legacy `master` branch: this config uses the classic
		-- `require("nvim-treesitter.configs").setup` API, which was removed on
		-- the new default `main` branch (the rewrite).
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = function()
			pcall(require("nvim-treesitter.install").update({ with_sync = true }))
		end,
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
		},
	},

	{
		"nvim-treesitter/playground",
		config = function()
			require("nvim-treesitter.configs").setup({})
		end,
	},
}
