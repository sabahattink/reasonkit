# Generic Adapter

This directory contains the provider-neutral system-prompt surface. Start with
SYSTEM.md or load the generated bundle from dist/.

## Minimal host contract

The host must be able to:

1. Load a compact orchestration instruction.
2. Provide a named set of tools and risk classes.
3. Start bounded specialist calls with per-call ceilings.
4. Return evidence and results to one synthesis hub.
5. Run or expose independent verification.
6. Stop without silently widening scope.

The host may be a model, an application, or a local workflow. Provider
capabilities must remain explicit and must not leak into the ReasonKit core.

## Scope

The host remains responsible for model calls, tools, permissions, and
execution. ReasonKit supplies the routing and verification contract.
