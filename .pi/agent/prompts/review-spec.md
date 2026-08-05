---
description: Review current branch changes against the project spec
argument-hint: "[spec-name]"
---
Review the current worktree/branch changes against the relevant OpenSpec or project specification (${1:-the most recent spec discussed}).

- Map every requirement and scenario to the files/tests that cover it.
- Identify fully covered, partially covered, and missing items.
- Flag out-of-scope changes, spec inconsistencies, and rollout/operational risks.
- Do not modify files unless asked after the review.
- Give a verdict: approve / approve with observations / request changes.
