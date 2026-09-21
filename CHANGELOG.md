# Changelog

All notable changes to ReasonKit are documented here.

## [Unreleased]

No unreleased changes.

## [0.2.0] - 2026-09-21

ReasonKit v0.2.0 is the first frozen candidate-backed release. It makes the
adaptive path explicit and observable while keeping the host and provider
responsibilities separate.

- Add the v0.2 Tiny Kernel, generic adapter, module registry, lazy context
  plan, specialist gate, and v0.2 implementation binding.
- Add route, module-load, reuse, specialist, verification, stop, and
  provenance telemetry surfaces.
- Keep the zero-agent path valid and reserve the full bundle for explicit
  escalation rather than default loading.
- Add generated full and compact distribution bundles, modular task-specific
  bundles, and working copy/load prompt-pack adapters for ChatGPT, Codex,
  Claude Code, and generic hosts.
- Add the deterministic v0.2 evaluation manifest and isolated benchmark packet
  runner with fixture, instruction, source-commit, and dirty-state provenance.
- Complete the frozen TASK-004 A/B/C/D benchmark. A, B, C, and D all passed
  public and held-out evaluation and all received the frozen 4/4 rubric score.
- Record that the four final patches were limited to `src/config-loader.js`.
  No final arm used a broad rewrite, disabled caching, edited tests or
  fixtures, or added dependencies.
- Record that the v0.2 ReasonKit path activated adaptive debugging/L2 routing,
  loaded one selected module, did not start a specialist, and kept the full
  bundle disabled. Its measured input was 0.9187x the B-arm input in this
  single comparison.
- Preserve provider metrics as reported. Provider `total_tokens` was not
  supplied for these runs and remains unavailable rather than synthesized.
- Retain the v0.1 protocols, role prompts, safety policies, creative checks,
  and evaluation materials as historical and compatibility surfaces.
- Keep the provider-neutral architecture: provider runtime clients,
  production deployment, and statistical generalization remain outside this
  release.

## [0.1.0] - Planned

- Added the public ReasonKit scaffold.
- Added the adaptive reasoning loop and L0-L4 complexity model.
- Added token, tool, verification, stop, and Computer Use policies.
- Added bounded specialist role prompts and task protocols.
- Added anti-generic design, visual reasoning, and critique guidance.
- Added provider-neutral adapter guidance and evaluation directories.
