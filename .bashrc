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

# fzf completion overrides git with path completion; restore branch completion
restore_git_bash_completion() {
  [[ $- == *i* ]] || return 0
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  else
    return 0
  fi
  complete -r git 2>/dev/null || true
  if type _comp_load &>/dev/null; then
    _comp_load git 2>/dev/null || true
  elif [ -f /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
  fi
}
restore_git_bash_completion

# venv alias
alias venv='python3 -m venv .venv && source .venv/bin/activate'

# Add local bin to path
PATH="$HOME/bin:$PATH"
PATH="$HOME/local/bin:$PATH"

[ -e ~/.local/bin/env ] && source ~/.local/bin/env

# Set prompt
if [[ $- == *i* ]]; then
  export PS1="\[\033[38;5;40m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;6m\][\[$(tput sgr0)\]\[\033[38;5;15m\]\[$(tput sgr0)\]\[\033[38;5;87m\]\w\[$(tput sgr0)\]\[\033[38;5;6m\]]:\[$(tput sgr0)\]\[\033[38;5;15m\] \n\\$\[$(tput sgr0)\]"
  export PROMPT_DIRTRIM=3
fi

# Run local bash settings
[ -e ~/.bashrc.local ] && source ~/.bashrc.local

