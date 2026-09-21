# Show HN draft

Status: hold until the default public surface points to v0.2 and a first-time user can load the bundle without reading benchmark internals.

## Title

Show HN: ReasonKit — adaptive reasoning and agent orchestration for efficient AI work

## Body

I built ReasonKit, a small prompt-pack for coding-agent and system-prompt workflows.

The problem I wanted to explore was context accumulation: an agent instruction set can grow into a large bundle even when a task needs only one protocol. ReasonKit uses a compact kernel, classifies the task, loads the relevant context, authorizes bounded specialists only when needed, and then requires verification and a stop decision.

It is deliberately not a runtime or API client. To try v0.2.0, clone the release tag, open `dist/v0.2/reasonkit-kernel.md` with `adapters/generic/SYSTEM.md`, and add the protocol that matches the task. Then give it one real task with scope and an acceptance condition. The host supplies the model, tools, permissions, and execution.

The release has one frozen held-out debugging result: all four tested conditions scored 4/4. The ReasonKit condition loaded only the debugging module and used 8.1% less provider input than the Luna + Reliable Engineering condition in that run. It is one task and not statistically significant; I am not claiming a quality advantage or universal token savings.

I’m looking for developers to try it on a real task and tell me where it helps or gets in the way. The 30-day experiment is about repeat use, not stars.

Release: https://github.com/sabahattink/reasonkit/releases/tag/v0.2.0

Please point out confusing setup or unsupported assumptions. Do not share private repository contents.
