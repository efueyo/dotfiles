#!/usr/bin/env bash

set -uo pipefail

# Absolute path to this dotfiles checkout, regardless of where ONA cloned it.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;34m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles] WARN:\033[0m %s\n' "$*" >&2; }

# verify_sha256 <file> <expected-hex> — returns non-zero (and warns) on mismatch.
# Downloaded binaries below are pinned by content hash so a swapped/compromised
# release asset can't be installed without the pin here changing too.
verify_sha256() {
  local file="$1" want="$2" got
  if command -v sha256sum >/dev/null 2>&1; then
    got="$(sha256sum "$file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    got="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    warn "no sha256 tool found; refusing to install unverified $file"
    return 1
  fi
  if [ "$got" != "$want" ]; then
    warn "checksum mismatch for $(basename "$file"): got $got, want $want"
    return 1
  fi
}

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
#    lazy.nvim + recent plugins expect). Pinned to an exact version + checksum
#    (not 'latest') so the bytes don't change out from under a CDE rebuild.
#    Neovim publishes no checksum file, so these were captured by hand — bump the
#    version and both hashes together.
# ----------------------------------------------------------------------------
NEOVIM_VERSION="0.12.3"

install_neovim() {
  if [ "$(uname -s)" != "Linux" ]; then
    command -v nvim >/dev/null 2>&1 || warn "install neovim manually on this host"
    return 0
  fi
  if command -v nvim >/dev/null 2>&1 && [ -x /opt/nvim/bin/nvim ]; then
    log "neovim already installed ($(/opt/nvim/bin/nvim --version | head -1))"
    return 0
  fi

  local arch asset sha url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64)        asset="nvim-linux-x86_64"; sha="c441b547142860bf01bcce39e36cbed185c41112813e15443b16e5237750724d" ;;
    aarch64|arm64) asset="nvim-linux-arm64";  sha="e055af73fa9c72b37456da8d204fa5c09850bc07e80e9176fe3b87d4afb7a3fc" ;;
    *) warn "unsupported arch '$arch' for neovim release; skipping"; return 0 ;;
  esac
  url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${asset}.tar.gz"
  tmp="$(mktemp -d)"

  log "downloading neovim v${NEOVIM_VERSION} ($asset)…"
  if curl -fsSL "$url" -o "$tmp/nvim.tar.gz" && verify_sha256 "$tmp/nvim.tar.gz" "$sha"; then
    $SUDO rm -rf "/opt/${asset}" /opt/nvim
    $SUDO tar -xzf "$tmp/nvim.tar.gz" -C /opt
    $SUDO ln -sfn "/opt/${asset}" /opt/nvim
    log "neovim installed to /opt/nvim"
  else
    warn "neovim download/verify failed; falling back to apt"
    $SUDO apt-get install -y -qq neovim || warn "apt neovim install failed too"
  fi
  rm -rf "$tmp"
}

# ----------------------------------------------------------------------------
# 2b. tree-sitter CLI — nvim-treesitter's `main` branch compiles parsers by
#     shelling out to the `tree-sitter` binary (the old `master` branch used cc
#     directly, so build-essential alone was enough). noble's apt build is too
#     old, so grab the pinned release binary. `main` requires >= 0.26.1.
# ----------------------------------------------------------------------------
TREE_SITTER_VERSION="0.26.9"

install_tree_sitter() {
  if [ "$(uname -s)" != "Linux" ]; then
    command -v tree-sitter >/dev/null 2>&1 \
      || warn "install the tree-sitter CLI manually on this host ('brew install tree-sitter')"
    return 0
  fi
  if command -v tree-sitter >/dev/null 2>&1; then
    log "tree-sitter already installed ($(tree-sitter --version))"
    return 0
  fi

  local arch asset sha url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64)        asset="tree-sitter-linux-x64";   sha="ca9a7bf542473e956aab7d69e2154a60e4b4ac9f8eaf56f248692fc6d340efa4" ;;
    aarch64|arm64) asset="tree-sitter-linux-arm64"; sha="0dbc9e41f374a4310d560bcd6ff886dc9d23f40ba7b014ebb6df498f788a1505" ;;
    *) warn "unsupported arch '$arch' for tree-sitter release; skipping"; return 0 ;;
  esac
  url="https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/${asset}.gz"
  tmp="$(mktemp -d)"

  # sha is of the decompressed binary (no checksum file is published upstream), so
  # verify after gunzip and before placing it on PATH.
  log "downloading tree-sitter CLI v${TREE_SITTER_VERSION} ($asset)…"
  if curl -fsSL "$url" -o "$tmp/tree-sitter.gz" && gunzip -f "$tmp/tree-sitter.gz" \
     && verify_sha256 "$tmp/tree-sitter" "$sha"; then
    $SUDO install -m 0755 "$tmp/tree-sitter" /usr/local/bin/tree-sitter
    log "tree-sitter installed to /usr/local/bin/tree-sitter"
  else
    warn "tree-sitter CLI download/verify failed; nvim-treesitter parsers won't compile"
  fi
  rm -rf "$tmp"
}

# ----------------------------------------------------------------------------
# 3. starship prompt — pinned release binary verified against its published
#    .sha256, installed to /usr/local/bin. We deliberately avoid the upstream
#    `curl https://starship.rs/install.sh | sh` one-liner: that runs an unpinned
#    remote script as root. Bump the version + both hashes together.
# ----------------------------------------------------------------------------
STARSHIP_VERSION="1.25.1"

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    log "starship already installed"
    return 0
  fi
  if [ "$(uname -s)" != "Linux" ]; then
    warn "install starship manually on this host"
    return 0
  fi

  local arch asset sha url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64)        asset="starship-x86_64-unknown-linux-gnu";   sha="4488c11ca632327d1f1f16fb2f102c0646094c35479cd5435991385da43c61ac" ;;
    aarch64|arm64) asset="starship-aarch64-unknown-linux-musl"; sha="01517aab398959ea9ea73bdb4f032ea4dbb51dff5c8e5eb05b4a1b9b7ab872b8" ;;
    *) warn "unsupported arch '$arch' for starship release; skipping"; return 0 ;;
  esac
  url="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/${asset}.tar.gz"
  tmp="$(mktemp -d)"

  log "downloading starship v${STARSHIP_VERSION} ($asset)…"
  if curl -fsSL "$url" -o "$tmp/starship.tar.gz" && verify_sha256 "$tmp/starship.tar.gz" "$sha" \
     && tar -xzf "$tmp/starship.tar.gz" -C "$tmp"; then
    $SUDO install -m 0755 "$tmp/starship" /usr/local/bin/starship \
      && log "starship installed to /usr/local/bin/starship" \
      || warn "starship install failed (prompt will fall back to default)"
  else
    warn "starship download/verify failed (prompt will fall back to default)"
  fi
  rm -rf "$tmp"
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
# Personal aliases (fish abbreviations ported to bash).
alias n='nvim'
alias cc='claude'
alias g='git'
alias gwa='git worktree add'
alias gwl='git worktree list'
alias gwr='git worktree remove'
alias ta='tmux attach'
alias d='docker'
command -v eza >/dev/null 2>&1 && alias ll='eza -l -g --icons'
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
  install_tree_sitter
  install_starship
  link_configs
  setup_bash
  install_tmux_theme
  sync_neovim
  log "done. Open a new shell (or 'source ~/.bashrc') to pick up changes."
}

main "$@"
