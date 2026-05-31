.PHONY: install install-common install-linux brew
.SILENT: install install-common install-linux brew

UNAME := $(shell uname -s)

# `make install` only links config files. Package installation is opt-in via
# `make brew` (skipped by default — on unsupported macOS, brew has no bottles
# and would build everything from source).
install: install-common
ifneq ($(UNAME),Darwin)
	$(MAKE) install-linux
endif

install-common:
	mkdir -p ~/.config ~/.claude
	echo "------- WezTerm -------"
	ln -snf $(CURDIR)/wezterm ~/.config/wezterm || true
	echo "------- tmux -------"
	ln -snf $(CURDIR)/tmux/.tmux.conf ~/.tmux.conf || true
	echo "------- starship -------"
	ln -snf $(CURDIR)/starship/starship.toml ~/.config/starship.toml || true
	echo "------- .gitignore -------"
	ln -snf $(CURDIR)/.gitignore ~/.gitignore || true
	echo "Configuring git global ~/.gitignore"
	git config --global core.excludesfile ~/.gitignore || true
	echo "------- Neovim -------"
	ln -snf $(CURDIR)/nvim ~/.config/nvim || true
	echo "------- Fish -------"
	ln -snf $(CURDIR)/fish ~/.config/fish || true
	echo "------- direnv -------"
	ln -snf $(CURDIR)/direnv ~/.config/direnv || true
	echo "------- binaries -------"
	ln -snf $(CURDIR)/.rgignore ~/.rgignore || true
	ln -snf $(CURDIR)/bin ~/bin || true
	echo "------- Tridactyl -------"
	mkdir -p ~/.config/tridactyl || true
	ln -snf $(CURDIR)/tridactyl/tridactylrc ~/.config/tridactyl/tridactylrc || true
	echo "------- ClaudeCode -------"
	ln -snf $(CURDIR)/claude/agents ~/.claude/agents || true
	ln -snf $(CURDIR)/claude/commands ~/.claude/commands || true

install-linux:
	echo "------- Hyprland -------"
	ln -snf $(CURDIR)/hypr ~/.config/hypr || true
	echo "------- Waybar -------"
	ln -snf $(CURDIR)/waybar ~/.config/waybar || true
	echo "------- Wofi -------"
	ln -snf $(CURDIR)/wofi ~/.config/wofi || true
	echo "------- Rofi -------"
	ln -snf $(CURDIR)/rofi ~/.config/rofi || true

brew:
	echo "------- Homebrew bundle -------"
	brew bundle --file=$(CURDIR)/Brewfile
