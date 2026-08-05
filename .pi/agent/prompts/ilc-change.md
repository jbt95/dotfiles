---
description: Start a spec-driven ILC change
argument-hint: "<IILC-XXX> <short description>"
---
Start a spec-driven change for ticket `$1`: ${@:2}

1. Read the repository `AGENTS.md`. If this is schema, API, observability, security,
   infrastructure, or cross-repository work, start with `/ilc-spec-change`.
2. Check existing OpenSpec artifacts under `openspec/changes/` for `$1`.
   If they are missing, create them first:
   - `proposal.md`
   - `design.md`
   - `specs/<domain>/spec.md`
   - `tasks.md`
   - `evidence.md`
3. Run `ilc-agent spec check . --change iilc-$1` and fix any findings before
   writing implementation code.
4. Implement through the repository's public seams (controller, repository,
   service, Flyway migration, Terraform). Prefer sequential work; use `/parallel`
   only for clearly independent slices.
5. Verify with the repository's canonical commands (e.g. `make check`, `make test`,
   Terraform validation). Update `evidence.md` with results.
6. Do not commit, push, or deploy unless explicitly asked.
