# Cat with context highlighting
# requires Pygments for Python (pip install pygments)
alias pcat="pygmentize -O style-native -g"

# Override ls aliases
alias ll="ls -lah --color"
alias la="ls -lAh --color"

alias lt="find . -iname '*.txt'"

alias cp="cp -r"

# Autocomplete options
bind "set completion-ignore-case on"
# bind "set show-all-if-ambiguous on"

# Ruby rbenv shim
if [ -d "$HOME/.rbenv/bin" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

# Start fuzzy finder
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Run local bash settings
[ -f .bashrc.local ] && source ~/.bashrc.local

