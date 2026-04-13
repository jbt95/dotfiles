#!/bin/bash

# Dotfiles Installation Script for Personal MacBook
# This script sets up a new MacBook with development configurations

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

info "Starting dotfiles installation from: $DOTFILES_DIR"

# ============================================
# 1. Install Homebrew
# ============================================
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
else
    info "Homebrew already installed"
fi

# ============================================
# 2. Install packages from Brewfile
# ============================================
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    info "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
    success "Packages installed"
else
    warning "No Brewfile found"
fi

# ============================================
# 3. Install Oh My Zsh
# ============================================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed"
else
    info "Oh My Zsh already installed"
fi

# ============================================
# 4. Install Zsh plugins
# ============================================
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

info "Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
else
    info "zsh-autosuggestions already installed"
fi

info "Installing zsh-syntax-highlighting..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed"
else
    info "zsh-syntax-highlighting already installed"
fi

# ============================================
# 5. Create symlinks for dotfiles
# ============================================
info "Creating symlinks for dotfiles..."

# Backup existing files
backup_file() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then
        mv "$1" "$1.backup.$(date +%Y%m%d%H%M%S)"
        info "Backed up existing $1"
    fi
}

# Remove existing symlinks
remove_symlink() {
    if [ -L "$1" ]; then
        rm "$1"
    fi
}

# .zshrc
backup_file "$HOME/.zshrc"
remove_symlink "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
success "Linked .zshrc"

# .zprofile
backup_file "$HOME/.zprofile"
remove_symlink "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
success "Linked .zprofile"

# .gitconfig
backup_file "$HOME/.gitconfig"
remove_symlink "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
success "Linked .gitconfig"

# ============================================
# 6. Setup SSH directory and generate key
# ============================================
info "Setting up SSH directory..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Copy SSH config
if [ -f "$DOTFILES_DIR/ssh/config" ]; then
    cp "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    success "SSH config copied"
fi

# Generate new SSH key if it doesn't exist
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    info "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "berme495@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
    success "SSH key generated"
    warning "Add this key to GitHub: https://github.com/settings/keys"
    warning "Public key:"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    info "SSH key already exists"
fi

# ============================================
# 7. Install NVM
# ============================================
if [ ! -d "$HOME/.nvm" ]; then
    info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    success "NVM installed"
    warning "Restart your terminal and run 'nvm install node' to install Node.js"
else
    info "NVM already installed"
fi

# ============================================
# 8. Install Bun (optional)
# ============================================
if ! command -v bun &> /dev/null; then
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    success "Bun installed"
else
    info "Bun already installed"
fi

# ============================================
# 9. Setup pnpm
# ============================================
if ! command -v pnpm &> /dev/null; then
    info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    success "pnpm installed"
else
    info "pnpm already installed"
fi

# ============================================
# 10. Install VS Code Extensions
# ============================================
if command -v code &> /dev/null; then
    info "Installing VS Code extensions..."
    if [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
        while IFS= read -r extension; do
            if [ -n "$extension" ]; then
                info "Installing $extension..."
                code --install-extension "$extension" || warning "Failed to install $extension"
            fi
        done < "$DOTFILES_DIR/vscode/extensions.txt"
        success "VS Code extensions installed"
    fi
else
    warning "VS Code command not found. Please install VS Code first."
fi

# ============================================
# 11. Reload shell configuration
# ============================================
info "Reloading shell configuration..."
source "$HOME/.zshrc" 2>/dev/null || true

# ============================================
# Final Summary
# ============================================
echo ""
echo "==========================================="
echo "  Installation Complete!"
echo "==========================================="
echo ""
success "Your development environment is set up!"
echo ""
echo "Next steps:"
echo "  1. Add your SSH public key to GitHub:"
echo "     cat ~/.ssh/id_ed25519.pub"
echo "     https://github.com/settings/keys"
echo "  2. Restart your terminal"
echo "  3. Run: nvm install node"
echo "  4. (Optional) Generate GPG key for signed commits:"
echo "     gpg --full-generate-key"
echo "     git config --global commit.gpgsign true"
echo "     git config --global user.signingkey YOUR_KEY_ID"
echo ""
echo "Your dotfiles are symlinked from: $DOTFILES_DIR"
echo "To update configs, edit files in this directory."
echo ""
