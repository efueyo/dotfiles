.PHONY: install
.SILENT: install
install:
	echo "------- WezTerm -------"
	ln -snf $(CURDIR)/wezterm ~/.config/wezterm || true
	echo "------- tmux -------"
	ln -snf $(CURDIR)/tmux/.tmux.conf ~/.tmux.conf || true
	echo "------- starship -------"
	ln -snf $(CURDIR)/starship/starship.toml ~/.config/starship.toml || true
	echo "------- .gitignore -------"
	ln -snf $(CURDIR)/.gitignore ~/.gitignore || true
	echo "Configuring git global ~/.gitignore"
	git config --global core.excludesfile ~/.gitignore || true
	echo "------- Neovim -------"
	ln -snf $(CURDIR)/nvim ~/.config/nvim || true
	echo "------- Hyprland -------"
	ln -snf $(CURDIR)/hypr ~/.config/hypr || true
	echo "------- Kitty -------"
	ln -snf $(CURDIR)/kitty ~/.config/kitty || true
	echo "------- Waybar -------"
	ln -snf $(CURDIR)/waybar ~/.config/waybar || true
	echo "------- Wofi -------"
	ln -snf $(CURDIR)/wofi ~/.config/wofi || true
	echo "------- Swaylock -------"
	ln -snf $(CURDIR)/swaylock ~/.config/swaylock || true
	echo "------- Swayidle -------"
	ln -snf $(CURDIR)/swayidle ~/.config/swayidle || true
	echo "------- Rofi -------"
	ln -snf $(CURDIR)/rofi ~/.config/rofi || true
	echo "------- direnv -------"
	ln -snf $(CURDIR)/direnv ~/.config/direnv || true
	echo "------- binaries -------"
	ln -snf $(CURDIR)/.rgignore ~/.rgignore || true
	ln -snf $(CURDIR)/bin ~/bin || true
	echo "------- ClaudeCode -------"
	ln -snf $(CURDIR)/claude/agents ~/.claude/agents || true
	ln -snf $(CURDIR)/claude/commands ~/.claude/commands || true

