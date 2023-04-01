local telescope = require('telescope')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

telescope.setup{
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
        return {"--hidden"}
      end
    },
  }
}
telescope.load_extension('fzy_native')
telescope.load_extension('ui-select')

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
M.buffers = function ()
	builtin.buffers({
    attach_mappings = function (_, map)
      map("i", "<c-d>", actions.delete_buffer)
      map("n", "<c-d>", actions.delete_buffer)
      return true
    end
  })
end


return M
