# ReasonKit for Claude Code

## Install

Load dist/reasonkit-min.md as the default reusable instruction. Use the
task-specific dist bundle for coding, debugging, design, or research. Load
dist/reasonkit-full.md only when explicitly needed.

## Use

Give Claude Code the requested outcome, repository or workspace scope,
constraints, tools, and acceptance condition. ReasonKit owns routing and
verification; the host supplies the tools.

## Host notes

Keep specialist calls bounded, return findings to one hub, and preserve
tool-before-tokens. Use the Computer Use risk tiers for UI actions and never
hide destructive or external effects inside a generic execution step. This
adapter makes no provider, model, or benchmark claim.

## Example

Task: Investigate the named failure, gather direct evidence, make only the
accepted seam change, run a regression check, and stop with residual unknowns.
