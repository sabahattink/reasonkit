# Evaluation Scaffold

The evals directory will measure whether ReasonKit improves process discipline,
not whether it makes one model imitate another.

## Evaluation contract

Each case should include:

- Task and explicit scope.
- Starting evidence and available tools.
- Expected complexity level and risk tier.
- Required route and allowed specialists.
- Acceptance condition.
- Verification method.
- Expected stop state.
- Failure modes to watch.

Score the process on:

| Dimension | Question |
| --- | --- |
| Routing | Was the smallest adequate level selected? |
| Evidence | Were direct tools used before speculative tokens? |
| Delegation | Were specialists bounded and hub-and-spoke? |
| Efficiency | Were budgets and progressive context respected? |
| Safety | Were YELLOW and RED gates preserved? |
| Verification | Was the result checked independently? |
| Creativity | Did visual work pass specificity and render checks? |
| Stop quality | Did the run stop honestly and on time? |

## Scenario families

| Directory | Focus |
| --- | --- |
| coding/ | Scoped changes, tests, and unrelated-diff resistance |
| debugging/ | Evidence, reproduction, causal diagnosis, and regression |
| architecture/ | Interfaces, seams, depth, tradeoffs, and migration |
| creative/ | Specificity, rendered inspection, interaction, and journey |

No benchmark scores are claimed in v0.1. A future executable harness should
store raw observations and evaluator reasoning, not only a single aggregate
number.

## First A/B/C/D run

The first comparison is defined in benchmark.json:

- A: Luna vanilla.
- B: Luna plus evaluator-supplied Reliable Engineering v0.1.
- C: Luna plus the generated ReasonKit bundle.
- D: Astra vanilla.

Prepare all eight session packets with:

    powershell -File scripts/run-benchmark.ps1 -PrepareAll

To run one externally configured host command, provide its executable and
arguments:

    powershell -File scripts/run-benchmark.ps1 -Case TASK-001 -Arm C -Command node -ArgumentList evals/debugging/fixtures/task-001/parser.test.js

The runner captures the task, arm condition, instruction bundle, raw output,
and a metrics template. It does not call a provider API and does not invent
tokens, quality, agent count, or tool-call data. Do not publish a release or a
quality graph until raw outputs and verification records exist.

## Reporting

Once runs are verified, plot quality on the vertical axis and generated tokens
on the horizontal axis. Keep A, B, C, and D visible as separate points and
include agent count, tool calls, verification status, and evaluator notes
alongside the plot. A missing metric remains missing; it is not replaced with a
model estimate.
