set fish_greeting ""

set -gx EDITOR nvim

# Go
set -g GOPATH $HOME/go
set -gx PATH /usr/local/go/bin $PATH
set -gx PATH $GOPATH/bin $PATH
set -gx PATH ~/bin $PATH

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
abbr -a glog git log --graph --pretty=format:'%Cred%h%Creset - %an -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative
abbr -a gg ginkgo --race --cover --randomize-all -r .
abbr -a ggu ginkgo --race --cover --randomize-all -r . -- --update
abbr -a n nvim
abbr -a dc docker compose
abbr -a dcl docker compose logs --tail=10 -f


if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

