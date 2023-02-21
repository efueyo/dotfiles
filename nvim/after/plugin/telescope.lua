local status_ok, _ = pcall(require, 'telescope')
if not status_ok then
  return
end


local function nmap(keys, func, desc)
  vim.keymap.set('n', keys, func, { desc = desc })
end

local builtin = require('telescope.builtin')
local user_telescope = require('user.telescope')
local themes = require('telescope.themes')
nmap('<leader>ff', builtin.find_files, '[F]ind [F]ile')
nmap('<leader>fg', builtin.git_files, '[F]ind [G]it files')
nmap('<leader>?', builtin.oldfiles, '[?] Find recently opened files')
nmap('<leader>fs', builtin.live_grep, '[F]ind [S]earch term')
nmap('<leader>fb', user_telescope.buffers, '[F]ind [B]uffers')
nmap('<leader>fd', builtin.diagnostics, '[F]ind [D]iagnostics')
nmap('<leader>fh', builtin.help_tags, '[F]ind [H]elp')
nmap('<leader>gc', user_telescope.git_branches, '[G]it [B]ranches')
nmap('<leader>/', function()
  builtin.current_buffer_fuzzy_find(themes.get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, '[/] Fuzzily search in current buffer]')

