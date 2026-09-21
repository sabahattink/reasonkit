# FAQ

## What is ReasonKit?

An adaptive reasoning and agent orchestration prompt-pack. It defines a compact operating loop, task-shaped protocols, bounded specialist rules, risk tiers, verification, telemetry expectations, and honest stop conditions.

## Is it a package or CLI?

No. v0.2.0 does not include a provider runtime client, API wrapper, hosted service, or executable CLI. There is no `npm install` or `pip install` command. The supported path is to clone or download the release and copy/load `dist/v0.2/reasonkit-kernel.md`, `adapters/generic/SYSTEM.md`, and the protocol matching the task into a host that accepts system instructions or an equivalent instruction surface.

## Which hosts are covered?

The repository provides copy/load notes for ChatGPT, Codex, Claude Code, and a generic system-prompt host. These are prompt-pack adapters, not runtime integrations. The host still supplies model calls, tools, permissions, and execution.

## Does it make a weaker model as capable as a stronger model?

No. ReasonKit changes the operating procedure around a model. It does not turn one model into another and makes no quality-superiority claim.

## What did v0.2.0 demonstrate?

On one frozen held-out debugging task, all four tested conditions scored 4/4. ReasonKit loaded only the debugging module and used 8.1% less provider input than the Luna + Reliable Engineering condition in that run. The result is one task and is not statistically significant. Astra vanilla used the least measured input and output overall in the same comparison.

## Does it always save tokens?

No. The release reports one measured comparison and does not claim universal savings. Provider `total_tokens` was unavailable and was not synthesized.

## Does it collect private repository contents?

The release does not ship a telemetry service or require private-repository uploads. When giving feedback, share task category and setup observations only; do not include source code, prompts, outputs, credentials, or customer data.

## What should I try first?

Use one real debugging, coding, architecture, or research task with a clear acceptance condition. Compare the host's normal workflow with the ReasonKit-loaded workflow only if you can do so without exposing private material.

## Where should I report friction?

Use the `Tried ReasonKit` issue template and report the task category, host/provider at a high level, whether this was a first or repeat use, setup friction, and whether you would use it again.
