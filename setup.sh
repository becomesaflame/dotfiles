#!/bin/bash

usage() {
  cmd=$(basename $0)
  cat <<EOF
Automatically sets up symbolic links in the home directory.
Configures settings and plugins.
USAGE: ./$cmd [options]
$cmd [-l|--locale]
Specify a locale. 
Locale may be "home" or "work".  

$cmd [-p|--platform]
Specify a platform.
Platform may be "linux" or "windows".

$cmd [-h|--help]
Print this help message

EOF
exit 0
}


# Parse args
while [[ $# -gt 0 ]] do
  key="$1"

  case $key in
    -l|--locale)
      locale = "$2"
      if [ "$locale" -ne "work" ] || [ "$locale" -ne "home" ] then
        echo 'Invalid locale.  Locale may be "home" or "work".'
        exit 1
      fi
      shift # past argument
      shift # past parameter
      ;;
    -p|--platform)
      platform = "$2"
      if [ "$platform" -ne "work" ] || [ "$platform" -ne "home" ] then
        echo 'Invalid platform.  Platform may be "linux" or "windows".'
        exit 1
      fi
      shift # past argument
      shift # past parameter
      ;;
    *) #default
      usage
      ;;
  esac
done


# Set up symbolic links in home directory
ln -s .bashrc ~/.bashrc
ln -s .vimrc ~/.vimrc
ln -s .gitconfig ~/.gitconfig
ln -s .tmux.conf ~/.tmux.conf


# Set up locale files
if [ "$locale" -eq "work" ] then 
  ln -s ".vimrc.local.work" ~/.vimrc.local
  ln -s ".bashrc.local.work.$platform" ~/.bashrc.local
  ln -s ".gitconfig.local.work.$platform" ~/.gitconfig.local
else
  ln -s ".gitconfig.local.home" ~/.gitconfig.local
fi


# Set up vim plugged
internet = curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if [ "$internet" -ne 0 ] then
  cp -r /git/dotfiles/.tmux/ ~
fi

echo "Reload .vimrc and :PlugInstall to install vim plugins."


# Set up tpm (tmux plugin manager)
if [ "$internet" -ne 0 ] then
  cp -r /git/dotfiles/.tmux/ ~
else
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "In tmux, enter prefix + I to install plugins"


# Set up tldr
[ -d "~/bin" ] || mkdir ~/bin
cp raylee-tldr/tldr ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH

if [ "$internet" -ne 0 ] then
  cp .config ~
else
  tldr -c
fi


# Set up diff-so-fancy
[ -d "~/bin" ] || mkdir ~/bin
cp diff-so-fancy/diff-so-fancy ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH
