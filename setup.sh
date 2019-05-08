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
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -l|--locale)
      locale="$2"
      if [ "$locale" != "work" ] && [ "$locale" != "home" ]; then
        echo "Invalid locale $locale.  Locale may be \"home\" or \"work\"."
        exit 1
      fi
      shift # past argument
      shift # past parameter
      ;;
    -p|--platform)
      echo "args are $@"
      platform="$2"
      if [ "$platform" != "linux" ] && [ "$platform" != "windows" ]; then
        echo "Invalid platform $platform.  Platform may be \"linux\" or \"windows\"."
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
rootDir=$(pwd)
ln -s $rootDir/.bashrc ~/.bashrc
ln -s $rootDir/.vimrc ~/.vimrc
ln -s $rootDir/.gitconfig ~/.gitconfig
ln -s $rootDir/.tmux.conf ~/.tmux.conf


# Set up locale files
if [ "$locale" == "work" ]; then 
  ln -s "$rootDir/.vimrc.local.work" ~/.vimrc.local
  ln -s "$rootDir/.bashrc.local.work.$platform" ~/.bashrc.local
  ln -s "$rootDir/.gitconfig.local.work.$platform" ~/.gitconfig.local
else
  ln -s "$rootDir/.gitconfig.local.home" ~/.gitconfig.local
fi


# Set up vim plugged
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
internet=$?
echo "internet = $internet"

if [ "$internet" != 0 ]; then
  cp -r $rootDir/.vim/ ~
fi

echo "Reload .vimrc and :PlugInstall to install vim plugins."


# Set up tpm (tmux plugin manager)
if [ "$internet" != 0 ]; then
  cp -r $rootDir/.tmux/ ~
else
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "In tmux, enter prefix + I to install plugins"


# Set up tldr
[ -d ~/bin ] || mkdir ~/bin
cp raylee-tldr/tldr ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH

if [ "$internet" != 0 ]; then
  cp .config ~
else
  tldr -c
fi


# Set up diff-so-fancy
[ -d ~/bin ] || mkdir ~/bin
cp diff-so-fancy/diff-so-fancy ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH
