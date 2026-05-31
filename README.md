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

`make install` only links config files (it never installs packages):

- **All platforms**: links the common configs (fish, nvim, wezterm, tmux,
  starship, direnv, bin, claude, ...).
- **Linux**: also links the Wayland desktop configs (Hyprland, Waybar, Wofi,
  Rofi) and you can install fonts with `./etc/fonts.sh`.

Packages are opt-in. On a supported macOS, `make brew` runs `brew bundle`
against the `Brewfile`. On older/unsupported macOS (no Homebrew bottles)
install the tools manually instead — `make install` keeps the configs in sync
either way.
