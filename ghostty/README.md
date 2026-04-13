# Ghostty Terminal

Configuration for Ghostty - a fast, native terminal emulator.

## Installation

Ghostty will be installed via Homebrew:
```bash
brew install ghostty
```

## Configuration

Config location: `~/.config/ghostty/config`

The config file will be symlinked from your dotfiles:
```bash
ln -s ~/dotfiles/ghostty/config ~/.config/ghostty/config
```

## Key Features

| Feature | Keybinding |
|---------|------------|
| New Tab | Cmd+T |
| Close Tab | Cmd+W |
| New Split (Right) | Cmd+D |
| New Split (Down) | Cmd+Shift+D |
| Next Split | Cmd+] |
| Previous Split | Cmd+[ |
| Quick Terminal | Cmd+` (global) |
| Increase Font | Cmd++ |
| Decrease Font | Cmd+- |
| Clear Screen | Cmd+K |

## Quick Terminal

Ghostty has a "quick terminal" feature - a dropdown terminal that appears from the top of the screen with a global hotkey (Cmd+`). This is similar to iTerm's "Hotkey Window".

## Customization

Edit `~/dotfiles/ghostty/config` to customize:
- Font family and size
- Colors and theme
- Window padding and transparency
- Keybindings

## Documentation

Full docs: https://ghostty.org/docs/config
