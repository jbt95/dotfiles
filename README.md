# Personal Dotfiles

My development environment configuration for macOS.

## Overview

This repository contains configuration files and scripts to set up a new MacBook for development.

## Contents

| File/Directory | Description |
|----------------|-------------|
| `Brewfile` | Homebrew packages and VS Code extensions |
| `zsh/.zshrc` | Zsh shell configuration with aliases |
| `zsh/.zprofile` | Zsh login shell configuration |
| `git/.gitconfig` | Git configuration with personal email |
| `vscode/extensions.txt` | List of VS Code extensions |
| `ssh/config` | SSH configuration template |
| `opencode/` | Opencode AI assistant configuration |
| `install.sh` | Automated setup script |

## Quick Start

### 1. Clone this repository

```bash
cd ~
git clone git@github.com:jbt95/dotfiles.git
cd dotfiles
```

### 2. Run the install script

```bash
./install.sh
```

### 3. Post-installation steps

1. **Add SSH key to GitHub:**
   The install script generated a new SSH key. Add it to GitHub:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   Then visit: https://github.com/settings/keys

2. **Install Node.js:**
   ```bash
   nvm install node
   ```

3. **(Optional) Generate GPG key for signed commits:**
   ```bash
   gpg --full-generate-key
   git config --global commit.gpgsign true
   git config --global user.signingkey YOUR_KEY_ID
   ```

4. **Configure Opencode:**
   ```bash
   cp ~/dotfiles/opencode/opencode.json.template ~/.opencode/opencode.json
   # Edit the file and add your Fireworks AI API key
   ```

5. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

## What's Installed

### Homebrew Packages
- `git` - Version control
- `gnupg` - GPG for signing commits
- `openssh` - SSH client
- `ripgrep` - Fast search tool
- `maven` - Java build tool
- `openjdk` - Java SDK
- `tfenv` - Terraform version manager
- `terraform` - Infrastructure as Code

### Zsh Configuration
- Oh My Zsh with `robbyrussell` theme
- Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting
- Aliases for git, npm, docker, terraform, java, and more

### Development Tools
- **NVM** - Node version manager
- **pnpm** - Fast package manager
- **Bun** - JavaScript runtime
- **Docker** - Containerization (install Docker Desktop separately)
- **WebStorm** - JetBrains IDE for JavaScript/TypeScript
- **Opencode** - AI coding assistant (Fireworks AI powered)

### VS Code Extensions
- GitLens - Enhanced git capabilities
- GitHub Copilot - AI pair programming
- Terraform - HashiCorp Terraform support
- Java Extension Pack - Java development
- Error Lens - Inline error highlighting

## Customization

### Adding New Aliases

Edit `zsh/.zshrc` and add to the aliases section:
```bash
alias myalias='my command'
```

### Installing New VS Code Extensions

```bash
code --install-extension publisher.extension-name
echo "publisher.extension-name" >> vscode/extensions.txt
```

### Adding Homebrew Packages

Edit `Brewfile` and add:
```ruby
brew "package-name"
```

Then run:
```bash
brew bundle
```

## Maintenance

### Update all packages

```bash
brew update && brew upgrade
```

### Sync dotfiles changes

Since configs are symlinked, edits to files in this repo are immediately active. Commit and push changes:

```bash
cd ~/dotfiles
git add .
git commit -m "Update configs"
git push origin main
```

## Work vs Personal Differences

| Item | Work | Personal |
|------|------|----------|
| Git email | j.bermejo@canda.com | berme495@gmail.com |
| IDE | VS Code | VS Code + WebStorm |
| SSL certs | Zscaler corporate certs | None (standard) |
| VPN | Corporate VPN | Personal preference |
| AI tools | Work-authenticated | Personal accounts |

## Troubleshooting

### Permission denied when running install.sh
```bash
chmod +x install.sh
```

### Command not found after installation
Restart your terminal or run:
```bash
source ~/.zshrc
```

### Homebrew not found on Apple Silicon Mac
Add to `~/.zprofile`:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## License

Personal use only.
