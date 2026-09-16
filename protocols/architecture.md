# Architecture Protocol

## When

Use for system shape, module boundaries, integration choices, migrations, or
tradeoffs that affect more than one seam.

## Sequence

1. State the outcome, invariants, constraints, and non-goals.
2. Map the current modules, interfaces, seams, and adapters.
3. Identify where behavior varies and where knowledge should remain local.
4. Propose at least two materially different interfaces when the decision is
   consequential.
5. Compare depth, leverage, locality, testability, operational risk, and
   migration cost.
6. Select one path and record rejected alternatives.
7. Define a small verification slice and rollback or recovery conditions.

## Gates

Prefer a deep module with a compact interface over a shallow pass-through
layer. Do not introduce a seam for a variation that does not exist. Mark
future concerns as future work instead of designing an untested platform.

## Output

Decision; interface; implementation responsibility; seam and adapter plan;
tradeoffs; migration slice; verification; unknowns.
