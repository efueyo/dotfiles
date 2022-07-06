.PHONY: install
.SILENT: install
install:
	echo "------- Vim -------"
	echo "Linking vim/.vimrc to ~/.vimrc"
	ln -s $(CURDIR)/vim/.vimrc ~/.vimrc || true
	echo "Linking vim/coc-settings.json to ~/.vim/coc-settings.json"
	ln -s $(CURDIR)/vim/coc-settings.json ~/.vim/coc-settings.json || true
	echo "------- .gitignore -------"
	echo "Linking .gitignore to ~/.gitignore"
	ln -s $(CURDIR)/.gitignore ~/.gitignore || true
	echo "Configuring git global ~/.gitignore"
	git config --global core.excludesfile ~/.gitignore || true
	echo "------- Neovim -------"
	echo "Linking nvim to ~/.config/nvim"
	ln -s $(CURDIR)/nvim ~/.config/nvim || true
	echo "Linking .rgignore to ~/.rgignore"
	ln -s $(CURDIR)/.rgignore ~/.rgignore || true
	echo "Linking bin/tat to ~/bin/tat"
	ln -s $(CURDIR)/bin/tat ~/bin/tat || true
	echo "Linking bin/list_instances to ~/bin/list_instances"
	ln -s $(CURDIR)/bin/list_instances ~/bin/list_instances || true

