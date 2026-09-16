# Changelog

All notable changes to ReasonKit are documented here.

## [Unreleased]

- Tighten default specialist and total token budgets; reserve 48,000 tokens
  for explicit escalation.
- Add generated full and compact distribution bundles.
- Add modular minimal, task-specific, and full distribution bundles.
- Add working copy/load prompt-pack adapters for ChatGPT, Codex, Claude Code,
  and generic hosts.
- Add TASK-001, TASK-002, an A/B/C/D manifest, and a session-packet runner.
- Isolate every benchmark run in a copied workspace and record fixture,
  instruction, source-commit, and dirty-state provenance.
- Replace ambiguous token totals with provider-aware input, cached-input,
  output, reasoning, total, tool-call, and agent-count metrics.
- Freeze the B-arm engineering baseline and add a pinned creative starter
  workspace for deterministic evaluation setup.
- Add scaffold validation and GitHub Actions quality checks.
- Add opinionated first-idea and 1,000-developers creative rejection checks.

## [0.1.0] - Planned

- Added the public ReasonKit scaffold.
- Added the adaptive reasoning loop and L0-L4 complexity model.
- Added token, tool, verification, stop, and Computer Use policies.
- Added bounded specialist role prompts and task protocols.
- Added anti-generic design, visual reasoning, and critique guidance.
- Added provider-neutral adapter guidance and evaluation directories.
