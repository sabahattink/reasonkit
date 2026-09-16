# Evaluation Scaffold

The evals directory provides a repeatable way to measure process discipline,
not whether ReasonKit makes one model imitate another.

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

No benchmark scores are claimed in v0.1. The current harness stores raw
observations and evaluator reasoning rather than reducing a run to one
aggregate number.

## First A/B/C/D run

The first comparison is defined in benchmark.json:

- A: Luna vanilla.
- B: Luna plus the frozen Reliable Engineering v0.1 baseline.
- C: Luna plus the case-specific generated ReasonKit bundle.
- D: Astra vanilla.

Prepare all eight isolated session packets with:

    powershell -File scripts/run-benchmark.ps1 -PrepareAll

The runner creates task.md, the selected instruction bundle, a frozen
workspace/, run.json, metrics.json, and (when a command is supplied)
model-output.txt. It records source commit, dirty state, fixture SHA-256,
instruction SHA-256, instruction bytes, and the workspace contract before the
host starts.

The following is a runner smoke check, not a model run:

    powershell -File scripts/run-benchmark.ps1 -Case TASK-001 -Arm C -Command node -ArgumentList parser.test.js

For a real host, the provider-neutral command contract is:

    reasonkit-host --model Luna --prompt $REASONKIT_PROMPT_FILE --instructions $REASONKIT_INSTRUCTION_FILE --workspace $REASONKIT_WORKSPACE --output $REASONKIT_OUTPUT_FILE --metrics $REASONKIT_METRICS_FILE

The host command is supplied by the evaluator. The runner does not call a
provider API, modify a shared fixture, or invent tokens, quality, agent count,
or tool-call data. The host may write measured fields to
REASONKIT_METRICS_FILE; fields without provider evidence remain null.

Token fields remain independently measured:

    input_tokens
    cached_input_tokens
    output_tokens
    reasoning_tokens
    total_tokens
    instruction_bytes

The primary report is quality versus total measured tokens. Quality versus
output tokens is secondary. A missing provider metric remains null.

## Reporting

Once runs are verified, plot quality on the vertical axis and total measured
tokens on the horizontal axis. Keep A, B, C, and D visible as separate points and
include agent count, tool calls, verification status, and evaluator notes
alongside the plot. A missing metric remains missing; it is not replaced with a
model estimate.
