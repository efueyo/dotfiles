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
	echo "------- binaries -------"
	ln -snf $(CURDIR)/.rgignore ~/.rgignore || true
	ln -snf $(CURDIR)/bin/tat ~/bin/tat || true
	ln -snf $(CURDIR)/bin/list_instances ~/bin/list_instances || true
	ln -snf $(CURDIR)/bin/add_my_ip_to_sec_group ~/bin/add_my_ip_to_sec_group || true

