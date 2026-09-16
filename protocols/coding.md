# Coding Protocol

## When

Use for a scoped code, configuration, documentation-as-code, or repository
change with an observable acceptance condition.

## Sequence

1. Extract the acceptance condition and affected seam.
2. Inspect current files, tests, configuration, and user changes.
3. Route L0-L4 and gather direct evidence.
4. Ask the Investigator only if state or cause is unclear.
5. Implement the smallest reversible change.
6. Run focused checks, then the relevant broader check.
7. Use one adversarial pass when the level or impact warrants it.
8. Verify independently and stop.

## Gates

Do not mix unrelated cleanup into the patch. Do not claim runtime, deployment,
or external state from local checks. Preserve exact failures and report
unverified environments.

## Output

Changed seam; files; evidence; checks; verification status; residual unknowns;
stop reason.
