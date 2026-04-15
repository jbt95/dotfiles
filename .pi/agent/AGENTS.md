# Global Agent Instructions

This file contains global instructions for the Pi coding agent.

## General Guidelines

- Always follow security best practices
- Review code carefully before making changes
- Use read-only mode (`/plan`) when exploring unfamiliar codebases
- Keep responses concise and actionable

## Tools Available

- `read` - Read files and directories
- `write` - Write new files
- `edit` - Edit existing files
- `bash` - Run shell commands
- `grep` - Search file contents
- `glob` - Find files by pattern
- `skill:*` - Load specialized skills on demand

## Session Management

- Use `/tree` to navigate session history
- Use `/fork` to create new branches from previous points
- Use `/compact` to manage context window

## Migration Notes

Migrated from OpenCode with Fireworks AI FirePass (Kimi K2.5 Turbo).
Previous configuration used MCP servers which are now converted to Skills.
