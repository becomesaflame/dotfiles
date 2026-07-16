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

### Set up dotfiles auto-commit:
Daily systemd timer that commits and pushes any changes in this repo, using
an LLM to write the commit message. Details/gotchas in
`notes/dotfiles-autocommit.md`. Assumes this repo is checked out at
`~/dotfiles` (the script hardcodes that path).

Symlink the systemd units in:
```
mkdir -p ~/.config/systemd/user
ln -sf ~/dotfiles/systemd/dotfiles-autocommit.service ~/.config/systemd/user/dotfiles-autocommit.service
ln -sf ~/dotfiles/systemd/dotfiles-autocommit.timer ~/.config/systemd/user/dotfiles-autocommit.timer
```

Set up the API key(s) - this file is **not** part of the repo (kept out on
purpose so a key can never get committed):
```
cp ~/dotfiles/systemd/dotfiles-autocommit.env.example ~/.config/dotfiles-autocommit.env
chmod 600 ~/.config/dotfiles-autocommit.env
# then edit ~/.config/dotfiles-autocommit.env and fill in a real key
```

Enable the timer:
```
systemctl --user daemon-reload
systemctl --user enable --now dotfiles-autocommit.timer
```

Trigger a run manually to confirm it works: `systemctl --user start dotfiles-autocommit.service`
