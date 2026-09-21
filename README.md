# ReasonKit

> ReasonKit v0.2.0 — compact, adaptive reasoning and agent orchestration for efficient AI work.

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

## What v0.2.0 provides

- A compact Tiny Kernel for task classification, evidence handling, routing,
  verification, and honest stopping.
- A provider-neutral generic adapter and an explicit v0.2 implementation
  binding for hosts that load ReasonKit as an instruction surface.
- A module registry and lazy context plan so a route can load only the
  task-relevant protocol or policy modules.
- A specialist gate with bounded role calls, per-call ceilings, and a valid
  zero-agent path when delegation is not justified.
- Structured telemetry and provenance fields for route, module, reuse, scope,
  verification, and stop decisions.
- Reusable protocols for coding, debugging, architecture, research, design,
  and computer use, plus the v0.1 foundation of role prompts and safety
  policies.
- Generated minimal, task-specific, and full distribution bundles. The full
  bundle is reserved for explicit escalation; it is not the default v0.2 path.
- A reproducible evaluation scaffold with frozen fixtures, isolated run
  packets, and the completed TASK-004 A/B/C/D evidence package.

The release is a concise instruction, protocol, and adapter surface. Provider
runtime clients, provider-neutral token fabrication, and production deployment
are outside the package.

## Complexity and default ceilings

Budgets are ceilings, not targets. The governor may lower a budget when the
task is clearer than its initial classification, but it must not silently
raise one.

| Level | Typical task | Max specialists | Max turns per specialist | Max specialist output |
| --- | --- | ---: | ---: | ---: |
| L0 | Direct answer or deterministic lookup | 0 | 0 | 0 |
| L1 | One bounded operation with a clear check | 0 | 0 | 0 |
| L2 | Multi-step task with one meaningful seam | 1 | 1 | 800 |
| L3 | Cross-cutting change or ambiguous diagnosis | 3 | 2 | 800 |
| L4 | High-impact, novel, or safety-sensitive work | 5 | 2 | 800 |

Normal specialist output is capped at 800 tokens. Research may use at most
1,200 and architecture at most 1,500 when the route requires it. The
orchestrator owns one overall budget, keeps one adversarial pass as the
default maximum, and stops when the acceptance condition is met. L4 work also
requires an explicit human gate before high-impact or RED actions.

## Quick start

For the v0.2 surface:

1. Load `dist/v0.2/reasonkit-kernel.md` together with
   `adapters/generic/SYSTEM.md`.
2. Resolve the task route and available modules from
   `core/module-registry.json`; keep the v0.2 binding explicit.
3. Load the selected protocol or policy module only when the route needs it.
4. Compose a specialist call only for an unresolved seam that meets the
   specialist gate; otherwise continue on the zero-agent path.
5. Execute through the host's tools and adapter.
6. Verify the acceptance condition and record the evidence, unknowns, and stop
   decision in the host's telemetry surface.

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

## Use it in five minutes

1. Choose the host surface: ChatGPT, Codex, Claude Code, or a generic
   system-prompt host.
2. Load the v0.2 kernel and generic adapter. Start with the route's compact
   module set; do not manually load every core file.
3. Give the host one task, its constraints, and the expected outcome.
4. Let ReasonKit route internally and open specialists only when the gate
   authorizes them.
5. Inspect the returned status, evidence, verification, telemetry, and stop
   reason.

Example task:

> Diagnose why the focused test fails after the smallest relevant repository
> change. Do not modify unrelated files. Return the confirmed cause, patch,
> checks, and any unverified runtime state.

The expected interaction is a compact route, direct evidence, a bounded
specialist only if needed, execution, and an independently verified result.
Measured comparisons belong to `evals/`; unavailable provider metrics remain
unavailable rather than being estimated.

## Repository map

| Path | Purpose |
| --- | --- |
| `skill/` | The compact reusable entry skill |
| `core/` | Constitution, routing, budgets, tools, verification, and stop policies |
| `agents/` | Bounded specialist role prompts |
| `protocols/` | Task-shaped execution sequences |
| `taste/` | Creative quality and critique checks |
| `adapters/` | Provider-specific prompt-pack adapters |
| `dist/` | Generated minimal, task-specific, v0.2, and full copy/load bundles |
| `scripts/` | Deterministic bundle, validation, and benchmark helpers |
| `evals/` | Evaluation contract, frozen fixtures, and benchmark harness |
| `docs/releases/` | Public release notes and evidence links |

## Evidence for this release

The frozen TASK-004 benchmark is recorded in
[`evals/runs/task-004-results/benchmark-report.md`](evals/runs/task-004-results/benchmark-report.md)
with the machine-readable
[`summary.json`](evals/runs/task-004-results/summary.json). All four final
arms passed public and held-out evaluation, received the frozen rubric score
4/4, and changed only `src/config-loader.js` in their isolated workspaces.
This is evidence from one task, not a statistical claim about all coding work.

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

Version 0.2.0 is released from the `v0.2-phase-0` line as candidate
`rk2-0.2.0`. The candidate is frozen and its 55 covered files are integrity
checked. TASK-004 is also frozen; its final A/B/C/D benchmark evidence is
published under `evals/runs/task-004-results/`.

The release does not claim provider runtime integrations, production
deployment, or a quality advantage over the vanilla or Reliable Engineering
baselines. See the release notes for the observed comparison and limitations.

## License

Released under the MIT License. See LICENSE.
