#!/bin/bash
set -euo pipefail

# Install Neovim from the official release tarball to /usr/local and register
# update-alternatives. Ubuntu 24.04 apt ships 0.9.5; AstroNvim needs >= 0.11.
#
# Usage: sudo ./install-neovim.sh

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

NEOVIM_VERSION="${NEOVIM_VERSION:-v0.12.3}"
TARBALL="nvim-linux-x86_64.tar.gz"
URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${TARBALL}"
install_dir="/usr/local/nvim-${NEOVIM_VERSION#v}"
nvim_bin="$install_dir/bin/nvim"

remove_apt_neovim() {
  if dpkg -l neovim 2>/dev/null | awk '{print $1}' | grep -qx ii; then
    echo "Removing apt neovim (real /usr/bin/nvim blocks update-alternatives)..."
    apt-get remove -y neovim
  fi

  # Belt-and-suspenders: alternatives need a symlink slot, not a regular file.
  if [[ -e /usr/bin/nvim && ! -L /usr/bin/nvim ]]; then
    rm -f /usr/bin/nvim
  fi
}

remove_apt_neovim

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

echo "Downloading Neovim $NEOVIM_VERSION..."
curl -fsSL -o "$TARBALL" "$URL"
tar -xzf "$TARBALL"

rm -rf "$install_dir"
mv nvim-linux-x86_64 "$install_dir"
chmod -R a+rX "$install_dir"

echo "Installed $($nvim_bin --version | head -1) to $install_dir"

for cmd in nvim vim vi; do
  update-alternatives --install "/usr/bin/$cmd" "$cmd" "$nvim_bin" 60
  update-alternatives --set "$cmd" "$nvim_bin"
done

echo "Registered alternatives:"
update-alternatives --display nvim | sed -n '1,6p'
echo
echo "Done. Verify with:"
echo "  vim --version | head -1"
echo "  nvim --version | head -1"
