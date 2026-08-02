# context-mode — MANDATORY routing rules

context-mode MCP tools available. Rules protect context window from flooding. One unrouted command dumps 56 KB into context.

## Think in Code — MANDATORY

Analyze/count/filter/compare/search/parse/transform data: **write code** via `context-mode_ctx_execute(language, code)`, `console.log()` only the answer. Do NOT read raw data into context. PROGRAM the analysis, not COMPUTE it. Pure JavaScript — Node.js built-ins only (`fs`, `path`, `child_process`). `try/catch`, handle `null`/`undefined`. One script replaces ten tool calls.

## BLOCKED — do NOT attempt

### curl / wget — BLOCKED
Shell `curl`/`wget` intercepted and blocked. Do NOT retry.
Use: `context-mode_ctx_fetch_and_index(url, source)` or `context-mode_ctx_execute(language: "javascript", code: "const r = await fetch(...)")`

### Inline HTTP — BLOCKED
`fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, `http.request(` — intercepted. Do NOT retry.
Use: `context-mode_ctx_execute(language, code)` — only stdout enters context

### Direct web fetching — BLOCKED
Use: `context-mode_ctx_fetch_and_index(url, source)` then `context-mode_ctx_search(queries)`

## REDIRECTED — use sandbox

### Shell (>20 lines output)
Shell ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`.
Otherwise: `context-mode_ctx_batch_execute(commands, queries)` or `context-mode_ctx_execute(language: "javascript", code: "...")`. Use `language: "shell"` only when code matches the host shell.

Exception: invoke a trusted CLI directly when its documentation explicitly defines the command and guarantees bounded, stable output. Do not wrap that CLI in JavaScript, Python, or another subprocess solely to invoke it. Use `context-mode_ctx_execute` only when the output actually requires filtering, parsing, aggregation, redaction, or transformation; keep the sandbox routing above for unknown or potentially unbounded output.

### File reading (for analysis)
Reading to **edit** → reading correct. Reading to **analyze/explore/summarize** → `context-mode_ctx_execute_file(path, language, code)`.

### grep / search (large results)
Use `context-mode_ctx_execute(language: "javascript", code: "...")` in sandbox for portable filtering/counting.

## Tool selection

0. **MEMORY**: `context-mode_ctx_search(sort: "timeline")` — after resume, check prior context before asking user.
1. **GATHER**: `context-mode_ctx_batch_execute(commands, queries)` — runs all commands, auto-indexes, returns search. ONE call replaces 30+. Each command: `{label: "header", command: "..."}`.
2. **FOLLOW-UP**: `context-mode_ctx_search(queries: ["q1", "q2", ...])` — all questions as array, ONE call (default relevance mode).
3. **PROCESSING**: `context-mode_ctx_execute(language, code)` | `context-mode_ctx_execute_file(path, language, code)` — sandbox, only stdout enters context.
4. **WEB**: `context-mode_ctx_fetch_and_index(url, source)` then `context-mode_ctx_search(queries)` — raw HTML never enters context.
5. **INDEX**: `context-mode_ctx_index(content, source)` — store in FTS5 for later search.

## Parallel I/O batches

For multi-URL fetches or multi-API calls, **always** include `concurrency: N` (1-8):

- `context-mode_ctx_batch_execute(commands: [3+ network commands], concurrency: 5)` — gh, curl, dig, docker inspect, multi-region cloud queries
- `context-mode_ctx_fetch_and_index(requests: [{url, source}, ...], concurrency: 5)` — multi-URL batch fetch

**Use concurrency 4-8** for I/O-bound work (network calls, API queries). **Keep concurrency 1** for CPU-bound (npm test, build, lint) or commands sharing state (ports, lock files, same-repo writes).

GitHub API rate-limit: cap at 4 for `gh` calls.

## Output

Write artifacts to FILES — never inline. Return: file path + 1-line description.
Descriptive source labels for `search(source: "label")`.

## Session Continuity

Skills, roles, and decisions persist for the entire session. Do not abandon them as the conversation grows.

## Memory

Session history is persistent and searchable. On resume, search BEFORE asking the user:

| Need | Command |
|------|---------|
| What did we decide? | `context-mode_ctx_search(queries: ["decision"], source: "decision", sort: "timeline")` |
| What constraints exist? | `context-mode_ctx_search(queries: ["constraint"], source: "constraint")` |

DO NOT ask "what were we working on?" — SEARCH FIRST.
If search returns 0 results, proceed as a fresh session.

## ctx commands

| Command | Action |
|---------|---------|
| `ctx stats` | Call `stats` MCP tool, display full output verbatim |
| `ctx doctor` | Call `doctor` MCP tool, run returned shell command, display as checklist |
| `ctx upgrade` | Call `upgrade` MCP tool, run returned shell command, display as checklist |
| `ctx purge` | Call `purge` MCP tool with confirm: true. Warns before wiping knowledge base. |

After /clear or /compact: knowledge base and session stats preserved. Use `ctx purge` to start fresh.

## Parallel subtask policy

For complex tasks:

1. First identify dependencies between subtasks.
2. Dispatch all independent discovery subtasks concurrently in one batch.
3. Prefer read-only `explore` agents, or an equivalent read-only scout role if configured, during discovery.
4. Do not assign two writing agents overlapping files.
5. Before implementation, establish file ownership and give every subagent:
   - a precise objective;
   - relevant paths and context;
   - files it may modify;
   - files it must not modify;
   - required validation commands;
   - a structured return format.
6. Subagents must not delegate further subtasks.
7. Wait for required discovery results before assigning dependent implementation work.
8. The primary agent owns integration and final verification.
9. After integration, run targeted checks, then the full repository lint, type-check, and test suite.
10. Dispatch independent read-only reviewers after integration, fix confirmed findings, and report remaining risks.

## Agent routing rules

Choose the narrowest role that matches the work. Do not run every agent by
default, and do not use a general-purpose agent when a specialized role fits.

| Agent | Run when | Do not use for |
| --- | --- | --- |
| `scout` | The repository, behavior, file locations, or dependency edges are unfamiliar. Use it for bounded read-only discovery before implementation. | Trivial changes where the target file and change are already known. |
| `librarian` | The task requires library internals, multiple repositories, external documentation, or current API behavior. | Local-only discovery that does not need external sources. |
| `oracle` | The task involves architecture, competing designs, difficult debugging, race conditions, performance regressions, or high-risk review. | Routine edits or searches that do not need deeper judgment. |
| `implementer` | Scope, ownership, target files, and acceptance criteria are clear and files must be changed. | Open-ended discovery, independent review, or claiming checks it did not run. |
| `reviewer` | A non-trivial or risky implementation is complete and needs an independent read-only correctness, regression, security, or coverage review. | Reviewing the same change while it is still being edited. |
| `verifier` | Explicit tests, lint, type checks, runtime checks, or acceptance commands must be run and reported without edits. | Fixing failures or treating inspection alone as successful verification. |
| `explore` | A built-in fast discovery agent is available and no configured `scout` role is suitable. | Running both `explore` and `scout` for the same question without a clear reason. |
| `general` | The task spans several concerns and no narrower role or explicit ownership split is appropriate. | Work that can be cleanly separated into specialized subtasks. |
| `build` | The primary agent must integrate a change, coordinate implementation, or handle a small direct coding task. | Delegated read-only research or independent acceptance verification. |
| `plan` | Requirements, design, dependencies, or ownership need to be clarified before edits begin. | Making code changes or presenting a plan as completed implementation. |

Use this default sequence:

1. For a trivial known change, use `implementer` or `build`, then run `verifier` when behavior or configuration loading needs confirmation.
2. For unfamiliar code, run `scout` first, then `implementer`, then `verifier`.
3. For external-library or multi-repository work, run `librarian`; add `oracle` when the findings require an architectural or debugging decision.
4. After a non-trivial implementation, run `reviewer` and `verifier` after integration. They may run concurrently only when neither changes files and their inputs are stable.
5. Use `plan` before implementation when the request has unresolved requirements or meaningful dependency and ownership questions.
6. Use `/parallelize` when there are two or more independent subtasks. Give each task one role, one owner, explicit paths, acceptance criteria, and the required JSON result contract.
7. Use `/verify` for explicit acceptance checks and `/inspect-results` to reconcile delegated outputs. Use `/plannotator-review` when human interactive annotations are needed; it does not replace automated verification.

Preserve least privilege when routing agents. Keep research, review, and
verification roles read-only; use role-specific MCP access only when the task
needs it; do not broaden permissions merely to avoid a blocked tool call. The
global DCP configuration protects `task` and `todowrite`; do not bypass that
protection or ask subagents to manage protected orchestration state directly.

Every subagent must return exactly one JSON object matching this contract:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "SubagentResult",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "summary",
    "filesInspected",
    "filesChanged",
    "checks",
    "assumptions",
    "risks"
  ],
  "properties": {
    "summary": { "type": "string", "minLength": 1 },
    "filesInspected": {
      "type": "array",
      "items": { "type": "string" }
    },
    "filesChanged": {
      "type": "array",
      "items": { "type": "string" }
    },
    "checks": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["command", "status", "details"],
        "properties": {
          "command": { "type": "string", "minLength": 1 },
          "status": {
            "type": "string",
            "enum": ["passed", "failed", "blocked", "not_run"]
          },
          "details": { "type": "string" }
        }
      }
    },
    "assumptions": {
      "type": "array",
      "items": { "type": "string" }
    },
    "risks": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
```

Subagents must not wrap the object in Markdown fences or add surrounding
commentary. Use empty arrays when a category has no entries. The primary agent
must parse and validate every result before relying on it; invalid or informal
reports must be corrected or marked incomplete rather than silently accepted.
