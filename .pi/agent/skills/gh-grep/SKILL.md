---
name: gh-grep
description: Search over a million public GitHub repositories for real-world code examples. Use grep.app API to find production code patterns and best practices.
---

# GitHub Grep Skill

Search public GitHub repositories using grep.app API for real-world code examples.

## When to Use

- When you need real-world examples of API usage
- When researching how production code solves specific problems
- When looking for patterns in popular repositories
- When learning unfamiliar libraries or frameworks

## Usage

### Basic Search

```bash
curl -s "https://mcp.grep.app/search?q=<query>&language=<lang>"
```

### Parameters

- `q` - Search query (code pattern)
- `language` - Programming language filter
- `repo` - Specific repository (format: owner/repo)
- `path` - File path filter
- `flags` - Regex flags (use 'r' for regex search)

## Examples

Search for useState hooks in TypeScript:
```bash
curl -s "https://mcp.grep.app/search?q=useState(&language=TypeScript"
```

Search for Express middleware patterns:
```bash
curl -s "https://mcp.grep.app/search?q=app.use(middleware)&language=JavaScript"
```

Search in specific repository:
```bash
curl -s "https://mcp.grep.app/search?q=getServerSession&repo=nextjs/next.js"
```

Regex search for useEffect cleanup:
```bash
curl -s "https://mcp.grep.app/search?q=useEffect.*return.*cleanup&flags=r"
```

## Tips

- Search for literal code patterns (e.g., 'useState(') not keywords
- Use language filter to narrow results
- Use repo filter to search within specific projects
- Use path filter for specific file types (e.g., 'src/components')

## Good Search Patterns

✅ Good queries:
- 'useState('
- 'export function'
- 'async function'
- 'import React from'
- 'getServerSession'

❌ Avoid:
- 'react tutorial'
- 'best practices'
- 'how to use'
- 'documentation'
