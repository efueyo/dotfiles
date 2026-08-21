# dotfiles

My dotfiles and some utils

Some of the tools and configurations I use.

- Fish as the shell
- Starship as the shell prompt
- Wezterm as terminal
- Tmux
- Nvim

macOS desktop:

- AeroSpace as tiling window manager (the counterpart to Hyprland below)

Linux desktop (Wayland):

- Hyprland as window manager
- Waybar as status bar
- Rofi / Wofi as application launcher

## Install

`make install` only links config files (it never installs packages):

- **All platforms**: links the common configs (fish, nvim, wezterm, tmux,
  starship, direnv, bin, claude, ...).
- **macOS**: also links the AeroSpace config to
  `~/.config/aerospace/aerospace.toml`.
- **Linux**: also links the Wayland desktop configs (Hyprland, Waybar, Wofi,
  Rofi) and you can install fonts with `./etc/fonts.sh`.

Packages are opt-in. On a supported macOS, `make brew` runs `brew bundle`
against the `Brewfile`. On older/unsupported macOS (no Homebrew bottles)
install the tools manually instead — `make install` keeps the configs in sync
either way.

## AeroSpace (macOS tiling)

`aerospace/aerospace.toml` mirrors the Hyprland keymap, with one substitution:
Hyprland's `SUPER` becomes `alt` (Option), because `Cmd` is load-bearing on
macOS. Workspace switching stays on `ctrl + 1-9`, exactly as on Linux.

| Action | Hyprland | AeroSpace |
| --- | --- | --- |
| Focus | `SUPER + hjkl` / arrows | `alt + hjkl` / arrows |
| Move window | — | `alt-shift + hjkl` / arrows |
| Terminal | `SUPER + RETURN` | `alt + enter` |
| Close window | `SUPER + C` | `alt + q` |
| Toggle floating | `SUPER + V` | `alt + v` |
| Workspace 1-10 | `CTRL + 0-9` | `ctrl + 0-9` |
| Move to workspace | `CTRL-SHIFT + 1-8` | `ctrl-shift + 1-8` |
| Scratchpad | `SUPER + S` | `alt + s` (workspace `S`) |
| Disable tiling | `SUPER + M` (exit) | `alt-shift + space` |
| Service mode | — | `alt-shift + ;` then `esc`/`r`/`f` |

`alt-e`, `alt-i`, `alt-n`, `alt-u` and `alt-backtick` are deliberately left
unbound: they are the macOS dead keys for `´ ˆ ˜ ¨ \``, and AeroSpace grabs
hotkeys globally without distinguishing left from right Option — binding them
would break accented input system-wide.

After `make brew && make install`, grant AeroSpace **Accessibility**
permission in System Settings → Privacy & Security → Accessibility. Without it
AeroSpace launches but cannot move windows.
