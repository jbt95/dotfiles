# OpenCode Configuration

The installer places the global configuration under `~/.config/opencode`, OpenCode's supported global config
location. The template contains no credentials.

## Managed Files

- `opencode.json.template` is copied to `~/.config/opencode/opencode.json` only when no config exists.
- Files under `agents/`, `command/`, and `skills/` are symlinked into `~/.config/opencode/`.
- Existing conflicting files are moved to timestamped backups. Unrelated local files are preserved.

## Local Credentials

The installer creates empty local credential files that are never tracked. Populate the services you use:

```bash
$EDITOR ~/.config/opencode/secrets/atlassian-user-email
$EDITOR ~/.config/opencode/secrets/bitbucket-api-token
$EDITOR ~/.config/opencode/secrets/context7-api-key
```

OpenCode expands `{file:path}` references internally, keeping credentials out of its shell environment. Do not
replace them with literal credentials in the tracked template.

The Bitbucket MCP entry is disabled by default because it requires a separately managed local service on port
3030. Context7 is also disabled until its key is populated. Enable either only after its dependency and
credentials are configured.

## Validate

After installation and environment setup:

```bash
opencode debug agent change-reviewer
opencode debug agent java-spring-specialist
opencode debug skill
```

Quit and restart OpenCode after changing any configuration-time file.
