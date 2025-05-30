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
	echo "------- Aichat -------"
	ln -snf $(CURDIR)/aichat ~/.config/aichat || true
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
	ln -snf $(CURDIR)/bin/tat ~/bin/tat || true
	ln -snf $(CURDIR)/bin/list_instances ~/bin/list_instances || true
	ln -snf $(CURDIR)/bin/add_my_ip_to_sec_group ~/bin/add_my_ip_to_sec_group || true
	ln -snf $(CURDIR)/bin/ec2_connect ~/bin/ec2_connect || true
	ln -snf $(CURDIR)/bin/op_add_user ~/bin/op_add_user || true
	ln -snf $(CURDIR)/bin/op_view_item ~/bin/op_view_item || true
	ln -snf $(CURDIR)/bin/tmux-sessionizer ~/bin/tmux-sessionizer || true

