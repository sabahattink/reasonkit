# TASK-004 Freeze Record

## Status

`TASK_004_FROZEN` is permitted only after this record, the freeze manifest,
the independent validation evidence, the repository integrity checks, and the
required CI run all succeed. The authoring validation recorded in
`BASELINE-VALIDATION.json` passed.

## Concept

TASK-004 is a held-out Node.js debugging case for a workspace/profile
configuration cache whose identity is too broad. It complements TASK-001's
single-function parser repair and TASK-003's duplicate-effect/concurrency
repair by testing cross-layer cache scope, path identity, per-call overlay
lifecycle, evidence-first diagnosis, and minimal verification.

## Authoring evidence

- Public pristine fixture: intentional failure, repeated exit code `1`.
- Hidden pristine fixture: intentional failure, repeated exit code `1`.
- Independent reference repair: public and hidden checks pass twice.
- Deliberate incomplete repair: public checks pass twice; hidden regression
  fails twice, demonstrating sensitivity to an incomplete path-key fix.
- Determinism: PASS.
- ReasonKit candidate arms: not run.

## Visibility boundary

Model-visible files are `task.md`, `acceptance.md`, and `fixture-public/**`.
Evaluator-only files are everything under `evaluator-only/`, plus the rubric,
validity rules, run order, protocol, and freeze controls. Hidden tests,
verifier code, reference repairs, incomplete repairs, and freeze evidence must
not be copied to a model workspace.

## Frozen inventory

`FREEZE-MANIFEST.json` lists every normative TASK-004 file except the manifest
itself. The manifest's own SHA256 is reported externally in the final task
report to avoid a self-referential hash. The manifest includes
`FREEZE-RECORD.md` and all other normative package files with exact bytes,
SHA256 values, roles, and visibility classifications.

## Candidate boundary

The frozen ReasonKit v0.2 candidate remains outside this package. Authoring
validation confirmed the candidate manifest file SHA256 and canonical digest
were unchanged, and no TASK-004 path was present in candidate coverage.
