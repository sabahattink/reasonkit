# TASK-004 — Fix workspace-scoped configuration caching

## Participant prompt

You are given a small Node.js service configuration fixture in the
`fixture-public/` workspace. Its tests reproduce a configuration mix-up that
appears when two workspaces use the same profile name. Diagnose the confirmed
cause from the failing test and the implementation, then make the smallest
safe production change that fixes the behavior.

Start by running the existing test command before editing. Trace the actual
runtime path through the loader, cache, profile source, and environment
overlay modules. Nearby helpers are present for realism; do not assume that a
file is on the runtime path merely because its name looks relevant.

The loader must satisfy these behaviors:

- A cached base configuration is isolated by the normalized workspace root
  and profile. Two different workspaces must never reuse one another's file
  values.
- Equivalent spellings of the same workspace root identify one cache entry.
- Environment and explicit request overrides are applied to the current call
  after the cached base is selected. A previous call must not freeze those
  per-call values into later calls.
- Repeated loads of the same normalized workspace and profile may reuse the
  base configuration; do not disable caching as a workaround.

Run the same verification command after the change. Do not add dependencies,
rewrite tests, or broaden the configuration feature set.

## Constraints

- Work only inside `fixture-public/`.
- Change production source only. Do not edit tests, configuration fixtures,
  package metadata, notes, or unrelated helpers.
- Do not add a dependency, network call, generated artifact, or service.
- Do not inspect or use evaluator-only material. It is not part of the model
  workspace during a benchmark run.
- Preserve the public API and existing parsing/merge behavior.
- Keep the patch minimal and explain why the changed file is on the confirmed
  runtime path.

## Required report

Report the initial test result, confirmed root cause, files changed, final
test result, any additional focused check, and any assumption that remains
unverified. Use PASS, PARTIAL, FAIL, or UNKNOWN for verification status.
