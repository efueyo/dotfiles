local options = {
  ignorecase = false,
  number = true,
  relativenumber = true,
  mouse = "a",
  syntax="enable",
  fileencodings= "utf-8,latin",
  encoding="utf-8",
  title=true,
  autoindent=true,
  smartindent=true,
  background="dark",
  backup=false,
  hlsearch=true,
  showcmd=true,
  cmdheight=1,
  updatetime=250,
  scrolloff=10,
  expandtab=true,
  inccommand="split",
  ruler=false,
  showmatch=false,
  -- Don't redraw while executing macros (good performance config)
  lazyredraw=true,
  smarttab=true,
  shiftwidth=2,
  tabstop=2,
  wrap=false,
  backspace="start,eol,indent",
  list = true,
  listchars="tab:▸·,trail:·",
  wildmode="longest,list,full",
  wildmenu=true,

  cursorline = true,

  laststatus=3,
  winbar="%=%m %f %n", -- aligned to the right + isModified + filename + buf number
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.cmd [[set wildignore+=*.pyc]]
vim.cmd [[set wildignore+=*_build/*]]
vim.cmd [[set wildignore+=**/coverage/*]]
vim.cmd [[set wildignore+=**/node_modules/*]]
vim.cmd [[set wildignore+=**/.git/*]]
