# TASK-003 Acceptance Contract

## Required behavior

1. `npm test` passes before any edit and after the candidate patch.
2. Two concurrent deliveries carrying the same logical job produce exactly one durable repository effect.
3. The acknowledgement-retry scenario still produces exactly one durable effect and eventually acknowledges the delivery.
4. Two different logical jobs can still be processed concurrently and produce two effects.

The concurrent duplicate check is held out of the model workspace. It uses the public queue/worker/repository interfaces and a deterministic scheduling delay; it does not inspect private implementation details.

## Scope and integrity

- Tests are unchanged.
- Fixtures and logs are unchanged.
- `package.json` and dependency state are unchanged.
- No dependency is added.
- No unrelated file is changed.
- No assertion is weakened, removed, skipped, or hidden.
- The patch is limited to the smallest production-code surface needed by the diagnosis.

## Completion

The run is a task PASS only when public tests, held-out verification, retry preservation, and scope checks all pass. A technically attractive explanation or partial patch does not override a failed held-out check or a scope violation.
