# Reddit draft

Status: use only in a community whose current rules permit a project/feedback post; ask moderators first where the rule is unclear.

## Suggested title

I built a small prompt-pack that selects task-specific reasoning context — looking for real workflow feedback

## Post

I’m testing ReasonKit v0.2.0, an open-source prompt-pack for adaptive reasoning and bounded agent orchestration.

The idea is simple: instead of loading every instruction and specialist role for every task, classify the task, load the relevant protocol, open a specialist only when the gate justifies it, then verify and stop.

The project is a copy/load surface, not a runtime, API client, or hosted service. It has notes for ChatGPT, Codex, Claude Code, and generic system-prompt hosts.

One frozen held-out debugging task gave all four tested conditions a 4/4 score. The ReasonKit condition loaded only the debugging module and used 8.1% less provider input than the Luna + Reliable Engineering condition in that run. It is one task and not statistically significant; there is no quality-superiority claim.

I’m looking for one small test on a real repository or real task:

- Was setup understandable?
- What task category did you try?
- What helped or got in the way?
- Would you use it again?

Please do not share private code, prompts, outputs, credentials, or customer data.

Release: https://github.com/sabahattink/reasonkit/releases/tag/v0.2.0

I’ll follow the community’s self-promotion rules and remove this if it is not appropriate here.
