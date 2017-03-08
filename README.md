# dotfiles
My configuration files - bash, vim, etc

Link files to repo e.g. 
$ ln -s /git/dotfiles/.vimrc ~/.vimrc

Set up home vs work git config:
$ ln -s /git/dotfiles/.gitconfig.local.work ~/.gitconfig.local


### Set up tpm (tmux plugin manager): 
$ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 

If tmux is running, source conf with:
$ tmux source ~/.tmux.conf

Press prefix + I to install plugins

If there's no internet:
$ cp -r /git/dotfiles/.tmux/plugins ~/.tmux/

