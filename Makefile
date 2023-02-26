.PHONY: install
.SILENT: install
install:
	echo "------- Vim -------"
	echo "Linking vim/.vimrc to ~/.vimrc"
	ln -snf $(CURDIR)/vim/.vimrc ~/.vimrc || true
	echo "Linking vim/coc-settings.json to ~/.vim/coc-settings.json"
	ln -snf $(CURDIR)/vim/coc-settings.json ~/.vim/coc-settings.json || true
	echo "------- Fish -------"
	echo "Linking fish to ~/.config/fish"
	ln -snf $(CURDIR)/fish ~/.config/fish || true
	echo "------- tmux -------"
	echo "Linking .tmux.conf to ~/.tmux.conf"
	ln -snf $(CURDIR)/tmux/.tmux.conf ~/.tmux.conf || true
	echo "------- .gitignore -------"
	echo "Linking .gitignore to ~/.gitignore"
	ln -snf $(CURDIR)/.gitignore ~/.gitignore || true
	echo "Configuring git global ~/.gitignore"
	git config --global core.excludesfile ~/.gitignore || true
	echo "------- Neovim -------"
	echo "Linking nvim to ~/.config/nvim"
	ln -snf $(CURDIR)/nvim ~/.config/nvim || true
	echo "Linking .rgignore to ~/.rgignore"
	ln -snf $(CURDIR)/.rgignore ~/.rgignore || true
	echo "Linking bin/tat to ~/bin/tat"
	ln -snf $(CURDIR)/bin/tat ~/bin/tat || true
	echo "Linking bin/list_instances to ~/bin/list_instances"
	ln -snf $(CURDIR)/bin/list_instances ~/bin/list_instances || true
	echo "Linking bin/add_my_ip_to_sec_group to ~/bin/add_my_ip_to_sec_group"
	ln -snf $(CURDIR)/bin/add_my_ip_to_sec_group ~/bin/add_my_ip_to_sec_group || true

