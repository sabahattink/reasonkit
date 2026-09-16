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
