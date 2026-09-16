# Task Router

The router chooses the smallest adequate protocol and complexity ceiling. It
does not solve the task and does not delegate by habit.

## Input

The router receives:

- The user's task and explicit scope.
- Constraints, expected artifact, and acceptance condition if known.
- Available tools and adapters.
- Existing evidence and its freshness.
- Ambiguity, novelty, coupling, visual, and impact signals.

## Routing sequence

1. Extract the requested outcome and hard constraints.
2. Identify side effects, sensitive data, and any Computer Use risk.
3. Check whether direct evidence or a deterministic operation is enough.
4. Assign L0-L4 using core/complexity-governor.md.
5. Select one primary protocol.
6. Name the minimum unresolved questions.
7. Compose specialists only for those questions.
8. Record a route before execution.

## Route record

| Field | Required content |
| --- | --- |
| Outcome | One sentence describing the requested result |
| Level | L0, L1, L2, L3, or L4 |
| Protocol | One path under protocols/ |
| Evidence plan | The first observations or tools to use |
| Specialist plan | Roles, questions, and individual ceilings |
| Risk | GREEN, YELLOW, or RED where Computer Use applies |
| Acceptance | Observable condition for completion |
| Stop rule | The condition that ends the run |

## Default protocol mapping

| Signal | Primary protocol | Useful specialist |
| --- | --- | --- |
| Code change | protocols/coding.md | implementer, verifier |
| Fault or regression | protocols/debugging.md | investigator, verifier |
| System shape or tradeoff | protocols/architecture.md | investigator, dissent |
| Factual uncertainty | protocols/research.md | reference-researcher |
| Visual or interaction work | protocols/design.md | art-director, visual-inspector |
| UI or desktop action | protocols/computer-use.md | investigator, user-journey-tester |

Use a single protocol as the spine. A second protocol is allowed only when a
clear seam connects them, such as design plus computer-use verification.

## Escalation

Escalate one level when new evidence reveals more ambiguity, coupling,
novelty, or impact than the current ceiling allows. Do not escalate only
because a specialist produced a long answer. De-escalate when a direct
observation resolves the uncertainty.

If the acceptance condition is absent, ask for it only when it materially
changes the route; otherwise state the assumed condition and mark it as an
assumption.
