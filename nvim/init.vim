" Fundamentals "{{{
" ---------------------------------------------------------------------

" init autocmd
autocmd!

"}}}

" Highlights "{{{
" ---------------------------------------------------------------------

augroup BgHighlight
  autocmd!
  autocmd WinEnter * set cul
  autocmd WinLeave * set nocul
augroup END


"}}}

" File types "{{{
" ---------------------------------------------------------------------
augroup Filetypes
  autocmd!
  " JavaScript
  au BufNewFile,BufRead *.es6 setf javascript
  " TypeScript
  au BufNewFile,BufRead *.tsx setf typescriptreact
  " Markdown
  au BufNewFile,BufRead *.md set filetype=markdown
  au BufNewFile,BufRead *.mdx set filetype=markdown
  " Go
  au BufNewFile,BufRead *.go set filetype=go
  autocmd FileType go setlocal noexpandtab shiftwidth=8 tabstop=8
  " insert if err != nil {...} and return to insert mode
  autocmd FileType go inoremap iferr  <cmd>GoIfErr<cr><esc>2kA
  autocmd FileType go nnoremap <leader>ga <cmd>GoAlternate<cr>

  autocmd FileType yaml setlocal shiftwidth=2 tabstop=2
  autocmd FileType floggraph nnoremap <leader>cc <cmd>call flog#copy_commits()<cr>
  autocmd BufWritePre * %s/\s\+$//e
augroup END
"}}}

" Imports "{{{
" ---------------------------------------------------------------------
runtime ./plug.vim

lua <<EOF
require("user.options")
require("user.keymaps")
EOF
"" runtime ./maps.vim
runtime ./colors.vim

"}}}

" Extras "{{{
" ---------------------------------------------------------------------
"}}}
" vim: set foldmethod=marker foldlevel=0:
