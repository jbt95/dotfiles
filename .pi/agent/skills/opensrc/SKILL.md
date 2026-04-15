---
name: opensrc
description: Query and search open source code repositories. Use when you need to find real-world code examples, understand library implementations, or research how other developers solve specific problems.
---

# OpenSrc Skill

Query and search over a million public GitHub repositories for real-world code examples.

## When to Use

- When implementing unfamiliar APIs or libraries
- When unsure about correct syntax or configuration
- When looking for production-ready examples
- When researching best practices for a specific library

## Usage

### Search for Code Patterns

```bash
opensrc grep "<code-pattern>" [--language <lang>] [--repo <repo>]
```

Examples:
```bash
# Find React useState patterns
opensrc grep "useState(" --language TypeScript

# Find Express.js authentication patterns
opensrc grep "passport.authenticate" --repo expressjs/express

# Find error boundary patterns
opensrc grep "ErrorBoundary" --language TSX
```

### Fetch and Read Repositories

```bash
opensrc fetch <repo-spec>
```

Repo spec formats:
- `zod` - npm package (latest version)
- `zod@3.22.0` - npm specific version
- `pypi:requests` - Python/PyPI package
- `crates:serde` - Rust/crates.io package
- `vercel/ai` - GitHub repo (default branch)
- `vercel/ai@v3.0.0` - GitHub repo at tag

Examples:
```bash
# Fetch zod repository
opensrc fetch zod

# Fetch specific version
opensrc fetch zod@3.22.0

# Fetch GitHub repo
opensrc fetch vercel/ai
```

### Read Files from Fetched Repos

```bash
opensrc read <source-name> <file-path>
```

Examples:
```bash
# Read package.json from zod
opensrc read zod package.json

# Read README
opensrc read zod README.md
```

### Search within Fetched Sources

```bash
opensrc grep "<pattern>" --sources <source-name> --include "*.ts"
```

## Tips

- Use specific code patterns (e.g., 'useState(') rather than keywords
- Filter by language for more relevant results
- Use regex patterns with --regexp flag for flexible matching
- Filter by repository to find examples from specific projects

## Examples of Good Queries

✅ Good: 'useState(', 'import React from', 'async function'
❌ Bad: 'react tutorial', 'best practices', 'how to use'
