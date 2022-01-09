.PHONY: install
.SILENT: install
install:
	echo "Linkning vim/.vimrc to ~/.vimrc"
	ln -s $(CURDIR)/vim/.vimrc ~/.vimrc
	echo "Linkning vim/coc-settings.json to ~/.vim/coc-settings.json"
	ln -s $(CURDIR)/vim/coc-settings.json ~/.vim/coc-settings.json


