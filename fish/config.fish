set fish_greeting ""

set -gx EDITOR nvim

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH
set -gx PATH ~/bin $PATH

direnv hook fish | source

starship init fish | source
