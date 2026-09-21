# ReasonKit

> ReasonKit — adaptive reasoning and agent orchestration for efficient AI work.

ReasonKit is a model-agnostic prompt-pack and orchestration layer for making an
AI host work with more discipline. It provides compact protocols for adaptive
reasoning, bounded specialists, token control, tool routing, verification,
anti-generic creative design, and computer use.

ReasonKit does not claim to turn one model into another. It changes the
operating procedure around a model: classify the task, collect evidence,
delegate only when useful, execute a bounded plan, verify the result, and
stop.

## Why ReasonKit

- Load the reasoning context a task appears to need instead of carrying every
  protocol by default.
- Keep specialist calls bounded, with a valid zero-agent path when delegation
  is not justified.
- Make evidence, verification, residual unknowns, and the stop decision visible
  in the result.

## 2-minute quickstart

ReasonKit v0.2.0 is a copy/load prompt-pack. It is not a provider runtime, API
client, package, hosted service, or executable CLI, so there is no `npm install`
or `pip install` command.

1. Clone the frozen release:

   ```bash
   git clone --branch v0.2.0 --depth 1 https://github.com/sabahattink/reasonkit.git
   cd reasonkit
   ```

2. For the v0.2 surface, open `dist/v0.2/reasonkit-kernel.md` together with
   `adapters/generic/SYSTEM.md`. For a first debugging task, also load
   `protocols/debugging.md`; choose the corresponding protocol for another task
   category. `core/module-registry.json` is the route index.
3. If you use ChatGPT, Codex, or Claude Code, read the matching copy/load note
   under `adapters/` first. These are prompt-pack adapters, not runtime
   integrations. The older generated bundles under `dist/` remain available as
   v0.1 compatibility surfaces.
4. Give the host one real task, its scope and constraints, and a clear
   acceptance condition.
5. Inspect the returned status, evidence, verification, residual unknowns, and
   stop reason. Report setup friction through the feedback path below.

There is no provider account, private-repository upload, or telemetry service
required by this release.

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

## What happens at runtime

1. The host classifies the task and chooses the smallest adequate route.
2. The route loads the relevant protocol or policy module instead of the full
   bundle.
3. A specialist is considered only for an unresolved seam that meets the
   specialist gate; zero specialists is a valid outcome.
4. The host executes through its own tools and permissions.
5. The result records evidence, verification, residual unknowns, and a stop
   decision.

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

## Example task

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
| `docs/distribution/v0.2-launch/` | Adoption drafts, feedback, channel notes, and sprint scorecard |

## Integrations and adapters

| Host | Supported surface |
| --- | --- |
| ChatGPT | Copy/load notes under `adapters/chatgpt/` |
| Codex | Copy/load notes under `adapters/codex/` |
| Claude Code | Copy/load notes under `adapters/claude-code/` |
| Generic host | `adapters/generic/SYSTEM.md` and the generated bundles |

The host remains responsible for model calls, tools, permissions, execution,
and any provider-specific telemetry. ReasonKit does not claim a provider
runtime integration.

## Evidence for this release

The frozen TASK-004 benchmark is recorded in
[`evals/runs/task-004-results/benchmark-report.md`](evals/runs/task-004-results/benchmark-report.md)
with the machine-readable
[`summary.json`](evals/runs/task-004-results/summary.json). All four final
arms passed public and held-out evaluation, received the frozen rubric score
4/4, and changed only `src/config-loader.js` in their isolated workspaces.
This is evidence from one task, not a statistical claim about all coding work.

The approved public summary is: on one frozen held-out debugging task, all four
tested conditions scored 4/4. ReasonKit v0.2 loaded only the debugging module
and used 8.1% less provider input than the Luna + Reliable Engineering
condition. Single task; not statistically significant.

## Limitations

- The release is a prompt-pack and orchestration contract, not a runtime,
  package, API client, or hosted service.
- It does not make a weaker model equivalent to a stronger model and does not
  claim a quality advantage over the tested baselines.
- The benchmark is one held-out task and is not statistically significant.
- Provider `total_tokens` was unavailable and was not synthesized.
- A single comparison does not establish universal token savings.

## Contributing and feedback

For setup or first-use feedback, use the
[`Tried ReasonKit` issue template](.github/ISSUE_TEMPLATE/tried-reasonkit.md).
Do not include private source code, prompts, outputs, credentials, customer
data, repository names, or internal URLs.

For code or documentation changes, read [CONTRIBUTING.md](CONTRIBUTING.md).
The distribution kit is in
[`docs/distribution/v0.2-launch/`](docs/distribution/v0.2-launch/).

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
