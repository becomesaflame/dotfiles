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

# takes submodule name as argument
# If submodule loaded properly, copies it into a backup with ".offline" appended
backupSubmodule(){
  submoduleDir="$1"
  if [ "$(ls -A $submoduleDir)" ]; then # submodule has files in it
    # Update the offline backup
    rm -r $submoduleDir.offline
    cp -r $submoduleDir $submoduleDir.offline
  fi
}


# Parse args
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -l|--locale)
      locale="$2"
      shift # past argument
      shift # past parameter
      ;;
    -p|--platform)
      echo "args are $@"
      platform="$2"
      shift # past argument
      shift # past parameter
      ;;
    *) #default
      usage
      ;;
  esac
  if [ "$locale" != "work" ] && [ "$locale" != "home" ]; then
    echo "Invalid locale $locale.  Locale may be \"home\" or \"work\"."
    exit 1
  fi
  if [ "$platform" != "linux" ] && [ "$platform" != "windows" ]; then
    echo "Invalid platform $platform.  Platform may be \"linux\" or \"windows\"."
    exit 1
  fi
done

##########################
# Dotfiles
##########################

# Set up symbolic links in home directory
echo "-----------------------------"
echo "Installing dotfiles"
echo "-----------------------------"
rootDir=$(pwd)
ln -s $rootDir/.bashrc ~/.bashrc
ln -s $rootDir/.vimrc ~/.vimrc
ln -s $rootDir/.gitconfig ~/.gitconfig
ln -s $rootDir/.tmux.conf ~/.tmux.conf


# Set up locale files
echo "-----------------------------"
echo "Installing locale files"
echo "-----------------------------"
if [ "$locale" == "work" ]; then 
  ln -s "$rootDir/.bashrc.local.work.$platform" ~/.bashrc.local
  ln -s "$rootDir/.gitconfig.local.work.$platform" ~/.gitconfig.local
else
  ln -s "$rootDir/.bashrc.local.home" ~/.bashrc.local
  ln -s "$rootDir/.gitconfig.local.home" ~/.gitconfig.local
fi

ln -s "$rootDir/.vimrc.local.$locale" ~/.vimrc.local


#########################
# Plugins and tools
#########################

# Set up vim plugged
echo "-----------------------------"
echo "Installing vim plugged"
echo "-----------------------------"
# Attempt to set up vim plugged the normal way
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
internet=$?
echo "internet = $internet"

# Use offline backup if curl failed
if [ "$internet" != 0 ]; then
  cp -r $rootDir/.vim/ ~
fi

echo "-----------------------------"
echo "Installing vim-sensible"
echo "-----------------------------"
backupSubmodule "vim-sensible"
# update offline .vim folder
rm -r $rootdir/.vim/plugged/vim-sensible
cp -r vim-sensible.offline $rootdir/.vim/plugged/vim-sensible


echo "Reload .vimrc and :PlugInstall to install vim plugins."

# Install tmux
chmod +x tmux_local_install.sh
echo "-----------------------------"
echo "Installing tmux"
echo "-----------------------------"
which tmux >/dev/null 2>&1 || ./tmux_local_install.sh

# Set up tpm (tmux plugin manager)
if [ "$internet" != 0 ]; then
  cp -r $rootDir/.tmux/ ~
else
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "In tmux, enter prefix + I to install plugins"


# Set up tldr
echo "-----------------------------"
echo "Installing tldr"
echo "-----------------------------"
backupSubmodule "raylee-tldr"
[ -d ~/bin ] || mkdir ~/bin
cp -r raylee-tldr.offline/tldr ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH

if [ "$internet" != 0 ]; then
  cp -r .config ~
else
  [ -d ~/.config ] || mdkir ~/.config
  tldr -c
  cp -r ~/.config/tldr/index.json .config/tldr/ # Update offline backup with latest tldr config
fi


# Set up diff-so-fancy
echo "-----------------------------"
echo "Installing diff-so-fancy"
echo "-----------------------------"
backupSubmodule "diff-so-fancy"
[ -d ~/bin ] || mkdir ~/bin
cp -r diff-so-fancy.offline/third_party/build_fatpackdiff-so-fancy ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH


# Set up fzf
echo "-----------------------------"
echo "Installing fzf"
echo "-----------------------------"
backupSubmodule "fzf-portable"
cd fzf-portable.offline
chmod +x install
which fzf >/dev/null 2>&1 || ./install --all --no-fish --no-zsh
cd -
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH


# Remind user to check in updates to backups
git update-index --refresh
if ! git diff-index --quiet HEAD --; then # There are uncommitted changes
  echo "Backup files have been updated. Commit and push them"
  echo
fi
