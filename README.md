# dotfiles
My configuration files - bash, vim, etc

Link files to repo e.g. 
```
ln -s /git/dotfiles/.vimrc ~/.vimrc
```

Set up home vs work git config:
```
ln -s /git/dotfiles/.gitconfig.local.work ~/.gitconfig.local
```
If symlinks don't work (e.g. in cygwin), create a .gitconfig that points here:
```
[include]
  path = /c/git/dotfiles/.gitconfig
```


### Set up tpm (tmux plugin manager): 
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 
```

If tmux is running, source conf with:
```
tmux source ~/.tmux.conf
```

Press prefix + I to install plugins

If there's no internet:
```
cp -r /git/dotfiles/.tmux/ ~
```


### Set up vim plugged:
```
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
```
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

Reload .vimrc and :PlugInstall to install plugins.

If there's no internet:
```
cp -r /git/dotfiles/.vim ~
```

### Set up tldr:
```
[ -d "~/bin" ] || mkdir ~/bin
cp raylee-tldr/tldr ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH
```
If there is an internet connection, run `tldr -c` to cache commands
Otherwise copy or link  `.config` to home directory:
`cp .config ~`

### Set up diff-so-fancy:
Copy the diff-so-fancy executeable to your path:
```
[ -d "~/bin" ] || mkdir ~/bin
cp diff-so-fancy/diff-so-fancy ~/bin/
source ~/.bashrc # assuming that .bashrc adds ~/bin to PATH
```
