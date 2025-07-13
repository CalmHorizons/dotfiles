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
    jdk-openjdk maven gradle \
    neovim \
    nodejs npm python python-pip \
    fzf ripgrep fd bat exa tmux \
    man-db man-pages \
    reflector

echo "🧠 Bootstrapping Neovim kickstart config..."
if [[ ! -d "$HOME/.config/nvim" ]]; then
    git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    echo "✅ Kickstart.nvim installed"
else
    echo "⚠️ Neovim config already exists at ~/.config/nvim"
fi


echo "✅ System bootstrap complete!"


################OH MY POST ###################################

echo "🎨 Installing oh-my-posh and setting powerline theme..."
yay -S --noconfirm oh-my-posh

# Create theme directory under ~/.config
mkdir -p ~/.config/oh-my-posh
cp /usr/share/oh-my-posh/themes/powerline.omp.json ~/.config/oh-my-posh/
chmod 644 ~/.config/oh-my-posh/powerline.omp.json

# Add oh-my-posh init to .bashrc if not already present
if ! grep -q "oh-my-posh init" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# ── oh-my-posh Prompt ────────────────────────────────
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/powerline.omp.json)"
EOF
fi

################ALIASES ###################################

echo "🧩 Adding common bash aliases..."
cat << 'EOF' >> ~/.bashrc

# ── Custom Dev Aliases ───────────────────────────────
alias ll='exa -al --git'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias cat='bat'
alias grep='rg'
alias cd..='cd ..'
EOF



