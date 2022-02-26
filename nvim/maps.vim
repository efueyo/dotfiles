" Description: Keymaps
nnoremap <SPACE> <Nop>
let mapleader = "\<space>" " map leader to space

" --- Some useful maps
" yank from cursor
nnoremap Y yg$
" keep the screen centered while searching
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z

" move lines
vnoremap - :m '>+1<CR>gv=gv
vnoremap _ :m '<-2<CR>gv=gv
nnoremap - :m .+1<cr>==
nnoremap _ :m .-2<cr>==

" Delete without yank
nnoremap <leader>d "_d
nnoremap <leader>D "_D
nnoremap x "_x

" delete a single line when in insert mode
inoremap <c-d> <esc>ddi
" break undo sequence when inserting this characters
inoremap . .<c-g>u
inoremap , ,<c-g>u

inoremap jk <esc>

""" -------------------- Add closing elements on insert more  --------------------
inoremap " ""<left>
" Avoid writing four elements when typed twice"
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

" move between windows
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l
nnoremap <leader>h <C-w>h


" mappins for NERDTree
let g:NERDTreeShowHidden=1
noremap <leader>nt <cmd>NERDTreeToggle<cr>
noremap <leader>ntf <cmd>NERDTreeFind<cr>
let NERDTreeQuitOnOpen=1 " Automatically close NERDTree when you open a file
"
""" -------------------- Config for SymbolsOutline  --------------------
map <leader>so :SymbolsOutline<CR>
