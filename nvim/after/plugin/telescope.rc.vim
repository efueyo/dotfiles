if !exists('g:loaded_telescope') | finish | endif

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope git_files<cr>
nnoremap <leader>fs <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fr <cmd>lua require'telescope.builtin'.lsp_references{}<CR>

lua << EOF
function telescope_buffer_dir()
  return vim.fn.expand('%:p:h')
end

local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup{
  defaults = {
    layout_config = { height = 0.9, width = 0.9 },
    mappings = {
      i = {
        ["qq"] = actions.close
      },
      n = {
        ["q"] = actions.close
      },
    },
  }
}
EOF
