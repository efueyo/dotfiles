#! /bin/bash
mkdir -p $HOME/.local/share/fonts
cd $HOME/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip
unzip FiraCode.zip
sudo dnf -y install redhat-*fonts*
fc-cache -f -v

