.PHONY: install
.SILENT: install
install:
	echo "------- Vim -------"
	echo "Linking vim/.vimrc to ~/.vimrc"
	ln -s -f $(CURDIR)/vim/.vimrc ~/.vimrc || true
	echo "Linking vim/coc-settings.json to ~/.vim/coc-settings.json"
	ln -s -f $(CURDIR)/vim/coc-settings.json ~/.vim/coc-settings.json || true
	echo "------- tmux -------"
	echo "Linking .tmux.conf to ~/.tmux.conf"
	ln -s -f $(CURDIR)/tmux/.tmux.conf ~/.tmux.conf || true
	echo "------- .gitignore -------"
	echo "Linking .gitignore to ~/.gitignore"
	ln -s -f $(CURDIR)/.gitignore ~/.gitignore || true
	echo "Configuring git global ~/.gitignore"
	git config --global core.excludesfile ~/.gitignore || true
	echo "------- Neovim -------"
	echo "Linking nvim to ~/.config/nvim"
	ln -s -f $(CURDIR)/nvim ~/.config/nvim || true
	echo "Linking .rgignore to ~/.rgignore"
	ln -s -f $(CURDIR)/.rgignore ~/.rgignore || true
	echo "Linking bin/tat to ~/bin/tat"
	ln -s -f $(CURDIR)/bin/tat ~/bin/tat || true
	echo "Linking bin/list_instances to ~/bin/list_instances"
	ln -s -f $(CURDIR)/bin/list_instances ~/bin/list_instances || true
	echo "Linking bin/add_my_ip_to_sec_group to ~/bin/add_my_ip_to_sec_group"
	ln -s -f $(CURDIR)/bin/add_my_ip_to_sec_group ~/bin/add_my_ip_to_sec_group || true

