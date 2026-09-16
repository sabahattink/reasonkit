# Architecture Evaluations

Future cases should test whether the route defines a compact interface, places
the seam correctly, preserves locality, compares alternatives, and avoids
platform design without evidence.

Suggested cases:

- One real variation requiring two adapters.
- A pass-through module that should be deleted.
- A migration with an explicit rollback slice.
- A decision where dissent changes operational risk.

Score the decision and its verification plan, not the amount of prose.
