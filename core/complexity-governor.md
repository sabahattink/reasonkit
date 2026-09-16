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

| Level | Typical signal | Maximum specialists | Turns each | Default output ceiling |
| --- | --- | ---: | ---: | ---: |
| L0 | Direct and deterministic | 0 | 0 | 0 |
| L1 | One bounded seam, low uncertainty | 0 | 0 | 0 |
| L2 | Several steps or one meaningful tradeoff | 1 | 1 | 800 |
| L3 | Cross-cutting, ambiguous, or novel | 3 | 2 | 800 |
| L4 | High-impact or safety-sensitive | 5 | 2 | 800 |

## Role output ceilings

These are generated-output ceilings, not invitations to fill space:

| Specialist class | Maximum output |
| --- | ---: |
| Normal, verifier, adversarial, dissent, and journey roles | 800 tokens |
| Research specialist | 1,200 tokens |
| Architecture specialist | 1,500 tokens |

The lower complexity ceiling always wins. A role cannot use its class maximum
when the route or total run budget cannot support it.

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
- L0 and L1 do not spawn specialists.

## Escalation triggers

Escalate when a required acceptance check is impossible, when evidence
conflicts, when a planned action changes risk tier, or when a specialist
identifies a new independent seam. Escalation changes the route record before
new work starts.

## De-escalation triggers

Return to a lower level when the task becomes deterministic, the ambiguity is
resolved, or a direct tool result makes further specialization unnecessary.
De-escalation is preferred to filling unused budget.
