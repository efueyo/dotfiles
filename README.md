# dotfiles

My dotfiles and some utils

Some of the tools and configurations I use.

- Fish as the shell
- Starship as the shell prompt
- Wezterm as terminal
- Tmux
- Nvim

Linux desktop (Wayland):

- Hyprland as window manager
- Waybar as status bar
- Rofi / Wofi as application launcher

## Install

`make install` detects the OS and links the common configs, then:

- **macOS**: runs `brew bundle` to install packages from the `Brewfile`. The
  Nerd Font is installed as a cask, so there's no font step.
- **Linux**: links the Wayland desktop configs (Hyprland, Waybar, Wofi, Rofi).
  Install the fonts with `./etc/fonts.sh`.

Run `make brew` to (re)install Homebrew packages only.
