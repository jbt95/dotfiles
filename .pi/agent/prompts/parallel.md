---
description: Implement a change by delegating to parallel subagents
argument-hint: "<task-description>"
---
Implement the following change end-to-end, using parallel subagents for independent slices:

$@

### Workflow

1. **Decompose** the work into 2–4 independent, non-overlapping sub-tasks. Each task must own distinct files or distinct layers.
2. **Gather shared context once** (repository conventions, interfaces, existing migrations/tests) and include concise summaries in each worker’s prompt.
3. **Launch workers in parallel** with fresh context. Give every worker:
   - a clear scope and explicit boundaries,
   - the exact files or directories to read,
   - the acceptance criteria (format check, static analysis, targeted tests; full suite only at the end),
   - instructions to **not** call subagents themselves, **not** commit, and to report exactly what changed.
4. **Synthesize** the worker outputs, resolve conflicts, fill gaps, and apply any cross-cutting fixes yourself. You are the sole writer; never let two workers edit the same file.
5. **Verify** with the narrowest relevant checks first, then the repository’s main gates. Summarize changed files, verification results, and residual risks.

If the task is not decomposable into truly independent slices, implement sequentially instead of forcing parallelism.
