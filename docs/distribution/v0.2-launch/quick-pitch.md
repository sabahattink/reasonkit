# Quick pitch

## One sentence

ReasonKit is a model-agnostic prompt-pack that routes a task to the smallest useful reasoning context, keeps specialist calls bounded, and makes verification and stopping explicit.

## Thirty seconds

Most agent instruction packs become a large context bundle. ReasonKit v0.2 keeps a compact kernel, selects a task-shaped protocol, and opens specialists only when the evidence and gate justify them. It works as a copy/load surface for ChatGPT, Codex, Claude Code, or a generic system-prompt host. It does not include a provider runtime or claim to make one model equivalent to another.

## Two minutes

Clone the v0.2 release, load `dist/v0.2/reasonkit-kernel.md` with `adapters/generic/SYSTEM.md`, and add the one protocol that matches the task. Give the host one real task with its scope and acceptance condition. The expected loop is classify → evidence → bounded specialists only when needed → execute → verify → stop. Start with one task; then tell us whether setup was clear and whether you would use it again.

## Small ask

Try ReasonKit on one real task in one real repository and tell us where it helped or got in the way. Do not share private repository contents or credentials.

## Links

- Repository: https://github.com/sabahattink/reasonkit
- Frozen release: https://github.com/sabahattink/reasonkit/releases/tag/v0.2.0
- Feedback path: https://github.com/sabahattink/reasonkit/issues/new/choose
