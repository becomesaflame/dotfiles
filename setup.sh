#!/bin/bash

# Script to automatically set up symbolic links in home directory


# Set up symbolic links in home directory
ln -s .bashrc ~/.bashrc
ln -s .vimrc ~/.vimrc
ln -s .gitconfig ~/.gitconfig
ln -s .tmux.conf ~/.tmux.conf

# Set up vim plugged
internet = curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if [ internet -ne 0 ] then
  cp -r /git/dotfiles/.tmux/ ~
fi

echo "Reload .vimrc and :PlugInstall to install vim plugins."

# Set up tpm (tmux plugin manager)
if [ internet -ne 0 ] then
  cp -r /git/dotfiles/.tmux/ ~
else
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "In tmux, enter prefix + I to install plugins"

# Set up tldr
[ -d "~/bin" ] || mkdir ~/bin
cp raylee-tldr/tldr ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH

if [ internet -ne 0 ] then
  cp .config ~
else
  tldr -c
fi


# Set up diff-so-fancy
[ -d "~/bin" ] || mkdir ~/bin
cp diff-so-fancy/diff-so-fancy ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH


## TODO
# Ask user for locale 
# - set up .bashrc.local
# - set up .gitconfig.local
