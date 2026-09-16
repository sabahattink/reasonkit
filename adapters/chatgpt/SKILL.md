# ReasonKit for ChatGPT

## Install

Copy or load dist/reasonkit-min.md as the default reusable instruction for the
host. For a named task, use dist/reasonkit-coding.md,
dist/reasonkit-debugging.md, dist/reasonkit-design.md, or
dist/reasonkit-research.md. Load dist/reasonkit-full.md only when the task
explicitly needs cross-protocol coverage. No manual loading of the core files
is required.

## Use

Give ChatGPT one task with its constraints and expected outcome. ReasonKit
should classify internally, gather evidence with available tools, and return
the standard result contract.

## Host notes

Expose only the tools available in the current ChatGPT environment. Mark their
risk class, preserve the L0-L4 ceilings, and keep external effects behind the
Computer Use policy. This adapter does not claim a specific model, account,
API, or runtime capability.

## Example

Task: Diagnose the focused test failure after the smallest relevant change.
Preserve unrelated work, use direct repository evidence, verify the fix, and
report any unverified runtime state.
