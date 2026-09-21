# ReasonKit Specialist Gate

Version: RK2-03
Status: implementation contract

The Specialist Gate is a deterministic, hub-owned decision seam. It decides
whether a bounded specialist is justified; it does not start a specialist,
model, process, tool, or workspace operation. A zero-specialist decision is
valid.

Authorization and execution are separate lifecycle states. A new
`AUTHORIZED` result has `started=false`, `specialist_count=0` when no earlier
specialist has started, and does not add its role to `specialist_roles`.
`specialist_count` and `specialist_roles` describe actual starts only.

## Decision order

1. Classify the request and normalize its consideration signals.
2. Attempt deterministic evidence first. Evidence may collapse hypotheses or
   establish that the uncertainty is resolved.
3. Consider a specialist only when a recognized signal remains, evidence was
   attempted or is unavailable, residual uncertainty is material, a bounded
   role has positive expected value, and the run budget permits it.
4. Record the decision and stop. The hub remains the sole authority.

After an external host confirms that an authorized execution actually began,
`Record-ReasonKitSpecialistStart` records that transition. It accepts the
authorization result and the same per-run state, returns `started=true`,
increments the actual started count once, and adds the started role once. It
does not invoke a provider, process, model, tool, or workspace operation.

Recognized signals are competing hypotheses, conflicting evidence, ownership
ambiguity, an unfamiliar external domain, high-impact or irreversible action,
nondeterministic verification, and unresolved creative direction. Complexity
level, uncertainty alone, or a request for more reasoning is not sufficient.

## Negative invariants

- No recursive spawn, specialist-to-specialist delegation, peer conversation,
  voting, majority, or consensus.
- Maximum three specialist authorizations per run and one adversarial pass.
  A further request is rejected and recorded; it is never silently dropped.
- The gate never fabricates provider measurements, re-injects raw transcripts,
  persists state, or grants a specialist authority over the hub.
- The start seam rejects missing or stale authorization, duplicate starts,
  role mismatch, recursive specialist-originated starts, and exhausted caps;
  each rejected lifecycle transition is recorded with a validity event.
- Gate authorization is not provider execution. `started` remains false until
  an explicitly separate execution boundary records an actual start.

## Decision record

`Decide-ReasonKitSpecialist` accepts a structured request and per-run state and
returns a deterministic record containing `decision`, `considered`,
`started`, `trigger`, `evidence_state`, `competing_hypotheses`,
`rejection_reason`, `role`, `expected_value`, `budget`, `validity_event`,
schema-bound `telemetry`, and nullable provider measurements.

The schema-bound `specialist_gate` object contains only the frozen telemetry
fields: `considered`, `started`, `trigger`, `evidence_state`,
`competing_hypotheses`, `rejection_reason`, and `role`. `expected_value` and
the detailed budget remain in the decision record so the telemetry schema is
not widened.

Per-run state contains authorization/reservation records, started records,
started role records, separate adversarial authorization and actual-pass
counts, and prior decisions. It is supplied by the caller and has no database,
cache, queue, or cross-run memory. Authorization reserves at most three
specialist slots and one adversarial slot; telemetry counts only actual starts.

## Bounded report

`Test-ReasonKitSpecialistReport` accepts only this exact payload:

```text
role
evidence_refs
conclusion
residual_risk
recommended_next_action
```

Each report is normalized and measured with `tiktoken==0.14.0` using
`cl100k_base` and the build-estimate measurement kind. Reports over 512
estimated tokens are rejected and surfaced; they are not truncated. Raw
transcripts and extra fields are rejected.
