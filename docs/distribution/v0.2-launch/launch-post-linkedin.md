# LinkedIn launch draft

ReasonKit v0.2.0 is released and frozen.

ReasonKit is an adaptive reasoning and agent orchestration prompt-pack for efficient AI work. It routes a task to the smallest useful context, keeps specialist calls bounded, and makes evidence, verification, and stopping explicit.

The honest boundary matters: this is not a provider runtime, API client, or claim that one model becomes another. It is a copy/load surface for ChatGPT, Codex, Claude Code, and generic system-prompt hosts.

On one frozen held-out debugging task, all four tested conditions scored 4/4. ReasonKit loaded only the debugging module and used 8.1% less provider input than the Luna + Reliable Engineering condition in that run. Single task; not statistically significant. The benchmark did not show a measurable quality advantage, and Astra vanilla used the least measured input and output in that comparison.

I’m starting a 30-day distribution sprint around one question: do developers use it a second time on real work?

If you build agent tooling or use coding agents on real repositories, try it on one task and tell me where it helped or got in the way. Please do not share private code, prompts, outputs, or credentials.

Release: https://github.com/sabahattink/reasonkit/releases/tag/v0.2.0

#opensource #aiagents #developerTools #reasoning
