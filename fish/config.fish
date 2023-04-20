set fish_greeting ""

set -gx EDITOR nvim

# Go
set -g GOPATH $HOME/go
set -gx PATH /usr/local/go/bin $PATH
set -gx PATH $GOPATH/bin $PATH
set -gx PATH ~/bin $PATH

if not test $TMUX
  tat
end

direnv hook fish | source

starship init fish | source

kubectl completion fish | source

abbr -a k kubectl
abbr -a g git
abbr -a gg ginkgo --race --cover --randomize-all -r .
abbr -a ggu ginkgo --race --cover --randomize-all -r . -- --update
abbr -a n nvim


if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

