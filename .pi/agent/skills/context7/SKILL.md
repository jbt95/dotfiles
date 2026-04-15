---
name: context7
description: Query up-to-date library documentation via Context7. Use when you need accurate documentation for programming libraries, frameworks, or APIs. Resolves library names to Context7-compatible IDs and queries documentation.
---

# Context7 Skill

Use this skill to get accurate, up-to-date documentation for programming libraries and frameworks.

## When to Use

- When the user asks about a specific library or framework
- When you need to verify API usage or function signatures
- When implementing unfamiliar libraries
- When troubleshooting library-specific issues

## Setup

Ensure CONTEXT7_API_KEY is set in your environment.

## Usage

### Step 1: Resolve Library ID

First, resolve the library name to a Context7-compatible ID:

```bash
curl -s "https://mcp.context7.com/library-id?libraryName=<library-name>" \
  -H "Authorization: Bearer $CONTEXT7_API_KEY"
```

### Step 2: Query Documentation

Use the library ID to query documentation:

```bash
curl -s "https://mcp.context7.com/query" \
  -H "Authorization: Bearer $CONTEXT7_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "libraryId": "<library-id>",
    "query": "<your question>"
  }'
```

## Examples

Query Next.js documentation:
```bash
# Resolve ID
curl -s "https://mcp.context7.com/library-id?libraryName=next.js" \
  -H "Authorization: Bearer $CONTEXT7_API_KEY"

# Query
curl -s "https://mcp.context7.com/query" \
  -H "Authorization: Bearer $CONTEXT7_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "libraryId": "/vercel/next.js",
    "query": "How to set up authentication with JWT"
  }'
```

Query React documentation:
```bash
curl -s "https://mcp.context7.com/library-id?libraryName=react" \
  -H "Authorization: Bearer $CONTEXT7_API_KEY"
```

## Available Libraries

Common libraries available on Context7:
- next.js, react, vue, angular
- express, fastify, nestjs
- prisma, drizzle-orm
- tailwindcss, shadcn/ui
- And many more...

## Notes

- Always resolve the library ID first before querying
- API key format: ctx7sk-...
- Results include code snippets and examples
