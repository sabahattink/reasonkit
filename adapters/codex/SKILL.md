# ReasonKit for Codex

## Install

Load dist/reasonkit.md as the reusable instruction for the Codex task. Use
dist/reasonkit-min.md when the task needs the smallest possible context.

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
