# ReasonKit

> ReasonKit — adaptive reasoning and agent orchestration for efficient AI work.

ReasonKit is a model-agnostic orchestration layer for making small and fast AI
models work with more discipline. It provides compact protocols for adaptive
reasoning, bounded specialists, token control, tool routing, verification,
anti-generic creative design, and computer use.

ReasonKit does not claim to turn one model into another. It changes the
operating procedure around a model: classify the task, collect evidence,
delegate only when useful, execute a bounded plan, verify the result, and
stop.

## The operating loop

classify → evidence → bounded specialists only when needed → execute → verify → stop

The loop is intentionally hub-and-spoke. One orchestrator owns the task and
the final synthesis. Specialists return bounded findings to the hub; they do
not start conversations with one another or create an unbounded swarm.

## What the v0.1 scaffold provides

- A complexity model from L0 to L4 with default delegation and token ceilings.
- A token governor that prefers tools and compact evidence before more model
  tokens.
- Reusable role prompts for investigation, implementation, verification,
  dissent, adversarial review, research, design, visual inspection, and
  journey testing.
- Protocols for coding, debugging, architecture, research, design, and
  computer use.
- A verification policy that separates pass, partial, fail, and unknown.
- Computer Use risk tiers: GREEN, YELLOW, and RED.
- Anti-generic design checks that require specificity, intention, and a
  rendered result.
- Provider-neutral adapter placeholders and a small evaluation layout.

This release is a concise instruction and protocol scaffold. Adapter
implementations and task fixtures are intentionally left for later versions.

## Complexity and default ceilings

Budgets are ceilings, not targets. The governor may lower a budget when the
task is clearer than its initial classification, but it must not silently
raise one.

| Level | Typical task | Max specialists | Max turns per specialist | Max specialist tokens |
| --- | --- | ---: | ---: | ---: |
| L0 | Direct answer or deterministic lookup | 0 | 0 | 0 |
| L1 | One bounded operation with a clear check | 1 | 1 | 3,000 |
| L2 | Multi-step task with one meaningful seam | 2 | 2 | 4,000 |
| L3 | Cross-cutting change or ambiguous diagnosis | 4 | 2 | 6,000 |
| L4 | High-impact, novel, or safety-sensitive work | 6 | 3 | 8,000 |

The orchestrator owns one overall budget, keeps one adversarial pass as the
default maximum, and stops when the acceptance condition is met. L4 work also
requires an explicit human gate before high-impact or RED actions.

## Quick start

1. Load skill/SKILL.md as the orchestration instruction.
2. Classify the task with core/task-router.md and set the L0-L4 ceiling.
3. Select one protocol from protocols/ and gather the minimum useful evidence.
4. Compose only the specialists needed for the unresolved seams.
5. Execute through the available adapter and tools.
6. Verify the acceptance condition, including a real render for visual work.
7. Report evidence, unknowns, and the stop decision.

The default result contract is:

| Field | Meaning |
| --- | --- |
| Status | Complete, partial, blocked, or unknown |
| Evidence | What was observed, measured, rendered, or cited |
| Decision | The selected path and why |
| Actions | Changes actually made |
| Verification | Checks performed and their result |
| Residual unknowns | What remains unverified |
| Stop reason | Why the loop ended or what gate is needed |

## Repository map

| Path | Purpose |
| --- | --- |
| skill/ | The compact reusable entry skill |
| core/ | Constitution, routing, budgets, tool, verification, and stop policies |
| agents/ | Bounded specialist role prompts |
| protocols/ | Task-shaped execution sequences |
| taste/ | Creative quality and critique checks |
| adapters/ | Provider-neutral integration placeholders |
| evals/ | Evaluation contract and future scenario families |

## Design rules

### Evidence before confidence

The system distinguishes observed facts, derived conclusions, hypotheses, and
unknowns. A screenshot can suggest a diagnosis; it cannot prove a runtime
state when a direct read is available.

### Tools before tokens

Use the least expensive reliable observation first: structured state, files,
logs, tests, or a targeted render. Spend model tokens on interpretation and
decisions, not on recreating evidence that a tool can provide.

### Visual work must be seen

Any visual artifact is rendered at its target size and visually inspected.
Source validity, a screenshot, or a successful build alone is not visual proof.
Missing render access is reported as unverified.

### Safety is part of the interface

GREEN computer-use actions may be read-only or readily reversible. YELLOW
actions need a clear scope and a confirmation gate at the point of effect. RED
actions include destructive, credential, financial, safety-critical, or
irreversible work and require explicit human control; ReasonKit never bypasses
that gate.

### Specificity beats decoration

The anti-generic checks ask whether the work has a clear point of view,
specific references, intentional hierarchy, and a reason for each prominent
visual or interaction. Minimal can be intentional; generic is not a quality
standard.

## Status

Version 0.1.0 is an initial public scaffold. It defines the contracts and
prompts; it does not claim provider integrations, benchmark results, or
production deployment.

## License

Released under the MIT License. See LICENSE.
