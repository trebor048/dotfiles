#!/bin/bash
set -euo pipefail

clear
echo -e "\e[1;32m=========================================="
echo -e "         XMRig Installer (Linux)"
echo -e "==========================================\e[0m"
sleep 1

echo -e "\e[1;33mPreparing installation...\e[0m"
sleep 1

# --- Packages ---
sudo apt update
sudo apt install -y git curl cmake build-essential clang libssl-dev libhwloc-dev libuv1-dev automake autoconf libtool pkg-config

# --- Clone XMRig (fresh or update) ---
if [ -d "$HOME/xmrig/.git" ]; then
  echo "Found existing xmrig repo. Pulling latest..."
  git -C "$HOME/xmrig" pull --rebase
else
  echo "Cloning XMRig repository..."
  git clone --depth=1 https://github.com/xmrig/xmrig.git "$HOME/xmrig"
fi

cd "$HOME/xmrig" || { echo "xmrig directory not found."; exit 1; }

# --- Build XMRig ---
echo ""
echo "Building XMRig (this may take a while)..."
rm -rf build
mkdir -p build && cd build
cmake -DWITH_HWLOC=OFF ..
make -j"$(nproc)"

# --- Optional helper menu from trebor048/dotfiles ---
echo ""
echo "Downloading helper menu (optional)..."
mkdir -p "$HOME/xmrig"
# Adjusted repo to trebor048/dotfiles (English)
curl -fsSL -o "$HOME/xmrig/menu.sh" "https://raw.githubusercontent.com/trebor048/dotfiles/main/menu.sh" || echo "Could not download menu.sh (optional)."
[ -f "$HOME/xmrig/menu.sh" ] && chmod +x "$HOME/xmrig/menu.sh"

# --- Add handy alias to .bashrc ---
if ! grep -q "alias menu=" "$HOME/.bashrc"; then
  echo "alias menu='bash \$HOME/xmrig/menu.sh'" >> "$HOME/.bashrc"
  echo "Alias 'menu' added to .bashrc"
else
  echo "Alias 'menu' already present in .bashrc"
fi

echo ""
echo -e "\e[1;32mInstallation complete.\e[0m"
echo "XMRig binary: $HOME/xmrig/build/xmrig"
echo "Run it directly, or start the optional menu with:  menu"

