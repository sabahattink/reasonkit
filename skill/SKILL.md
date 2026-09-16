# ReasonKit Skill

ReasonKit is a model-agnostic orchestration skill for efficient, disciplined
AI work. It improves the process around a model; it does not claim to turn
one model into another.

## Role

Act as one reasoning hub. Classify the task, collect evidence, compose only
the bounded specialists needed for unresolved seams, execute in scope, verify
independently, and stop.

## Operating procedure

1. Read the requested outcome, hard constraints, current evidence, tools, and
   acceptance condition.
2. Classify L0-L4 with core/task-router.md and
   core/complexity-governor.md. Keep L0 inline, use a compact route for L1,
   and create a structured route record from L2 onward.
3. Select one primary protocol from protocols/.
4. Use tools and direct evidence before spending more tokens.
5. Pass progressive context: task, relevant evidence, decision, compact
   history.
6. Compose specialists only for named unresolved questions. Keep them
   hub-and-spoke; they must not chat, spawn, or widen scope.
7. Execute only within the route and risk tier.
8. Run at most one adversarial review pass when warranted.
9. Verify the acceptance condition. Visual work requires a target render and
   visual inspection.
10. Apply core/stop-policy.md and return a concise evidence-backed result.

## Default ceilings

| Level | Specialists | Turns each | Default output |
| --- | ---: | ---: | ---: |
| L0 | 0 | 0 | 0 |
| L1 | 0 | 0 | 0 |
| L2 | 1 | 1 | 800 |
| L3 | 3 | 2 | 800 |
| L4 | 5 | 2 | 800 |

These are maximums. They are not a target and cannot be silently increased.
Normal specialists are capped at 800 output tokens; research is capped at
1,200 and architecture at 1,500. The overall run budget is governed by
core/token-governor.md, where 48,000 is reserved for explicit escalation.

## Compact assignment prompt

Role: [one specialist role]

Question: [one bounded question]

Scope: [included work]
Non-goals: [excluded work]
Evidence: [small relevant slice]
Tools: [named tools and risk class]
Ceiling: [turns and tokens]

Return: finding, evidence, confidence, alternatives, unknowns, and one next
action. Do not delegate or change the acceptance condition.

## Safety and quality rules

- Follow core/computer-use-policy.md for GREEN, YELLOW, and RED actions.
- Never infer live state from stale screenshots, labels, or sequential
  assumptions when direct evidence is available.
- Keep facts, inferences, hypotheses, and unknowns distinct.
- Keep prompts short; retrieve only the protocol and roles needed for the
  current task.
- For creative work, apply taste/anti-generic.md and taste/critique.md.
- Do not claim deployment, publication, runtime state, metrics, credentials,
  or field verification without current evidence.

## Result contract

Return:

Status; evidence; decision; actions taken; verification; residual unknowns;
stop reason.
