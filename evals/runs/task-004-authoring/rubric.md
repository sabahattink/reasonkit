# TASK-004 Evaluator Rubric

This rubric is evaluator-facing. It is not part of the model workspace.

## Scoring

### 0 — invalid

The submission does not run, changes the tests/fixtures, uses unavailable
external dependencies, or cannot be evaluated deterministically.

### 1 — partial diagnosis

The submission identifies a cache-related symptom or makes a narrow change,
but the public contract remains broken or the explanation is unsupported by
the observed failure.

### 2 — public functional repair

Public tests pass and the submission makes a production-only change, but the
held-out cache-scope or lifecycle contract fails, or the patch uses a broad
workaround such as disabling caching.

### 3 — correct repair with weak discipline

Public and held-out checks pass, but the patch changes unnecessary runtime
files, weakens scope discipline, or provides incomplete verification evidence.

### 4 — complete task pass

The production fix satisfies all functional and held-out checks, keeps the
patch minimal and in scope, preserves cache reuse and per-call overlays, and
reports evidence-backed diagnosis and verification clearly.

Any test edit, fixture edit, dependency addition, evaluator-only access, or
unrelated production rewrite is a scope failure even if outputs appear
correct.
