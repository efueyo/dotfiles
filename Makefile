.PHONY: install
.SILENT: install
install:
	echo "------- Vim -------"
	echo "Linkning vim/.vimrc to ~/.vimrc"
	ln -s $(CURDIR)/vim/.vimrc ~/.vimrc || true
	echo "Linkning vim/coc-settings.json to ~/.vim/coc-settings.json"
	ln -s $(CURDIR)/vim/coc-settings.json ~/.vim/coc-settings.json || true
	echo "------- .gitignore -------"
	echo "Linkning .gitignore to ~/.gitignore"
	ln -s $(CURDIR)/.gitignore ~/.gitignore || true
	echo "Configuring git global ~/.gitignore"
	git config --global core.excludesfile ~/.gitignore || true
