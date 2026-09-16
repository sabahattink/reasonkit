# Benchmark Arms

The first comparison has four arms:

| Arm | Condition |
| --- | --- |
| A | Luna vanilla |
| B | Luna plus the frozen evals/arms/reliable-engineering-v0.1.md baseline |
| C | Luna plus the case-specific generated ReasonKit bundle |
| D | Astra vanilla |

Keep model, task prompt, available tools, starting state, and evaluator
instructions as constant as the selected arm allows. Record exact model
version, instruction source, date, context, and tool permissions.

The runner prepares an isolated session packet and captures raw output. It
records instruction and fixture hashes before execution. It does not call a
model API or fabricate token, quality, or agent metrics. Add measured data only
after deterministic or human verification.
