# TASK-004 Validity Rules

## Independence

- Author the task before any ReasonKit candidate arm is run against it.
- Do not inspect candidate outputs, candidate traces, or benchmark results
  while writing the fixture, hidden checks, or acceptance contract.
- The authoring proof must use only the public fixture, evaluator-only
  reference material, and local Node.js built-ins.

## Determinism

- Public and hidden baseline outcomes must repeat with the same exit status.
- The reference repair must pass public and hidden validation on repeated
  runs.
- No network, clock, random value, race, unavailable service, or timing
  threshold may determine validity.

## Fairness

- The public failure must identify a real defect without requiring hidden
  implementation knowledge.
- Held-out assertions must be direct instances of the written acceptance
  contract, not surprise behavior or implementation trivia.
- A strong vanilla coding agent must be able to solve the task by tracing the
  supplied runtime path and running the supplied tests.

## Scope

- The fixture must remain small and dependency-free.
- The intended repair must be smaller than a rewrite and must not require
  changing tests, fixtures, or metadata.
- Hidden material, the verifier, and the reference repair are never copied to
  the model workspace.
