# TASK-004 — Independent authoring package

This directory is a held-out authoring package for ReasonKit v0.2. It is
outside the frozen candidate coverage and must remain independent of all
candidate arms.

The case is a small Node.js configuration loader with a cross-workspace cache
scope regression. The model receives only `task.md`, the intentionally red
`fixture-public/` tree, and `acceptance.md` when the run protocol exposes it.
Hidden regression tests, verifiers, reference material, and scoring guidance
are evaluator-only.

Authoring validation is independent of ReasonKit. Run the evaluator-only
verification script from the repository root before using this package in an
actual benchmark arm:

```powershell
pwsh -ExecutionPolicy Bypass -File evals/task-004-authoring/evaluator-only/verify-task-004.ps1
```

The verifier must be run before any candidate evaluation. It must not invoke
the frozen ReasonKit candidate.
