set fish_greeting ""

set -gx EDITOR nvim

# z plugin
set -g Z_DATA $HOME/.local/share/z/data
set -g Z_DATA_DIR $HOME/.local/share/z
set -g Z_EXCLUDE '^'$HOME'$'

# Go
set -g GOPATH $HOME/go
set -gx PATH /usr/local/go/bin $PATH
set -gx PATH $GOPATH/bin $PATH
set -gx PATH ~/bin $PATH

# Rust
set -gx PATH $HOME/.cargo/bin $PATH

# Poetry
set -gx PATH $HOME/.local/bin $PATH

# Krew
set -gx PATH $HOME/.krew/bin $PATH

if not test $TMUX
  tat
end

if type -q direnv
  direnv hook fish | source
end

if type -q starship
  starship init fish | source
end

if type -q kubectl
  kubectl completion fish | source
end

if type -q op
  op completion fish | source
end

abbr -a k kubectl
abbr -a kctx kubectl ctx
abbr -a kns kubectl ns
abbr -a g git
abbr -a gwa git worktree add
abbr -a gwl git worktree list
abbr -a gwr git worktree remove
abbr -a gg ginkgo --race --cover --randomize-all -r .
abbr -a ggu ginkgo --race --cover --randomize-all -r . -- --update
abbr -a n nvim
abbr -a dc docker compose
abbr -a dcl docker compose logs --tail=10 -f
abbr -a t tmux-sessionizer
abbr -a ta tmux attach
abbr -a cc claude

abbr -a ficp fish_clipboard_copy

abbr -a act source .venv/bin/activate.fish
# pyenv
set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH
if type -q pyenv
  pyenv init - | source
end

abbr -a ns nix-shell -p fish

if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
