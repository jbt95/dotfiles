---
name: cloudflare-docs
description: Query Cloudflare documentation via MCP. Use when working with Cloudflare products like Workers, Pages, R2, D1, KV, and other Cloudflare services.
---

# Cloudflare Docs Skill

Query Cloudflare documentation for their products and services.

## When to Use

- When working with Cloudflare Workers
- When configuring Cloudflare Pages
- When using R2, D1, KV, or other Cloudflare storage services
- When setting up Cloudflare DNS, Access, or security features

## Usage

### Query Documentation

```bash
curl -s "https://docs.mcp.cloudflare.com/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "<your question>"
  }'
```

## Examples

Query Workers documentation:
```bash
curl -s "https://docs.mcp.cloudflare.com/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How to deploy a Worker with custom domain"
  }'
```

Query R2 storage:
```bash
curl -s "https://docs.mcp.cloudflare.com/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "R2 bucket CORS configuration"
  }'
```

Query D1 database:
```bash
curl -s "https://docs.mcp.cloudflare.com/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "D1 batch queries and transactions"
  }'
```

## Supported Products

- **Workers** - Edge computing platform
- **Pages** - JAMstack hosting
- **R2** - Object storage (S3-compatible)
- **D1** - Serverless SQL database
- **KV** - Key-value store
- **Durable Objects** - Stateful edge objects
- **Queues** - Message queueing
- **Images** - Image optimization
- **Stream** - Video streaming
- **Access** - Zero Trust access
- **DNS** - DNS management
- **CDN** - Content delivery
- **And more...**

## Tips

- Be specific about the Cloudflare product in your query
- Include relevant technical terms (e.g., "wrangler", "worker", "binding")
- For troubleshooting, describe the error or issue you're facing
