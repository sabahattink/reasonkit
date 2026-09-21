# ReasonKit v0.2 Distribution Sprint #1

ReasonKit v0.2.0 is released and frozen. This sprint is for real-user adoption, not new architecture.

## Product

ReasonKit is an adaptive reasoning and agent orchestration surface for efficient AI work. It adds the reasoning context a task appears to need, keeps specialist calls bounded, and preserves an evidence/verification/stop contract.

It is a prompt-pack and orchestration contract. It is not a provider runtime, API client, package, hosted service, or universal token-saving promise.

## Evidence-backed proof

On one frozen held-out debugging task, all four tested conditions scored 4/4. ReasonKit v0.2 loaded only the debugging module and used 8.1% less provider input than the Luna + Reliable Engineering condition. Single task; not statistically significant.

The benchmark did not demonstrate a measurable ReasonKit quality advantage. Astra vanilla used the least measured input and output in that run.

## Sprint goal

Get the release into the hands of real developers and learn whether they use it more than once.

- Primary: second-use / repeat-use signal.
- Target: 20 real users or tries, 5 repeat users if measurable, 5 concrete feedback items, 3 external issue/discussion threads or equivalent direct feedback, and 3 real task categories.
- No fabricated installs, users, telemetry, outcomes, or field stories.

## Operating boundary

Allowed during the 30-day sprint: install/setup fixes, onboarding clarity, documentation, packaging/distribution fixes, feedback capture, and obvious first-run friction fixes.

Not allowed: v0.3 architecture, new specialist systems, benchmark rewrites, changes to candidate-covered bytes, changes to TASK-004 normative bytes, or automatic external posting/outreach.

## Launch gate

Before public promotion, a first-time user must be able to:

1. Find the v0.2 release surface.
2. Understand that it is a copy/load prompt-pack rather than an executable CLI.
3. Load the v0.2 kernel, generic adapter, and one task-shaped protocol into a supported host.
4. Run one real task without reading benchmark internals.
5. Report setup friction and whether they would use it again.

## Measurement rule

Record counts and evidence in `30-day-scorecard.md`. Keep repository names, prompts, outputs, and other private material out of feedback. A repeat user means a person who reports a second distinct ReasonKit use; do not infer it from stars, page views, or an unverified log.
