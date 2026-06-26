return {
	{
		-- Highlight, edit, and navigate code.
		-- Tracks the `main` branch (the rewrite), which is required for Neovim
		-- 0.12+. The classic `require("nvim-treesitter.configs").setup` API lives
		-- on the old `master` branch and is incompatible with 0.12. Setup and
		-- keymaps live in `after/plugin/treesitter.lua`.
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
	},

	{
		-- `main` branch: select keymaps are bound manually in
		-- `after/plugin/treesitter.lua` (the classic `textobjects` module table
		-- was removed alongside the rest of the legacy API).
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}
