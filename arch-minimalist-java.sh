#!/bin/bash
set -euo pipefail

echo "🛠️ Installing base packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel git curl wget openssh sudo

echo "🔌 Enabling and starting SSH server..."
sudo systemctl enable --now sshd

echo "🛠️ Installing yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
else
    echo "✅ yay already installed"
fi

echo "📦 Installing development packages with yay..."
yay -S --noconfirm \
    jdk-openjdk jre-openjdk maven gradle \
    neovim \
    nodejs npm python python-pip \
    fzf ripgrep fd bat exa tmux \
    man-db man-pages \
    reflector \
    ufw fail2ban

echo "🧠 Bootstrapping Neovim kickstart config..."
if [[ ! -d "$HOME/.config/nvim" ]]; then
    git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    echo "✅ Kickstart.nvim installed"
else
    echo "⚠️ Neovim config already exists at ~/.config/nvim"
fi

echo "🔧 Setting up firewall..."
sudo ufw allow ssh
sudo ufw enable
sudo systemctl enable --now ufw

echo "✅ System bootstrap complete!"
