# Benchmark Arms

The first comparison has four arms:

| Arm | Condition |
| --- | --- |
| A | Luna vanilla |
| B | Luna plus evaluator-supplied Reliable Engineering v0.1 |
| C | Luna plus the generated ReasonKit bundle |
| D | Astra vanilla |

Keep model, task prompt, available tools, starting state, and evaluator
instructions as constant as the selected arm allows. Record exact model
version, instruction source, date, context, and tool permissions.

The runner prepares a session packet and captures raw output. It does not call
a model API or fabricate token, quality, or agent metrics. Add measured data
only after the run and human or deterministic verification.
