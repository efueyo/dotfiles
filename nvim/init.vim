" Fundamentals "{{{
" ---------------------------------------------------------------------

" init autocmd
autocmd!
" set script encoding
scriptencoding utf-8
" stop loading config if it's on tiny or small
if !1 | finish | endif

set nocompatible
set number
set relativenumber
syntax enable
set fileencodings=utf-8,sjis,euc-jp,latin
set encoding=utf-8
set title
set autoindent
set background=dark
set nobackup
set hlsearch
set showcmd
set cmdheight=1
set updatetime=250
" Always display the status line, even if only one window is displayed
set laststatus=2
set scrolloff=10
set expandtab
"let loaded_matchparen = 1

" incremental substitution (neovim)
if has('nvim')
  set inccommand=split
endif

" Suppress appending <PasteStart> and <PasteEnd> when pasting
set t_BE=

set noruler
set noshowmatch
" Don't redraw while executing macros (good performance config)
set lazyredraw
"set showmatch
" How many tenths of a second to blink when matching brackets
"set mat=2
" Ignore case when searching
set noignorecase
" Be smart when using tabs ;)
set smarttab
" indents
filetype plugin indent on
set shiftwidth=2
set tabstop=2
set ai "Auto indent
set si "Smart indent
set nowrap "No Wrap lines
set backspace=start,eol,indent
" display tabs and whitespaces
set list
set listchars=tab:▸·,trail:·,eol:⏎
" Finding files - Search down into subfolders
set path+=**
set wildmode=longest,list,full
set wildmenu
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/android/*
set wildignore+=**/.git/*


"}}}

" Highlights "{{{
" ---------------------------------------------------------------------
set cursorline
"set cursorcolumn

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
  autocmd FileType go inoremap iferr  <ESC><Plug>(go-iferr)2ki
  autocmd FileType go nnoremap <leader>ga <cmd>GoAlternate<cr>

  autocmd FileType yaml setlocal shiftwidth=2 tabstop=2
  autocmd FileType floggraph nnoremap <leader>cc <cmd>call flog#copy_commits()<cr>
augroup END
"}}}

" Imports "{{{
" ---------------------------------------------------------------------
runtime ./plug.vim
if has("unix")
  let s:uname = system("uname -s")
  " Do Mac stuff
  if s:uname == "Darwin\n"
    runtime ./macos.vim
  endif
endif

runtime ./maps.vim
runtime ./colors.vim
"}}}

" Extras "{{{
" ---------------------------------------------------------------------
"}}}
" vim: set foldmethod=marker foldlevel=0:
