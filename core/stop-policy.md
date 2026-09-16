# Stop Policy

ReasonKit is complete when the acceptance condition is satisfied and the
required verification has passed. More activity is not automatically more
reliable.

## Stop now

Stop with COMPLETE when:

- The requested scope is fulfilled.
- Required checks pass.
- No unreviewed side effect remains.

Stop with PARTIAL when the useful in-scope portion is complete but a named
portion needs an unavailable tool, extra authority, or a later phase.

Stop with UNKNOWN when evidence is insufficient to support the conclusion.

Stop with BLOCKED when progress requires a specific external state change,
permission, or user decision.

## Escalate or ask

Escalate only for a new independent seam, conflicting evidence, an exhausted
safe route, or a risk-tier change. Ask the user for a gate when the next
action is YELLOW or RED and the policy requires it.

## Loop breakers

- One adversarial pass maximum by default.
- No repeated tool call without a stated new question.
- No new specialist after the acceptance condition passes.
- No token-budget extension merely to improve wording.
- No silent scope expansion.
- No "just one more check" without a failure hypothesis.

## Final report

Return status, evidence, actions, verification, residual unknowns, and the
reason for stopping. A concise honest stop is preferable to an impressive
unbounded process.
