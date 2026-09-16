# Debugging Protocol

## When

Use for a failure, regression, unexpected state, performance issue, or
intermittent behavior.

## Sequence

1. Define the failing behavior and the smallest reproduction.
2. Capture current state, versions, inputs, logs, and timing.
3. Separate observation from hypotheses.
4. Rank hypotheses by evidence and test cost.
5. Run one discriminating check at a time.
6. Change one causal seam only after evidence supports it.
7. Reproduce the original failure and run a regression check.
8. Verify the acceptance condition and stop or report BLOCKED.

## Gates

Do not initialize, format, overwrite, or change a live system while diagnosing
unless the scope and risk gate explicitly allow it. A missing ping is not proof
of host failure; labels and sequential addresses are not proof of a mapping.

## Output

Reproduction; observed evidence; confirmed cause or UNKNOWN; smallest fix;
checks; remaining hypotheses; stop reason.
