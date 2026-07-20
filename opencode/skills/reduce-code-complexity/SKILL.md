---
name: reduce-code-complexity
description: Use when simplifying complex, duplicated, deeply nested, hard-to-test, or hard-to-understand code without changing observable behavior. Finds the smallest high-leverage refactor and verifies it through public seams.
license: MIT
metadata:
  inspiration: mattpocock/skills
---

# Reduce Code Complexity

Reduce accidental complexity while preserving behavior. A smaller diff with a clearer interface is preferable to a broad rewrite.

Inspired by the deep-module and code-smell vocabulary in `mattpocock/skills`. Adapted rather than copied.

## The Seam

Name the public interface whose behavior must remain stable. Tests and callers should cross that same seam. If no reliable seam exists, identify that design problem before rearranging implementation details.

## 1. Bound The Work

Read repository instructions, relevant ADRs, tests, and recent history. Use the scope named by the user. Otherwise focus on changed or repeatedly modified code rather than scanning the entire repository.

Record the observable behavior that must not change, current verification commands, compatibility constraints, and files that must not be edited.

Completion criterion: the target and its stable behavior seam are explicit.

## 2. Locate Load-Bearing Complexity

Trace real callers and data flow. Look for duplicated decisions, deep nesting, mixed abstraction levels, scattered policy, repeated parameter groups, primitive domain concepts, message chains, pass-through wrappers, unrelated reasons to change, speculative abstractions, and tests coupled to private details.

Apply the deletion test: if deleting an abstraction merely moves complexity into every caller, it is earning its keep; if complexity disappears, it is probably shallow. Do not use line count or cyclomatic complexity alone as proof.

Completion criterion: one primary complexity source is supported by callers, history, tests, or repeated logic.

## 3. Choose The Smallest Deepening

Prefer a change that puts more behavior behind a smaller interface and concentrates knowledge in one module. Rename before restructuring when names are the main problem. Flatten guards before extracting helpers. Consolidate duplicated policy in its owning module. Remove middle layers that only delegate.

Keep code in one function when extraction only creates fragments and navigation. Do not add factories, interfaces, strategies, base classes, or configuration switches without concrete variation.

Completion criterion: the proposed change improves locality or interface depth without speculative capability.

## 4. Preserve Behavior

Add executable characterization at the public seam before changing code when existing tests are insufficient. Make one coherent refactor at a time, run the narrowest check, inspect for scope creep, and remove obsolete code.

Do not rewrite tests merely to accommodate a new private structure. Stop if preserving behavior requires an unresolved product or architecture decision.

Completion criterion: public behavior remains proven and the diff contains only the intended simplification.

## Done

Report the complexity removed, interface preserved or deepened, changed files, verification evidence, and residual complexity deliberately left in place.
