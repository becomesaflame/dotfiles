# Cat with context highlighting
# requires Pygments for Python (pip install pygments)
alias pcat="pygmentize -O style-native -g"

# Override ls aliases
alias ll="ls -lAh"
alias la="ls -lAh"

# Autocomplete options
bind "set completion-ignore-case on"
# bind "set show-all-if-ambiguous on"

# Ruby rbenv shim
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
