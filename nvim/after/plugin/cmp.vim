if !exists('g:loaded_cmp') | finish | endif

set completeopt=menu,menuone,noselect

lua <<EOF
  -- Setup nvim-cmp.
  require("user.cmp")
EOF
