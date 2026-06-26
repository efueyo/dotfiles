return {
	{
		-- Highlight, edit, and navigate code.
		-- Tracks the `main` branch (the rewrite), which is required for Neovim
		-- 0.12+. The classic `require("nvim-treesitter.configs").setup` API lives
		-- on the old `master` branch and is incompatible with 0.12. Setup and
		-- keymaps live in `after/plugin/treesitter.lua`.
		--
		-- NOTE: upstream was archived (read-only) on 2026-04-03 after the 0.12
		-- rewrite, so there will be no further updates. The commit in
		-- lazy-lock.json is therefore intentionally pinned/frozen — it still works
		-- and compiles parsers via the `tree-sitter` CLI (installed by install.sh).
		-- Revisit only if a maintained successor emerges.
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
