---
description: Inspect and summarize subagent results, artifacts, and verification status for an orchestration run.
---

Inspect delegation results for:

$ARGUMENTS

## Workflow

1. Gather all returned subagent results and any artifacts named by the launch
   envelope. Do not invent missing results.
2. Correlate results by `runId` and `taskId` when available; otherwise identify
   the task from its prompt and state the uncertainty.
3. Classify each task as complete, failed, blocked, incomplete, or not run.
4. Summarize changed files, verification checks, acceptance criteria, and
   unresolved risks.
5. Identify dependency failures and results that cannot be trusted because the
   JSON contract or required checks are missing.

Do not rerun checks or modify files. Use `/verify` when execution is needed.

## Output

Use a compact run summary followed by one flat entry per task containing its
task ID, role, state, summary, changed files, checks, and risks. Distinguish
observed results from inferred status.
