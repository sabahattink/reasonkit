# Token Governor

The token governor treats context and generation as scarce resources. It
optimizes for reliable decisions, not maximum output length.

## Default budget

These are total soft ceilings for a run. The actual adapter may impose a lower
limit.

| Level | Total run tokens | Evidence | Synthesis and execution | Verification |
| --- | ---: | ---: | ---: | ---: |
| L0 | 4,000 | 1,500 | 1,500 | 1,000 |
| L1 | 8,000 | 2,500 | 3,500 | 2,000 |
| L2 | 16,000 | 5,000 | 7,000 | 4,000 |
| L3 | 32,000 | 10,000 | 14,000 | 8,000 |
| L4 | 48,000 | 15,000 | 21,000 | 12,000 |

The table is a ceiling and planning aid. The complexity governor caps each
specialist separately; unused specialist budget does not become permission to
start more specialists.

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
