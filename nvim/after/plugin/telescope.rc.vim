if !exists('g:loaded_telescope') | finish | endif
"
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope git_files<cr>
nnoremap <leader>fs <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fr <cmd>Telescope lsp_references theme=dropdown layout_config={width=0.8}<cr>
nnoremap <leader>fi <cmd>Telescope lsp_implementations theme=dropdown layout_config={width=0.8}<cr>
nnoremap <leader>fts <cmd>Telescope treesitter<cr>
nnoremap <leader>gc :lua require('efueyo.telescope').git_branches()<cr>

