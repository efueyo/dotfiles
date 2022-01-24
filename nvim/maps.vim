" Description: Keymaps
nnoremap <SPACE> <Nop>
let mapleader = "\<space>" " map leader to space

" --- Some useful maps
" move line down
nnoremap - ddp
" move line up
nnoremap _ ddkP
" Delete without yank
nnoremap <leader>d "_d
nnoremap x "_x

" delete a single line when in insert mode
inoremap <c-d> <esc>ddi

nnoremap <Left> <nop>
nnoremap <Right> <nop>
nnoremap <Up> <nop>
nnoremap <Down> <nop>

vnoremap <Left> <nop>
vnoremap <Right> <nop>
vnoremap <Up> <nop>
vnoremap <Down> <nop>

inoremap jk <esc>
inoremap <esc> <nop>

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

" Commands for lsp
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> <C-n> <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> <C-p> <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

" mappins for NERDTree
let g:NERDTreeShowHidden=1
noremap <leader>nt <cmd>NERDTreeToggle<cr>
noremap <leader>ntf <cmd>NERDTreeFind<cr>
let NERDTreeQuitOnOpen=1 " Automatically close NERDTree when you open a file
