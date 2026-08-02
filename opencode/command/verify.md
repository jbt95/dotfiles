---
description: Run explicit, read-only verification for current changes, a task, or named acceptance criteria.
---

Run verification for:

$ARGUMENTS

Use the `verifier` agent for this request when the task tool is available.
Otherwise, follow the verifier role directly.

## Workflow

1. Establish the exact scope from the request, launch envelope, changed files,
   and repository instructions.
2. Select the smallest relevant checks, tests, linters, type checks, or runtime
   commands. State why each check is relevant.
3. Run the checks without editing files.
4. Report every check as `passed`, `failed`, `blocked`, or `not_run`.
5. Return exactly the JSON result contract required by `AGENTS.md`.

Never claim verification from inspection alone when execution was requested.
If a check cannot run, explain the blocker instead of silently omitting it.
