#!/usr/bin/env bash

set -uo pipefail

# Absolute path to this dotfiles checkout, regardless of where ONA cloned it.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;34m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles] WARN:\033[0m %s\n' "$*" >&2; }

# sudo only if we're not already root and sudo exists.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
  warn "no sudo available; package installation may be skipped"
fi

# ----------------------------------------------------------------------------
# 1. Packages (Linux/apt only — macOS uses the Brewfile via \`make brew\`).
# ----------------------------------------------------------------------------
install_packages() {
  if [ "$(uname -s)" != "Linux" ]; then
    log "non-Linux host detected; skipping apt packages (use 'make brew' on macOS)"
    return 0
  fi
  if ! command -v apt-get >/dev/null 2>&1; then
    warn "apt-get not found; skipping package install"
    return 0
  fi

  log "installing apt packages (tmux, ripgrep, fzf, direnv, build tools)…"
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y -qq || warn "apt-get update failed"
  # build-essential is needed for nvim-treesitter to compile parsers.
  $SUDO apt-get install -y -qq \
    tmux ripgrep fzf direnv build-essential curl ca-certificates \
    || warn "some apt packages failed to install"

  # eza (modern ls) — available in noble's universe repo; best-effort.
  if ! command -v eza >/dev/null 2>&1; then
    $SUDO apt-get install -y -qq eza 2>/dev/null \
      || warn "eza not available via apt; skipping (only used by ls aliases)"
  fi
}

# ----------------------------------------------------------------------------
# 2. Neovim — install a current stable build (noble's apt nvim lags behind what
#    lazy.nvim + recent plugins expect). Pinned configs deserve a modern nvim.
# ----------------------------------------------------------------------------
install_neovim() {
  if [ "$(uname -s)" != "Linux" ]; then
    command -v nvim >/dev/null 2>&1 || warn "install neovim manually on this host"
    return 0
  fi
  if command -v nvim >/dev/null 2>&1 && [ -x /opt/nvim/bin/nvim ]; then
    log "neovim already installed ($(/opt/nvim/bin/nvim --version | head -1))"
    return 0
  fi

  local arch asset url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64)          asset="nvim-linux-x86_64" ;;
    aarch64|arm64)   asset="nvim-linux-arm64" ;;
    *) warn "unsupported arch '$arch' for neovim release; skipping"; return 0 ;;
  esac
  url="https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz"
  tmp="$(mktemp -d)"

  log "downloading neovim ($asset)…"
  if curl -fsSL "$url" -o "$tmp/nvim.tar.gz"; then
    $SUDO rm -rf "/opt/${asset}" /opt/nvim
    $SUDO tar -xzf "$tmp/nvim.tar.gz" -C /opt
    $SUDO ln -sfn "/opt/${asset}" /opt/nvim
    log "neovim installed to /opt/nvim"
  else
    warn "neovim download failed; falling back to apt"
    $SUDO apt-get install -y -qq neovim || warn "apt neovim install failed too"
  fi
  rm -rf "$tmp"
}

# ----------------------------------------------------------------------------
# 3. starship prompt — official installer to /usr/local/bin (best-effort).
# ----------------------------------------------------------------------------
install_starship() {
  if command -v starship >/dev/null 2>&1; then
    log "starship already installed"
    return 0
  fi
  if [ "$(uname -s)" != "Linux" ]; then
    warn "install starship manually on this host"
    return 0
  fi
  log "installing starship…"
  curl -fsSL https://starship.rs/install.sh \
    | $SUDO sh -s -- --yes >/dev/null 2>&1 \
    || warn "starship install failed (prompt will fall back to default)"
}

# ----------------------------------------------------------------------------
# 4. Symlink configs. Only the ones that make sense in a remote CDE.
# ----------------------------------------------------------------------------
link() {
  # link <source-relative-to-dotfiles> <target-absolute>
  local src="$DOTFILES_DIR/$1" dst="$2"
  if [ ! -e "$src" ]; then
    warn "source missing, skipping: $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  ln -snf "$src" "$dst"
  log "linked $dst -> $src"
}

link_configs() {
  link nvim                 "$HOME/.config/nvim"
  link tmux/.tmux.conf      "$HOME/.tmux.conf"
  link starship/starship.toml "$HOME/.config/starship.toml"
  link direnv               "$HOME/.config/direnv"
  link bin                  "$HOME/bin"
  link .rgignore            "$HOME/.rgignore"

  # Personal Claude Code agents/commands (repo also ships its own .claude/).
  link claude/agents        "$HOME/.claude/agents"
  link claude/commands      "$HOME/.claude/commands"

  # Global gitignore (cheap, useful).
  link .gitignore           "$HOME/.gitignore"
  git config --global core.excludesfile "$HOME/.gitignore" 2>/dev/null || true
}

# ----------------------------------------------------------------------------
# 5. bash integration. We append a marked, idempotent block — never edit the
#    repo's /etc/bash.bashrc (that's where shell-env.sh is sourced).
# ----------------------------------------------------------------------------
BEGIN_MARK="# >>> dotfiles (ona) >>>"
END_MARK="# <<< dotfiles (ona) <<<"

bashrc_block() {
  cat <<'EOF'
# >>> dotfiles (ona) >>>
# Personal bash setup for ONA/Gitpod. Layered ON TOP of the repo's
# /etc/bash.bashrc (which sources scripts/dev/shell-env.sh for PATH).
export EDITOR=nvim
export VISUAL=nvim
_pathprepend() { case ":$PATH:" in *":$1:"*) ;; *) [ -d "$1" ] && PATH="$1:$PATH";; esac; }
_pathprepend "$HOME/bin"
_pathprepend "$HOME/.local/bin"
_pathprepend "/opt/nvim/bin"
export PATH
unset -f _pathprepend
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v direnv   >/dev/null 2>&1 && eval "$(direnv hook bash)"
# Auto-attach to a tmux session on interactive login (mirrors fish config.fish).
case $- in
  *i*)
    if [ -z "$TMUX" ] && command -v tat >/dev/null 2>&1; then
      tat
    fi
    ;;
esac
# <<< dotfiles (ona) <<<
EOF
}

append_block() {
  # append_block <file>
  local file="$1"
  touch "$file"
  if grep -qF "$BEGIN_MARK" "$file" 2>/dev/null; then
    log "bash block already present in $file"
    return 0
  fi
  printf '\n%s\n' "$(bashrc_block)" >> "$file"
  log "added bash block to $file"
}

setup_bash() {
  append_block "$HOME/.bashrc"

  # SSH login shells read ~/.bash_profile (or ~/.profile), NOT ~/.bashrc.
  # Ensure our block runs there too by sourcing ~/.bashrc from the login files.
  local bridge='[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
  if [ -f "$HOME/.bash_profile" ]; then
    grep -qF "$bridge" "$HOME/.bash_profile" 2>/dev/null \
      || printf '\n%s\n' "$bridge" >> "$HOME/.bash_profile"
  else
    grep -qF "$bridge" "$HOME/.profile" 2>/dev/null \
      || printf '\n%s\n' "$bridge" >> "$HOME/.profile"
  fi
}

# ----------------------------------------------------------------------------
# 6. tmux theme. .tmux.conf loads catppuccin directly via `run` (no tpm —
#    tmux-sensible and vim-tmux-navigator are inlined in the config). We pin to an
#    immutable commit SHA rather than a branch or tag, so a future upstream
#    compromise can't reach the CDE without an explicit bump here.
# ----------------------------------------------------------------------------
CATPPUCCIN_SHA="b2f219c00609ea1772bcfbdae0697807184743e4"  # v2.1.3

install_tmux_theme() {
  if ! command -v git >/dev/null 2>&1; then
    warn "git not found; skipping catppuccin tmux theme"
    return 0
  fi

  local dir="$HOME/.config/tmux/plugins/catppuccin/tmux"
  if [ -d "$dir/.git" ]; then
    log "catppuccin tmux already installed"
    return 0
  fi

  log "installing catppuccin tmux theme (pinned ${CATPPUCCIN_SHA})…"
  mkdir -p "$(dirname "$dir")"
  if git clone -q https://github.com/catppuccin/tmux.git "$dir" \
     && git -C "$dir" checkout -q "$CATPPUCCIN_SHA"; then
    log "catppuccin tmux installed at ${CATPPUCCIN_SHA}"
  else
    warn "catppuccin tmux install failed; status bar theme will be missing"
    rm -rf "$dir"
  fi
}

# ----------------------------------------------------------------------------
# 7. (Optional) pre-sync neovim plugins so the first real launch is instant.
#    Guarded with a timeout and made non-fatal; lazy.nvim also auto-installs
#    on first interactive launch, so failure here is harmless.
# ----------------------------------------------------------------------------
sync_neovim() {
  local nvim_bin
  nvim_bin="$(command -v nvim 2>/dev/null || echo /opt/nvim/bin/nvim)"
  [ -x "$nvim_bin" ] || return 0
  log "pre-syncing neovim plugins (best-effort)…"
  timeout 120 "$nvim_bin" --headless "+Lazy! sync" +qa >/dev/null 2>&1 \
    || warn "nvim plugin pre-sync skipped/incomplete (will finish on first launch)"
}

main() {
  log "installing dotfiles from $DOTFILES_DIR"
  install_packages
  install_neovim
  install_starship
  link_configs
  setup_bash
  install_tmux_theme
  sync_neovim
  log "done. Open a new shell (or 'source ~/.bashrc') to pick up changes."
}

main "$@"
