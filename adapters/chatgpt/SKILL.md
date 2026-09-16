# ReasonKit for ChatGPT

## Install

Copy or load dist/reasonkit.md as the reusable instruction for the host. When
the context window is tight, use dist/reasonkit-min.md. No manual loading of
the core files is required.

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
