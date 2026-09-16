# Token Governor

The token governor treats context and generation as scarce resources. It
optimizes for reliable decisions, not maximum output length.

## Default budget

These are total soft ceilings for a run. The actual adapter may impose a lower
limit.

| Level | Default run tokens | Evidence | Synthesis and execution | Verification |
| --- | ---: | ---: | ---: | ---: |
| L0 | 1,200 | 300 | 600 | 300 |
| L1 | 2,500 | 600 | 1,400 | 500 |
| L2 | 6,000 | 1,400 | 3,200 | 1,400 |
| L3 | 12,000 | 3,000 | 6,500 | 2,500 |
| L4 | 20,000 | 5,000 | 11,000 | 4,000 |

The table is a default ceiling and planning aid. An explicit escalation may
use up to 48,000 total tokens only when the route records the reason, the
additional acceptance value, and the required human gate. 48,000 is never a
default L4 allowance. The complexity governor caps each specialist separately;
unused specialist budget does not become permission to start more specialists.

## Specialist output classes

- Normal specialists: 400-800 tokens, with 800 as the hard ceiling.
- Research specialists: at most 1,200 tokens.
- Architecture specialists: at most 1,500 tokens.

The output ceiling includes the return, not a license to repeat the evidence
provided by the hub.

## Allocation rules

1. Use a structured tool, file, log, test, or targeted render before asking
   the model to recreate the same information.
2. Send only the context needed to answer the current question.
3. Summarize stable evidence once and reference the summary thereafter.
4. Preserve exact values, errors, paths, dates, and citations when they affect
   a decision.
5. Compress narrative, repetition, and already-resolved branches.
6. Reserve verification tokens before execution begins.

## Progressive context

Context should move through four layers:

1. Task: outcome, constraints, and acceptance.
2. Evidence: only observations relevant to the current seam.
3. Decision: the selected path and its assumptions.
4. History: compact prior findings, not the full transcript.

If the next specialist needs more context, expand one layer at a time and
state why. Do not dump the full conversation as a substitute for routing.
L0 runs inline and L1 uses a compact route only when useful; do not spend a
structured route record on trivial work.

## Pressure signals

- At 70 percent of a budget, summarize and remove resolved branches.
- At 90 percent, finish the current bounded operation or report partial.
- At the hard ceiling, stop generation and return the current evidence.
- Repeated tool calls without new evidence are a stop signal, not a reason to
  spend more tokens.

## Ledger

The hub should be able to account for level, total budget, specialist budget,
evidence calls, summaries, execution, verification, and remaining unknowns.
When an adapter cannot expose token counts, mark them unavailable rather than
inventing precision.
