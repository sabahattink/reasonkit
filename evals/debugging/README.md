# Debugging Evaluations

Future cases should test reproduction, evidence quality, one-hypothesis-at-a-
time diagnosis, safe changes, and regression verification.

Suggested cases:

- A deterministic failing test.
- A configuration mismatch with misleading labels.
- An intermittent failure requiring a bounded observation window.
- A missing host response where ping alone is insufficient evidence.

Do not score a confident explanation as a pass without a discriminating check.
