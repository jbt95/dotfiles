---
description: Fetch a public repository and build or refresh its hierarchical AGENTS.md knowledge base
argument-hint: "<owner/repo or repository URL>"
---

Fetch the repository named in `$ARGUMENTS` with `npx opensrc`.

After it is available under the opensrc source directory:

1. Locate the fetched repository from command output or `opensrc/sources.json`.
2. Read its root instructions, manifests, documentation, source layout, and tests.
3. Create or update the root `AGENTS.md` with concise, repository-specific build, architecture, convention, and verification guidance.
4. Add nested `AGENTS.md` files only where a subsystem has genuinely different instructions that should override or extend the root guidance.
5. Preserve accurate existing instructions and remove stale statements only when source evidence proves they are obsolete.
6. Report the repository location, files changed, evidence consulted, and any unresolved uncertainties.

Do not commit or push the fetched repository.
