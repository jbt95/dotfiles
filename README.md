# Personal Dotfiles

Personal-only macOS configuration for a portable development workstation.

This repository contains neutral shell, Git, SSH, terminal, editor-extension,
OpenCode, Pi, and Oh My Pi preferences. Secrets, authentication stores,
runtime state, machine-specific paths, and work-only configuration are
intentionally kept outside the repository.

## Contents

| File or directory             | Purpose                                                             |
| ----------------------------- | ------------------------------------------------------------------- |
| `Brewfile`                    | Homebrew packages and VS Code extensions                            |
| `zsh/`                        | Portable interactive and login shell configuration                  |
| `git/.gitconfig`              | Personal Git defaults and conditional local include                 |
| `ssh/config`                  | Personal SSH template with a local include hook                     |
| `ghostty/`                    | Ghostty terminal configuration                                      |
| `vscode/extensions.txt`       | VS Code extension list                                              |
| `opencode/`                   | Neutral global OpenCode configuration and resources                 |
| `.pi/`                        | Portable Pi settings, resources, and generic MCP configuration      |
| `.omp/agent/`                 | Portable Oh My Pi preferences, rules, and generic MCP configuration |
| `.agents/`                    | VS Code agent skills and customizations                             |
| `install.sh`                  | New-Mac setup for the tracked personal configuration                |
| `sync-pi.sh`                  | Safe synchronization for mutable Pi files                           |
| `sync-omp.sh`                 | Safe synchronization for the allowlisted Oh My Pi files             |
| `validate-portable-mcp.py`    | Rejects literal MCP credentials                                     |
| `validate-personal-config.py` | Rejects known company markers in pulled files                       |

## Boundary

The repository is personal-only. Company configuration is deliberately absent
and must be applied locally on the relevant workstation from the private
workstation setup prompt or a credential manager. Do not put company values,
endpoints, certificates, identities, hosts, or credentials into tracked files,
and do not commit or push local work configuration.

The installer and synchronizers only manage the paths documented here. Local
environment files, Git identity includes, SSH host includes, secret files, and
runtime state remain outside the repository and are ignored when they use the
repository-side names documented below.

## Quick start

```bash
git clone git@github.com:jbt95/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer manages the personal files and neutral resources. Install the
`omp` binary separately; after installation, `omp config path` should resolve
to `~/.omp/agent`.

## Post-installation

1. Add the generated personal SSH public key to GitHub:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. Install Node.js when needed:

   ```bash
   nvm install node
   ```

3. Optionally create a personal GPG key. Keep private GPG data outside this
   repository.

4. OpenCode creates only the local Context7 secret file when it is absent:
   `~/.config/opencode/secrets/context7-api-key`. Populate it only if that
   service is needed; the tracked configuration uses a file reference.

5. Restart the shell or run:

   ```bash
   source ~/.zshrc
   ```

## Personal configuration

- Zsh keeps the personal aliases and development paths while loading an
  optional `~/.config/local-env.zsh` file.
- Git keeps the personal identity and GitHub rewrite. A local identity can be
  supplied through `~/.config/git/work.inc` for matching repositories without
  changing the tracked personal config.
- SSH includes `~/.ssh/config.local` for machine-local hosts. Private keys and
  host databases are never captured.
- Ghostty and the VS Code extension manifest are repository-owned neutral
  resources. User settings, keybindings, editor caches, and authentication
  databases are not included.

## OpenCode and Pi maintenance

OpenCode resources are installed under `~/.config/opencode`. The template is
copied only when no user configuration exists; the global instructions and DCP
configuration are managed regular files, while resource directories retain the
existing managed-link behavior. See `opencode/README.md` for details.

Pi's mutable settings are regular copies because Pi can rewrite them
atomically:

```bash
cd ~/dotfiles
./sync-pi.sh status
./sync-pi.sh pull
./sync-pi.sh push
```

The Pi synchronizer validates every pulled file and rejects literal sensitive
MCP values or company markers before changing the repository.

Oh My Pi's portable allowlist is synchronized separately:

```bash
./sync-omp.sh status
./sync-omp.sh pull
./sync-omp.sh push
```

`push` backs up changed live OMP files under
`~/.omp/backups/<timestamp>/agent/` with private directories. No OMP runtime
database, session, log, cache, binary, or authentication path is managed.

Run the focused configuration checks with:

```bash
./tests/pi-config.test.sh
./tests/config-sync.test.sh
```

Review changes before committing. Never stage protected pre-existing worktree
changes merely because the installer or synchronizers were run.

## Personal tools

The tracked setup includes Homebrew, Git, OpenSSH, NVM, pnpm, Bun, Docker
support, Maven/OpenJDK, Terraform, WebStorm, Ghostty, Raycast, Contexts,
Rectangle, and the personal VS Code extension list. Install optional tools
separately when they are not available on the new Mac.

## Troubleshooting

### Permission denied when running the installer

```bash
chmod +x install.sh
```

### Command not found after installation

Restart the terminal or source the shell configuration:

```bash
source ~/.zshrc
```

### Homebrew is not on PATH

On Apple Silicon, add the Homebrew shell initialization to the local login
profile rather than adding machine-specific paths to this repository.

## License

Personal use only.
