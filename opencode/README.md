# Opencode Configuration

Place your actual `opencode.json` in `~/.opencode/opencode.json`

## Required API Keys

1. **Fireworks AI API Key**
   - Get from: https://fireworks.ai/api-keys
   - Replace `YOUR_FIREWORKS_API_KEY_HERE` in opencode.json

2. **Context7 API Key** (optional)
   - Get from: https://context7.com
   - Replace `YOUR_CONTEXT7_API_KEY_HERE` in opencode.json

## Installation

Opencode will be installed via the main install.sh script, or manually:

```bash
curl -fsSL https://opencode.ai/install.sh | bash
```

## Configuration Location

- Main config: `~/.opencode/opencode.json`
- Agents: `~/.opencode/agents/`
- Binaries: `~/.opencode/bin/`
