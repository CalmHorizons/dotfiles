#!/bin/bash
set -euo pipefail

echo "🛠️ Updating system and installing base packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel git curl wget unzip openssh sudo stylua

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
    jdk-openjdk maven gradle jdtls \
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

echo "🛠️ Configuring Neovim to auto-install jdtls via Mason..."
mkdir -p ~/.config/nvim/lua/custom/plugins

cat > ~/.config/nvim/lua/custom/plugins/mason-lspconfig.lua <<'EOF'
return {
  "williamboman/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "jdtls",
    },
  },
}
}
EOF

echo "📦 Triggering Neovim plugin sync..."
nvim --headless "+Lazy! sync" +qa

echo "🔧 Exporting TERM variable for full terminal support..."
if ! grep -q "export TERM=xterm-256color" ~/.bashrc; then
    echo 'export TERM=xterm-256color' >> ~/.bashrc
fi

echo "🖌️ Installing Oh My Posh with powerline theme..."

if ! command -v oh-my-posh &> /dev/null; then
    yay -S --noconfirm oh-my-posh
fi

mkdir -p ~/.config/oh-my-posh
curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerline.omp.json -o ~/.config/oh-my-posh/powerline.omp.json

# Add to .bashrc if not already there
if ! grep -q "eval \"\$(oh-my-posh init bash --config ~/.config/oh-my-posh/powerline.omp.json)\"" ~/.bashrc; then
    echo 'eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/powerline.omp.json)"' >> ~/.bashrc
fi

echo "🛠️ Adding useful aliases to ~/.bashrc..."
cat >> ~/.bashrc <<'ALIAS_EOF'

# Custom Aliases
alias ll='ls -lha --color=auto'
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gl='git log --oneline --graph --decorate'

ALIAS_EOF

echo "✅ Bootstrap complete! Please restart your terminal or run 'source ~/.bashrc'"




echo "[*] Installing TPM (Tmux Plugin Manager)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "[✓] TPM already installed."
fi

echo "[*] Writing ~/.tmux.conf with Catppuccin theme..."
cat > ~/.tmux.conf <<EOF
# Set prefix to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload config with prefix + r
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# TPM plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'catppuccin/tmux'

# Catppuccin flavor: mocha, frappe, latte, macchiato
set -g @catppuccin_flavour 'mocha'

# Initialize TPM
run '~/.tmux/plugins/tpm/tpm'
EOF

echo "[*] Starting tmux to install plugins via TPM..."
tmux new-session -d -s temp_session
sleep 1
tmux send-keys -t temp_session "tmux source-file ~/.tmux.conf" C-m
tmux send-keys -t temp_session "~/.tmux/plugins/tpm/bin/install_plugins" C-m
sleep 2
tmux kill-session -t temp_session

echo "[✓] Done. Start tmux with: tmux"

