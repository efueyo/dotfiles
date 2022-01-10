" Set 'nocompatible' to ward off unexpected things that your distro might
" have made, as well as sanely reset options when re-sourcing .vimrc
set nocompatible

" Attempt to determine the type of a file based on its name and possibly
"  its
" contents. Use this to allow intelligent auto-indenting for each filetype,
" and for plugins that are filetype specific.
filetype indent plugin on

" Enable syntax highlighting
syntax on

"set spell spelllang=en_us

" Better command-line completion
set wildmenu
" Show partial commands in the last line of the screen
set showcmd
" Highlight searches (use <C-L> to temporarily turn off highlighting; see the
" mapping of <C-L> below)
set hlsearch
" show search results as you type
set incsearch

" Display the cursor position on the last line of the screen or in the status
" line of a window
set ruler

" Always display the status line, even if only one window is displayed
set laststatus=2

" Set the command window height to 2 lines, to avoid many cases of having to
" "press <Enter> to continue"
set cmdheight=2

" Display line numbers on the left
set number
" Display relative number
set relativenumber

set expandtab
set shiftwidth=2
set softtabstop=2
autocmd FileType python setlocal shiftwidth=4 tabstop=4

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

call vundle#end()            " required
filetype plugin indent on    " required

Plugin 'scrooloose/nerdtree'
Plugin 'xuyuanp/nerdtree-git-plugin'
Plugin 'neoclide/coc.nvim'
Plugin 'josa42/coc-go', {'do': 'yarn install --frozen-lockfile'}
Plugin 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
Plugin 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
Plugin 'fannheyward/coc-pyright', {'do': 'yarn install --frozen-lockfile'}

Plugin 'morhetz/gruvbox'
Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plugin 'junegunn/fzf.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'leafgarland/typescript-vim'

""" -------------------- Config for vim-go  -------------------- 
" disable all linters as that is taken care of by coc.nvim
" let g:go_diagnostics_enabled = 0
" let g:go_metalinter_enabled = []

" don't jump to errors after metalinter is invoked
let g:go_jump_to_error = 0

" run go imports on file save
let g:go_fmt_command = "goimports"

" automatically highlight variable your cursor is on
let g:go_auto_sameids = 0
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1

" create custom mappings for Go files
autocmd BufEnter *.go nmap <leader>t  <Plug>(go-test)
autocmd BufEnter *.go nmap <leader>tt <Plug>(go-test-func)
autocmd BufEnter *.go nmap <leader>c  <Plug>(go-coverage-toggle)
autocmd BufEnter *.go nmap <leader>i  <Plug>(go-info)
autocmd BufEnter *.go nmap <leader>ii  <Plug>(go-implements)
autocmd BufEnter *.go nmap <leader>ci  <Plug>(go-describe)
autocmd BufEnter *.go nmap <leader>cc  <Plug>(go-callers)
autocmd BufEnter *.go nmap <leader>cs  <Plug>(go-callstack)
" insert if err != nil {...} and return to insert mode
autocmd BufEnter *.go imap iferr  <ESC><Plug>(go-iferr)2ki
nmap <leader>r <Plug>(coc-rename)

""" -------------------- Colors -------------------- 

colorscheme gruvbox
autocmd ColorScheme * highlight CocErrorFloat guifg=#ffffff
autocmd ColorScheme * highlight CocInfoFloat guifg=#ffffff
autocmd ColorScheme * highlight CocWarningFloat guifg=#ffffff
autocmd ColorScheme * highlight SignColumn guibg=#adadad
autocmd ColorScheme * highlight CocWarningSign guibg=#ffffff


""" -------------------- Add closing elements on insert more  -------------------- 
" Avoid writing four elements when typed twice"
inoremap " ""<left>
inoremap "" ""
inoremap ' ''<left>
inoremap '' ''
inoremap ( ()<left>
inoremap () ()
inoremap [ []<left>
inoremap [] []
inoremap { {}<left>
inoremap {} {}
inoremap {<CR> {<CR>}<ESC>O

" display tabs and whitespaces
set list
set listchars=tab:▸·,trail:·,eol:⏎

""" ------------------- custom commands ---------------------
" skip golden files
command GFilesNoGolden call fzf#run({'source': 'git ls-files | grep -v golden', 'sink': 'e'})

" leader+c to copy to clipboard from visual mode
vnoremap <leader>c "*y
