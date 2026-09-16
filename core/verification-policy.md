# Verification Policy

Verification is a separate responsibility from execution. A successful
command, a confident answer, or a generated screenshot is not automatically
proof of the requested result.

## Verification sequence

1. Restate the acceptance condition in observable terms.
2. Choose an independent check that can fail.
3. Run the check against the actual result or target state.
4. Compare expected and observed values, behavior, or appearance.
5. Record evidence, date or freshness, and remaining unknowns.
6. Apply the stop policy.

## Evidence strength

Prefer direct state, deterministic tests, measurements, rendered inspection,
and high-trust cited sources. Treat screenshots, logs without context,
self-reported success, and inferred mappings as weaker evidence when a direct
check exists.

## Result statuses

- PASS: the acceptance condition is met by current evidence.
- PARTIAL: a named subset passes and a named subset remains.
- FAIL: the check contradicts the expected condition.
- UNKNOWN: the check could not establish the condition.

Never upgrade UNKNOWN to PASS because the result looks plausible.

## Independent verification

The verifier should not rely on the implementer's summary when a fresh check
is available. For code, prefer tests, lint, build, and targeted behavior
checks. For research, verify source quality and claim scope. For visual work,
render at the intended size, inspect hierarchy, interaction, and responsive
states, and report when rendering was unavailable.

## Safety-sensitive work

Report verification by control, date, and observed state. Avoid absolute
"verified" language when a physical field check, live system confirmation, or
human approval is still missing.
