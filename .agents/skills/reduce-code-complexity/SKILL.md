---
name: reduce-code-complexity
description: Use when simplifying complex, duplicated, deeply nested, hard-to-test, or hard-to-understand code without changing observable behavior. Finds the smallest high-leverage refactor and verifies it through public seams.
license: MIT
metadata:
  inspiration: mattpocock/skills
disable-model-invocation: true
---

# Reduce Code Complexity

Reduce accidental complexity while preserving behavior. A smaller diff with a clearer interface is preferable to a broad rewrite.

Inspired by the deep-module and code-smell vocabulary in `mattpocock/skills`. Adapted rather than copied.

## The Seam

Name the public interface whose behavior must remain stable. Tests and callers should cross that same seam. If no reliable seam exists, identify that design problem before rearranging implementation details.

## 1. Bound The Work

Read repository instructions, relevant ADRs, tests, and recent history. Use the scope named by the user. Otherwise focus on changed or repeatedly modified code rather than scanning the entire repository.

Record:

- Observable behavior that must not change
- Current verification commands
- Compatibility and performance constraints
- Generated, migrated, or externally owned files that must not be edited

Completion criterion: the target and its stable behavior seam are explicit.

## 2. Locate Load-Bearing Complexity

Trace real callers and data flow before proposing a refactor. Look for evidence of:

- Duplicated decisions or transformations
- Deep nesting and mixed abstraction levels
- One change scattered across many callers
- Repeated parameter groups or primitive domain concepts
- Long message chains and leaked implementation knowledge
- Pass-through wrappers whose interface is as complex as their implementation
- Modules edited for unrelated reasons
- Abstractions created for hypothetical future variation
- Tests coupled to private implementation details

Apply the deletion test to a suspected abstraction: if deleting it merely moves complexity into every caller, it is earning its keep; if complexity disappears, it is probably shallow.

Do not use line count, method length, or cyclomatic complexity alone as proof. Explain the concrete maintenance or correctness cost.

Completion criterion: one primary complexity source is supported by callers, history, tests, or repeated logic.

## 3. Choose The Smallest Deepening

Prefer a refactor that puts more behavior behind a smaller interface and concentrates knowledge in one module. Typical moves include:

- Rename before restructuring when names are the main problem
- Flatten guards before extracting helpers
- Consolidate duplicated policy in the module that owns it
- Replace repeated parameter groups with an existing domain type, or introduce one only when the concept is real
- Move behavior toward the data and invariants it owns
- Remove middle layers that only delegate
- Replace scattered conditionals with one explicit policy when the same decision recurs
- Accept dependencies rather than constructing them when this creates a real test seam

Keep code in one function when extraction only gives fragments names and forces readers to jump around. Do not add factories, interfaces, strategies, base classes, or configuration switches without concrete variation.

Completion criterion: the proposed change improves locality or interface depth and introduces no speculative capability.

## 4. Preserve Behavior

Establish executable characterization at the public seam before changing code when existing tests are insufficient. Then make one coherent refactor at a time.

After each change:

1. Run the narrowest relevant check.
2. Inspect the diff for behavior changes and scope creep.
3. Remove obsolete branches, helpers, and comments made redundant by the new shape.
4. Stop if preserving behavior requires an unresolved product or architecture decision.

Do not rewrite tests merely to accommodate a new private structure. A behavior-preserving refactor should leave public tests substantially intact.

Completion criterion: public behavior remains proven and the diff contains only the intended simplification.

## 5. Review The Result

Compare before and after:

- Facts callers must know
- Places changed for the same policy
- Branching and failure modes
- Test setup required at the public seam
- Number of concepts and abstractions, not merely lines of code

If the result only moves complexity or increases the interface, revert the approach rather than layering another abstraction over it.

## Done

Report the complexity removed, the interface preserved or deepened, changed files, verification evidence, and any residual complexity deliberately left in place.
