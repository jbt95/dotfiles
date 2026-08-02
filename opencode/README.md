# OpenCode Configuration

The installer places the global configuration under `~/.config/opencode`.
The tracked template contains neutral settings and no literal credentials.

## Managed files

- `opencode.json.template` is copied to `~/.config/opencode/opencode.json` only
  when no user configuration exists.
- `AGENTS.md` and `dcp.jsonc` are installed as regular managed files. A changed
  file is backed up before replacement, and an unmanaged symlink is refused.
- Files under `agents/`, `command/`, and `skills/` use the existing managed
  resource-link behavior. Unrelated local files are preserved.

Use `../sync-opencode.sh` for ongoing synchronization of all managed OpenCode
files and tracked resources.

## Local secret convention

The installer creates only the empty Context7 file when it is absent:

```bash
$EDITOR ~/.config/opencode/secrets/context7-api-key
chmod 600 ~/.config/opencode/secrets/context7-api-key
```

The template uses OpenCode's `{file:~/.config/opencode/secrets/context7-api-key}`
reference. Keep secret directories outside the repository and never replace a
reference with a literal value.

The tracked MCP entries are generic documentation and development services.
Company or workstation-specific MCP servers and credentials are deliberately
not tracked; add those only through a supported local configuration layer and
keep their values in local files or a credential manager.

## Validate

After installation and configuration changes, inspect the resources with the
OpenCode diagnostics available on the machine, for example:

```bash
opencode debug agent change-reviewer
opencode debug agent java-spring-specialist
opencode debug skill
```

Quit and restart OpenCode after changing a configuration-time file.
