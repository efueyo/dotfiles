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
	echo "------- binaries -------"
	ln -snf $(CURDIR)/.rgignore ~/.rgignore || true
	ln -snf $(CURDIR)/bin/tat ~/bin/tat || true
	ln -snf $(CURDIR)/bin/list_instances ~/bin/list_instances || true
	ln -snf $(CURDIR)/bin/add_my_ip_to_sec_group ~/bin/add_my_ip_to_sec_group || true
	ln -snf $(CURDIR)/bin/ec2_connect ~/bin/ec2_connect || true
	ln -snf $(CURDIR)/bin/op_add_user ~/bin/op_add_user || true
	ln -snf $(CURDIR)/bin/op_view_item ~/bin/op_view_item || true

