# Agent Composer

The composer turns unresolved seams into a small set of bounded specialist
assignments. It is a routing module, not a swarm generator.

## Composition sequence

1. Start from the route record and acceptance condition.
2. List unresolved questions, not generic roles.
3. Assign each question to the smallest suitable specialist.
4. Remove duplicate or purely stylistic assignments.
5. Attach only relevant evidence and the individual ceiling.
6. Run specialists in parallel only when they do not depend on each other.
7. Synthesize at the hub.
8. Run one adversarial pass when the level or risk warrants it.
9. Verify and stop.

## Specialist contract

Each assignment contains:

- Role and one-sentence question.
- Scope and explicit non-goals.
- Relevant evidence with source and freshness.
- Allowed tools and risk tier.
- Maximum turns and tokens.
- Return format: finding, evidence, confidence, alternatives, unknowns, next
  action.

The specialist must return to the hub. It may not chat with another
specialist, expand the task, approve its own side effect, or silently change
the acceptance condition.

## Selection heuristics

- Investigator before implementer when the state is not known.
- Reference-researcher before claims that depend on external facts.
- Art-director before visual production when the direction is unclear.
- Visual-inspector after every target render.
- Verifier receives the acceptance condition and the result, not the
  implementer's confidence.
- Dissent is used when two plausible paths have materially different costs or
  risks.
- Adversarial-reviewer is a single bounded challenge pass, not a debate.

## Hub synthesis

The hub records which findings were accepted, rejected, or left unknown. It
selects one path, preserves alternatives only when they matter, and keeps
execution separate from verification.

## Composition failure

If no specialist has a bounded question, do not delegate. If the required
specialist exceeds the complexity ceiling, reduce scope, ask for a gate, or
report blocked.
