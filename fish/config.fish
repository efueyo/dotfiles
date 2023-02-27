set fish_greeting ""

set -gx EDITOR nvim

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH


starship init fish | source
