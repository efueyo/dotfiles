local telescope = require("telescope")
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

telescope.setup({
	defaults = {
		layout_config = { height = 0.9, width = 0.9 },
		color_devicons = true,
		mappings = {
			i = {
				["qq"] = actions.close,
				["<C-q>"] = actions.smart_send_to_qflist,
			},
			n = {
				["q"] = actions.close,
			},
		},
	},
	pickers = {
		live_grep = {
			additional_args = function(opts)
				return { "--hidden" }
			end,
		},
	},
})
telescope.load_extension("fzy_native")
telescope.load_extension("ui-select")

-- Only load mailman extension if available
local mailman_ok, _ = pcall(require, "mailman")
if mailman_ok then
  telescope.load_extension("mailman")
end

local M = {}
M.git_branches = function()
	builtin.git_branches({
		layout_config = {
			height = 0.6,
		},
		attach_mappings = function(_, map)
			map("i", "<c-d>", actions.git_delete_branch)
			map("n", "<c-d>", actions.git_delete_branch)
			return true
		end,
	})
end
M.buffers = function()
	builtin.buffers({
		attach_mappings = function(_, map)
			map("i", "<c-d>", actions.delete_buffer)
			map("n", "<c-d>", actions.delete_buffer)
			return true
		end,
	})
end

function M.live_multigrep(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local pieces = vim.split(prompt, "  ")
			local args = { "rg" }
			if pieces[1] then
				table.insert(args, "-e")
				table.insert(args, pieces[1])
			end

			if pieces[2] then
				table.insert(args, "-g")
				table.insert(args, pieces[2])
			end

			---@diagnostic disable-next-line: deprecated
			return vim.tbl_flatten({
				args,
				{
					"--color=never",
					"--hidden",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
			})
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})

	pickers
		.new(opts, {
			debounce = 100,
			prompt_title = "Multi Grep",
			finder = finder,
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
		})
		:find()
end

return M
