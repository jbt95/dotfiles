# Personal Dotfiles

My development environment configuration for macOS.

## Overview

This repository contains configuration files and scripts to set up a new MacBook for development.

## Contents

| File/Directory | Description |
| ---------------- | ------------- |
| `Brewfile` | Homebrew packages and VS Code extensions |
| `zsh/.zshrc` | Zsh shell configuration with aliases |
| `zsh/.zprofile` | Zsh login shell configuration |
| `git/.gitconfig` | Git configuration with personal email |
| `vscode/extensions.txt` | List of VS Code extensions |
| `ssh/config` | SSH configuration template |
| `ghostty/` | Ghostty terminal configuration |
| `opencode/` | Opencode AI assistant configuration |
| `.pi/` | Portable Pi settings, agents, prompts, skills, and MCP configuration |
| `install.sh` | Automated setup script |
| `sync-pi.sh` | Synchronizes mutable Pi settings without relying on fragile file symlinks |

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

   Then visit: <https://github.com/settings/keys>

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
   The installer preserves an existing config and creates a template only when
   none exists. Populate the local credential files documented in
   `opencode/README.md`.

5. **Configure Pi MCP credentials:**
   Create `~/.config/pi/mcp.zsh`, restrict it to the current user with
   `chmod 600`, and define these machine-local environment variables:
   `PI_MCP_ATLASSIAN_USER_EMAIL`, `PI_MCP_BITBUCKET_API_TOKEN`, and
   `PI_MCP_CONTEXT7_API_KEY`. The tracked Zsh configuration sources this
   private file; it must never be committed.

6. **Link the workspace ILC Pi extension:**
   When `~/work/ilc-agent-toolkit` exists, the installer links its tested Pi
   extension into `~/.pi/agent/extensions/`. The extension is globally loaded
   but activates its ILC tools and policies only for projects under `~/work`.
   Clone and build the toolkit first, then rerun this installer if it was not
   available during initial setup.

7. **Restart your terminal** or run:

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
- **OpenCode** - AI coding assistant with portable agents, commands, skills, and MCP configuration

### Productivity Tools

- **Raycast** - Spotlight replacement with powerful extensions
- **Contexts** - Fast window switcher with search capabilities
- **Rectangle** - Window tiling manager (snap windows to edges)

### Development & DevOps

- **Docker Desktop** - Container management and orchestration
- **Ghostty** - Fast, native GPU-accelerated terminal emulator with quick terminal feature

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

Most configs are symlinked, so repository edits are immediately active. Pi can
rewrite `settings.json` and `mcp.json` atomically, which would replace file-level
symlinks. Those two mutable files are regular copies managed explicitly:

```bash
cd ~/dotfiles
./sync-pi.sh status  # Compare live and repository copies
./sync-pi.sh pull    # Copy intentional live changes into this repository
./sync-pi.sh push    # Restore repository copies into ~/.pi
```

`pull` refuses to copy literal MCP credentials; tracked MCP authentication must
remain environment-variable based. Before replacing a changed live file,
`push` stores it under `~/.pi/backups/<timestamp>/`.

Validate Pi linking, backup, synchronization, and credential safeguards with:

```bash
./tests/pi-config.test.sh
```

After pulling intentional changes, review and commit them:

```bash
git diff
git add .
git commit -m "Update configs"
git push origin main
```

## Work vs Personal Differences

| Item | Work | Personal |
| ------ | ------ | ---------- |
| Git email | <j.bermejo@canda.com> | <berme495@gmail.com> |
| IDE | VS Code | VS Code + WebStorm |
| Terminal | iTerm | Ghostty |
| Spotlight | Default | Raycast |
| Window Switcher | Default | Contexts |
| Window Tiling | Default | Rectangle |
| Containers | Docker | Docker Desktop |
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
