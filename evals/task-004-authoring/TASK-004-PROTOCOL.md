# TASK-004 Protocol

## Package boundary

The authoritative package root is `evals/task-004-authoring/`. It is outside
the v0.2 candidate manifest coverage. TASK-004 files are historical benchmark
material and must not be added to or substituted into the frozen candidate.

## Model-visible material

An eventual benchmark workspace contains only:

- `task.md`
- `acceptance.md` when the selected run protocol exposes the contract
- the complete `fixture-public/` subtree

The model may edit production files under `fixture-public/` only, subject to
the task contract.

## Evaluator-only material

The following remain outside the model workspace:

- `rubric.md`
- `validity-rules.md`, `run-order.md`, and this protocol
- `evaluator-only/README.md`
- the hidden regression test
- the verifier and scoring helpers
- reference and incomplete-fix material
- all freeze records and manifests

The model must never receive evaluator-only files, their contents, their
hashes as hints, or outputs from their hidden assertions during a run.

## Authoring boundary

Baseline and reference validation are performed independently with local
Node.js built-ins. They are not ReasonKit benchmark arms. Candidate A/B/C/D
execution is permitted only after the status is explicitly
`TASK_004_FROZEN`, the freeze manifest is recorded, the candidate integrity
check is PASS, and repository CI is successful.

## Verification evidence

The verifier must report public baseline, hidden baseline, reference fix,
incomplete-fix sensitivity when present, repeated outcomes, and candidate
non-use. A failed or nondeterministic authoring check blocks the freeze.
