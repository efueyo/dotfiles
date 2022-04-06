function telescope_buffer_dir()
  return vim.fn.expand('%:p:h')
end

local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup{
  defaults = {
    layout_config = { height = 0.9, width = 0.9 },
    color_devicons = true,
    mappings = {
      i = {
        ["qq"] = actions.close,
        ["<C-q>"] = actions.send_to_qflist,
      },
      n = {
        ["q"] = actions.close,
      },
    },
  },
  pickers = {
    live_grep = {
      additional_args = function(opts)
        return {"--hidden"}
      end
    },
  }
}
telescope.load_extension('fzy_native')

local M = {}
M.git_branches = function()
	require("telescope.builtin").git_branches({
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


return M