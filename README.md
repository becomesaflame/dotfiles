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
$ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 
```

If tmux is running, source conf with:
```
$ tmux source ~/.tmux.conf
```

Press prefix + I to install plugins

If there's no internet:
```
$ cp -r /git/dotfiles/.tmux/ ~
```


### Set up vim plugged:
```
$ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
```
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

Reload .vimrc and :PlugInstall to install plugins.

If there's no internet:
```
$ cp -r /git/dotfiles/.vim ~
```
