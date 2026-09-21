# TASK-004 Acceptance Contract

## Functional correctness

1. The public test command passes without changing the tests.
2. Loading the same profile from different workspace roots returns each
   workspace's own file-backed values and creates separate base-cache entries.
3. Equivalent path spellings for one workspace reuse the same normalized
   workspace/profile cache entry rather than reading the same profile twice.
4. Environment and explicit request overrides are evaluated for every call,
   including calls that reuse a cached base. The cached value is the merged
   defaults-plus-file base, not a prior call's overlay.
5. The existing defaults, file parsing, numeric environment parsing, and
   shallow merge semantics remain intact.

## Scope and integrity

- Tests, workspace configuration fixtures, notes, and `package.json` are
  unchanged.
- No dependency is added and the test command is unchanged.
- The patch is limited to production code on the loader's runtime path.
- Clearing the cache on every call or removing the cache is not an acceptable
  workaround.
- No evaluator-only file is used as an input to the solution.

## Completion

The run is a task PASS only when the public tests pass, the implementation
preserves the cache contract, and the final diff stays within the allowed
production surface. A plausible explanation without a passing regression
check is not sufficient.
