vim.keymap.set('n', '<leader>gl',  function ()
  vim.cmd "G log --graph --pretty=format:'%h - %an -%d %s (%cr)' --abbrev-commit --date=relative --all"
end, { desc = 'Nice [G]it [l]og' })
