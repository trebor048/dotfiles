#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

clear
# ===== Banner =====
echo -e "\e[1;32m=========================================="
echo -e "        XMRig Termux Installer"
echo -e "==========================================\e[0m"
sleep 1

echo -e "\e[1;33mPreparing installation...\e[0m"
sleep 1

# ----- Basic packages -----
pkg update -y && pkg upgrade -y
pkg install -y git cmake build-essential clang openssl curl

# ----- Clone or update XMRig -----
if [ -d "$HOME/xmrig" ]; then
  echo "Found existing xmrig directory. Pulling latest changes..."
  cd "$HOME/xmrig"
  git pull --rebase || { echo "Git pull failed."; exit 1; }
else
  echo "Cloning XMRig repository..."
  git clone https://github.com/xmrig/xmrig.git "$HOME/xmrig" || { echo "Failed to clone repository."; exit 1; }
  cd "$HOME/xmrig"
fi

# ----- Build XMRig -----
echo ""
echo "Building XMRig (this may take a while)..."
rm -rf build
mkdir -p build && cd build
cmake -DWITH_HWLOC=OFF ..
make -j"$(nproc)"

# ----- Optional menu (from original author) -----
echo ""
echo "Downloading helper menu..."
mkdir -p "$HOME/xmrig"
curl -fsSL -o "$HOME/xmrig/menu.sh" https://raw.githubusercontent.com/trebor048/dotfiles/main/menu.sh || echo "Could not download menu.sh (optional)."
[ -f "$HOME/xmrig/menu.sh" ] && chmod +x "$HOME/xmrig/menu.sh"

echo ""
echo -e "\e[1;32mInstallation complete!\e[0m"
echo "XMRig binary: $HOME/xmrig/build/xmrig"
echo "Run it directly, or start the optional menu (if downloaded) with:"
echo "bash ~/xmrig/menu.sh"
