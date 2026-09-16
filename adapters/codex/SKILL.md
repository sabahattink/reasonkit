# ReasonKit for Codex

## Install

Load dist/reasonkit-min.md as the default reusable instruction. Use
dist/reasonkit-coding.md, dist/reasonkit-debugging.md, dist/reasonkit-design.md,
or dist/reasonkit-research.md for task-specific context. Load
dist/reasonkit-full.md only when explicitly needed.

## Use

Provide the task, repository scope, constraints, available tools, and
acceptance condition. Keep L0/L1 work inline, create a structured route from
L2 onward, and preserve user changes in the working tree.

## Host notes

Map repository reads, edits, tests, renders, and review surfaces to explicit
tool classes. Local checks do not prove deployment or external runtime state.
The adapter preserves the hub-and-spoke topology and does not claim a
particular Codex model or capability.

## Example

Task: Implement the named repository change, run focused checks, inspect the
diff, and return COMPLETE, PARTIAL, BLOCKED, or UNKNOWN with evidence.
