# Positioning

## Primary statement

ReasonKit — adaptive reasoning and agent orchestration for efficient AI work.

It adds only the reasoning context a task appears to need, keeps specialist calls bounded, and makes evidence, verification, and stopping explicit.

## Who it is for

- Developers using coding agents on real repositories.
- Agent-framework builders who want a compact routing and verification contract.
- People testing context-efficient workflows across ChatGPT, Codex, Claude Code, or a generic system-prompt host.
- Maintainers who want a small, inspectable prompt-pack rather than a hosted black box.

## Message hierarchy

1. The practical problem: agent instructions often grow into an undifferentiated bundle.
2. The mechanism: classify the task, load the relevant protocol, authorize specialists only when needed, then verify and stop.
3. The boundary: ReasonKit supplies a prompt-pack and orchestration contract; the host supplies the model, tools, permissions, and runtime.
4. The invitation: try one real task in one real repository and report where it helped or got in the way.

## Approved evidence sentence

On one frozen held-out debugging task, all four tested conditions scored 4/4. ReasonKit v0.2 loaded only the debugging module and used 8.1% less provider input than the Luna + Reliable Engineering condition. Single task; not statistically significant.

## Say

- adaptive context selection
- bounded specialist calls
- observable routing and provenance
- explicit verification and stop decisions
- one frozen held-out task
- measured provider input in that run
- prompt-pack / copy-load surface

## Do not say

- makes weaker models as smart as stronger ones
- beats Astra
- improves intelligence
- statistically proven
- universally saves tokens
- production-ready runtime integration
- automatic support for every provider

## Tone

Technical, direct, and inspectable. Lead with the workflow and the invitation to test. Keep benchmark evidence as a bounded proof point, not the product's headline.
