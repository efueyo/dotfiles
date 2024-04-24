local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

local formatting = null_ls.builtins.formatting

null_ls.setup({
	debug = false,
	sources = {
		formatting.prettier.with({
			extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"yaml",
				"css",
				"scss",
				"less",
				"html",
				"jsonc",
				"markdown",
				"graphql",
				"handlebars",
			},
		}),
		-- formatting.eslint_d.with({
		-- 	filetypes = {
		-- 		"javascript",
		-- 		"javascriptreact",
		-- 		"typescript",
		-- 		"typescriptreact",
		-- 	},
		-- 	prefer_local = "node_modules/.bin",
		-- }),
		formatting.stylua,
		formatting.terraform_fmt,
	},
})
