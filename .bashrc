# Cat with context highlighting
# requires Pygments for Python (pip install pygments)
alias pcat="pygmentize -O style-native -g"

# Override ls aliases
alias ll="ls -lah --color"
alias la="ls -Ah --color"
alias ls="ls --color"

alias lt="find . -iname '*.txt'"

alias cp="cp -r"
alias rcp='rsync -rvz --info-progress2'

alias yeet="rm -rf"
alias :e="vim"
alias please=sudo

cl() { cd $1; ll; } 

# Autocomplete options
if [ -n "$PS1" ] ; then # Check if interactive shell
  bind "set completion-ignore-case on"
  # bind "set show-all-if-ambiguous on"
fi

# Ruby rbenv shim
if [ -d "$HOME/.rbenv/bin" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

# Start fuzzy finder
[ -e ~/.fzf.bash ] && source ~/.fzf.bash

# venv alias
alias venv='python3 -m venv .venv && source .venv/bin/activate'

# Add local bin to path
PATH="$HOME/bin:$PATH"
PATH="$HOME/local/bin:$PATH"

[ -e ~/.local/bin/env ] && source ~/.local/bin/env

# Run local bash settings
[ -e ~/.bashrc.local ] && source ~/.bashrc.local

