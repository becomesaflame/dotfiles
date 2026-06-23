#!/bin/bash
set -euo pipefail

# Pinned tool versions
DIFF_SO_FANCY_VERSION="v1.4.10"
TLDR_COMMIT="7d57134c2ab58eb5c906f31bdf695e653f5d128b"
NEOVIM_MIN_VERSION="0.11.0"

usage() {
  cmd=$(basename "$0")
  profiles=$(ls -1 profiles/)
  cat <<EOF

Automatically sets up symbolic links in the home directory.
Configures settings and plugins.

USAGE: ./$cmd [options]
$cmd [-p|--profile]
Specify an environment profile. Default: "default"
Available profiles:
$(printf '  %s\n' $profiles)

$cmd [-h|--help]
Print this help message

EOF
  exit 0
}

backupRoot=""

init_backup_root() {
  backupRoot="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
}

backup_dotfile() {
  local target="$1"
  local source="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi

  if [[ -L "$target" ]]; then
    local current
    current=$(readlink "$target")
    if [[ "$current" == "$source" ]]; then
      return 0
    fi
  fi

  local dest="$backupRoot$target"
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  echo "Backed up $target -> $dest"
}

link_dotfile() {
  local source="$1"
  local target="$2"
  backup_dotfile "$target" "$source"
  ln -sf "$source" "$target"
}

backup_file() {
  local target="$1"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi

  local dest="$backupRoot$target"
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  echo "Backed up $target -> $dest"
}

neovim_version() {
  command -v nvim >/dev/null 2>&1 || return 1
  nvim --version 2>/dev/null | sed -n 's/^NVIM v\([0-9.]*\).*/\1/p' | head -1
}

neovim_version_ok() {
  local current
  current=$(neovim_version) || return 1
  [[ "$(printf '%s\n' "$NEOVIM_MIN_VERSION" "$current" | sort -V | head -1)" == "$NEOVIM_MIN_VERSION" ]]
}

ensure_neovim() {
  echo "-----------------------------"
  echo "Checking Neovim (AstroNvim needs >= $NEOVIM_MIN_VERSION)"
  echo "-----------------------------"
  if neovim_version_ok; then
    echo "Neovim OK: v$(neovim_version)"
    return 0
  fi

  local current
  current=$(neovim_version || echo "not installed")
  echo "Neovim v$current is too old or missing."
  echo "Installing system Neovim (sudo required)..."
  sudo "$rootDir/install-neovim.sh"

  hash -r

  for cmd in nvim vim vi; do
    if [[ -L "$HOME/bin/$cmd" ]]; then
      rm -f "$HOME/bin/$cmd"
      echo "Removed user-local override: ~/bin/$cmd"
    fi
  done

  if neovim_version_ok; then
    echo "Neovim OK after install: v$(neovim_version)"
    return 0
  fi

  echo "Error: Neovim is still below $NEOVIM_MIN_VERSION after install." >&2
  echo "Check: vim --version | head -1" >&2
  exit 1
}

profile="default"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--profile)
      if [[ $# -lt 2 ]]; then
        echo "Error: --profile requires a value"
        exit 1
      fi
      profile="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")"
rootDir=$(pwd)

if [ ! -d "$rootDir/profiles/$profile" ]; then
  echo "Unknown profile \"$profile\". Available profiles:"
  ls -1 profiles/
  exit 1
fi

echo "Setting up with profile=$profile"
init_backup_root
echo "Existing dotfiles will be backed up under $backupRoot"

ensure_neovim

##########################
# Dotfiles
##########################

echo "-----------------------------"
echo "Installing dotfiles"
echo "-----------------------------"
link_dotfile "$rootDir/.bashrc" ~/.bashrc
link_dotfile "$rootDir/.vimrc" ~/.vimrc
link_dotfile "$rootDir/.gitconfig" ~/.gitconfig
link_dotfile "$rootDir/.tmux.conf" ~/.tmux.conf
mkdir -p ~/.config
link_dotfile "$rootDir/.config/nvim" ~/.config/nvim

echo "-----------------------------"
echo "Installing profile: $profile"
echo "-----------------------------"
for file in "$rootDir/profiles/$profile"/.*; do
  [ -f "$file" ] || continue
  link_dotfile "$file" "$HOME/$(basename "$file")"
done

#########################
# Plugins and tools
#########################

mkdir -p ~/bin
export PATH="$HOME/bin:$PATH"

echo "-----------------------------"
echo "Installing vim-plug"
echo "-----------------------------"
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo "Reload .vimrc and run :PlugInstall to install vim plugins."

echo "-----------------------------"
echo "Installing tmux"
echo "-----------------------------"
if command -v tmux >/dev/null 2>&1; then
  echo "tmux already installed: $(tmux -V)"
else
  echo "tmux not found. Install it with your package manager (e.g. sudo apt install tmux)."
fi

echo "-----------------------------"
echo "Installing tpm"
echo "-----------------------------"
if [ -d ~/.tmux/plugins/tpm ]; then
  echo "tpm already installed"
else
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
echo "In tmux, enter prefix + I to install plugins"

echo "-----------------------------"
echo "Installing tldr (commit ${TLDR_COMMIT:0:7})"
echo "-----------------------------"
tmpdir=$(mktemp -d)
git clone --quiet https://github.com/raylee/tldr-sh-client.git "$tmpdir/tldr-sh-client"
git -C "$tmpdir/tldr-sh-client" checkout --quiet "$TLDR_COMMIT"
cp "$tmpdir/tldr-sh-client/tldr" ~/bin/
chmod +x ~/bin/tldr
rm -rf "$tmpdir"

echo "-----------------------------"
echo "Installing diff-so-fancy $DIFF_SO_FANCY_VERSION"
echo "-----------------------------"
tmpdir=$(mktemp -d)
git clone --quiet --depth 1 --branch "$DIFF_SO_FANCY_VERSION" \
    https://github.com/so-fancy/diff-so-fancy.git "$tmpdir/diff-so-fancy"
cp "$tmpdir/diff-so-fancy/diff-so-fancy" ~/bin/
chmod +x ~/bin/diff-so-fancy
rm -rf "$tmpdir"

echo "-----------------------------"
echo "Installing bash-completion"
echo "-----------------------------"
if dpkg -l bash-completion 2>/dev/null | awk '{print $1}' | grep -qx ii; then
  echo "bash-completion already installed"
else
  sudo apt-get install -y bash-completion
fi

echo "-----------------------------"
echo "Installing fzf"
echo "-----------------------------"
if command -v fzf >/dev/null 2>&1; then
  echo "fzf already installed: $(fzf --version)"
else
  sudo apt-get install -y fzf
fi

backup_file ~/.fzf.bash
cat > ~/.fzf.bash <<'EOF'
# Setup fzf (apt package)
# Auto-generated by setup.sh
FZF_SHELL="/usr/share/doc/fzf/examples"

# Auto-completion
# ---------------
[[ $- == *i* ]] && [ -f "$FZF_SHELL/completion.bash" ] && source "$FZF_SHELL/completion.bash"

# Key bindings
# ------------
[ -f "$FZF_SHELL/key-bindings.bash" ] && source "$FZF_SHELL/key-bindings.bash"
EOF

echo "-----------------------------"
echo "Setup complete"
echo "-----------------------------"
if [[ -d "$backupRoot" ]]; then
  echo "Backups saved under $backupRoot"
fi
