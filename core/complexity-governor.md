# Complexity Governor

The complexity governor limits process size before specialists or tokens are
spent. A high-impact task is never made safe by calling it simple.

## Signals

Score each signal from 0 to 2:

- Ambiguity: how many plausible interpretations remain.
- Coupling: how many modules, people, or systems can be affected.
- Novelty: how much precedent or tested pattern is missing.
- Impact: cost of an incorrect result or side effect.

Use the highest level implied by any high-impact signal. Otherwise use the
total as a guide:

| Level | Typical signal | Maximum specialists | Turns each | Tokens each |
| --- | --- | ---: | ---: | ---: |
| L0 | Direct and deterministic | 0 | 0 | 0 |
| L1 | One bounded seam, low uncertainty | 1 | 1 | 3,000 |
| L2 | Several steps or one meaningful tradeoff | 2 | 2 | 4,000 |
| L3 | Cross-cutting, ambiguous, or novel | 4 | 2 | 6,000 |
| L4 | High-impact or safety-sensitive | 6 | 3 | 8,000 |

The suggested score bands are L0 for 0-1, L1 for 2-3, L2 for 4-5, and L3 for
6-7. L4 is an explicit override for high impact, irreversible effects,
untrusted environments, or unresolved safety concerns.

## Governor rules

- Budgets are hard ceilings unless a human explicitly authorizes a new route.
- The hub counts as one active reasoning process; specialists are additional.
- A specialist receives one question, one evidence slice, and one return
  contract.
- The default maximum is one adversarial-reviewer pass per task.
- No specialist can create another specialist.
- When the same evidence is sufficient, reuse it instead of re-querying.
- When a tool resolves the question, terminate the corresponding specialist.

## Escalation triggers

Escalate when a required acceptance check is impossible, when evidence
conflicts, when a planned action changes risk tier, or when a specialist
identifies a new independent seam. Escalation changes the route record before
new work starts.

## De-escalation triggers

Return to a lower level when the task becomes deterministic, the ambiguity is
resolved, or a direct tool result makes further specialization unnecessary.
De-escalation is preferred to filling unused budget.
