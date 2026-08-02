# Always-follow engineering rules

- Inspect the repository's existing conventions before editing; follow them instead of introducing parallel patterns.
- Make the smallest complete change that solves the request. Do not perform speculative refactors.
- Preserve existing public APIs unless the task explicitly requires a breaking change.
- When changing an exported symbol, find and update all references and callers.
- Validate data at system boundaries; do not treat TypeScript or Java types as runtime validation.
- Do not add dependencies when the existing stack can solve the problem.
- Do not edit generated files, lockfiles, build output, or secrets unless explicitly required.
- Add or update focused tests for changed behavior, then run the narrowest relevant verification.
- Do not claim that tests, builds, or commands passed unless they were actually run.
- Never commit, push, or rewrite unrelated user changes unless explicitly asked.
