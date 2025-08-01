set fish_greeting ""

set -gx EDITOR nvim

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

direnv hook fish | source

starship init fish | source

kubectl completion fish | source

op completion fish | source

abbr -a k kubectl
abbr -a kctx kubectl ctx
abbr -a kns kubectl ns
abbr -a g git
abbr -a gg ginkgo --race --cover --randomize-all -r .
abbr -a ggu ginkgo --race --cover --randomize-all -r . -- --update
abbr -a n nvim
abbr -a dc docker compose
abbr -a dcl docker compose logs --tail=10 -f
abbr -a t tmux-sessionizer
abbr -a ta tmux attach

# aichat
abbr -a ai aichat
abbr -a aig aichat -m gemini
abbr -a aid aichat -r dev:
abbr -a aix aichat -r expert:

abbr -a ficp fish_clipboard_copy

abbr -a act source .venv/bin/activate.fish
pyenv init - | source

abbr -a ns nix-shell -p fish

if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
alias claude="/home/efueyo/.claude/local/claude"
