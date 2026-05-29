#! /bin/bash
if [ "$(uname -s)" != "Linux" ]; then
  echo "fonts.sh only supports Linux. On macOS the font is installed via the Brewfile (font-fira-code-nerd-font)."
  exit 0
fi
mkdir -p $HOME/.local/share/fonts
cd $HOME/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip
unzip FiraCode.zip
sudo dnf -y install redhat-*fonts*
fc-cache -f -v
