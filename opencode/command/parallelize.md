---
description: Analyze and execute complex work as a dependency-aware set of parallel subtasks.
---

Treat the request below as a dependency graph and execute it end to end.

## Request

$ARGUMENTS

## Operating protocol

### 1. Discover and model dependencies

- Identify the requested outcomes, constraints, likely files, validation commands, and risks.
- Break the work into subtasks and identify which subtasks depend on which others.
- Launch all dependency-free discovery subtasks concurrently in one batch.
- Prefer read-only `explore` agents, or an equivalent read-only scout role if configured.
- Do not begin implementation until the required discovery results have returned, unless the task is clearly trivial.

### 2. Establish ownership before implementation

- Assign one clear owner to every file that may be modified.
- Do not allow concurrent edits to the same file.
- Keep implementation subtasks non-overlapping; sequence tasks that share an API, schema, generated output, or other boundary.
- The primary agent owns integration and final verification.
- Do not let subagents delegate further subtasks.
- Give every subagent:
  - a precise objective;
  - relevant paths and context;
  - files it may modify;
  - files it must not modify;
  - constraints and required validation commands;
  - the required structured return format.

### 3. Implement and integrate

- Dispatch independent implementation subtasks concurrently only after ownership is explicit.
- Wait for all required subtasks before integrating dependent work.
- Validate each subagent's claims against the repository rather than treating reports as proof.
- Resolve conflicts and integrate changes in the primary agent's workspace.

### 4. Verify and review

- Run targeted tests or checks for the changed areas.
- Run the complete repository lint, type-check, and test suite using the repository's documented commands. If a check cannot run, report the blocker and do not claim it passed.
- Dispatch independent read-only reviewers after integration.
- Fix confirmed findings, rerun affected checks, and report remaining risks or unresolved questions.

## Required subagent return contract

Each subagent must return exactly one JSON object matching this schema. Do not
wrap it in Markdown fences or add commentary before or after it.

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
    "summary": {
      "type": "string",
      "minLength": 1
    },
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

Use empty arrays when a category has no entries. The primary agent must parse
and validate every result against this contract before relying on it. If a
result is invalid or not JSON, request a corrected result or mark the subtask
incomplete; do not silently treat an informal report as verified.
