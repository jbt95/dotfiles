---
description: Start a focused ILC change in the current repo
argument-hint: "<IILC-XXX> <short description>"
---
Start an ILC change for ticket `$1`: ${@:2}

1. Read the repository `AGENTS.md` and follow its change workflow. If the repo has a
   formal spec/change skill (e.g. `/ilc-spec-change`), use it for non-trivial schema,
   API, contract, security, authorization, infrastructure, or cross-repository work.
2. Check existing change artifacts for `$1` (e.g. `openspec/changes/`, `docs/adr/`,
   `docs/rfc/`, or the project issue). Create/update them before implementation.
3. If the repo uses OpenSpec/ilc-agent, run `ilc-agent spec check . --change iilc-$1`
   and fix any findings before writing code.
4. Implement through the repository's public seams with the smallest complete change.
   Backend examples: controller, repository, service, migration, Terraform.
   Frontend examples: component, store, hook, route, test, story.
   Use `/parallel` only for clearly independent slices.
5. Verify with the repository's canonical commands and update the change evidence/notes.
6. Do not commit, push, deploy, or approve pipelines unless explicitly asked.
