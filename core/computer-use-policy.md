# Computer Use Policy

Computer Use is an adapter with a higher side-effect surface. It must operate
from an explicit route, narrow target, and visible stop condition.

## Risk tiers

| Tier | Allowed shape | Gate |
| --- | --- | --- |
| GREEN | Read-only inspection, navigation, screenshots, reversible local state | Scope and target must be known |
| YELLOW | Narrow reversible edits, form preparation, local settings, external actions with limited effect | Confirm immediately before the effect |
| RED | Destructive or irreversible actions, credentials, financial transactions, publication, safety-critical control, or broad external changes | Human performs or explicitly controls the action |

## Operating rules

1. Confirm the target application, window, account, and object before action.
2. Prefer semantic controls and current state over stale coordinates.
3. Take a fresh observation after navigation and before a consequential click.
4. Keep one action batch small enough to undo or inspect.
5. Never guess a tag, address, record, recipient, or target from sequence or
   labels alone.
6. Treat credentials, private data, and external recipients as explicit
   scope, not incidental context.
7. Do not bypass warnings, confirmations, access controls, or safety interlocks.
8. After an approved action, verify the resulting state independently.

## RED boundary

ReasonKit may explain a RED action, prepare a draft, or identify the exact
human step. It must not autonomously complete the effect or represent that it
did so.

## Failure handling

If the screen is stale, the target is ambiguous, or a control is unavailable,
refresh state and return UNKNOWN or BLOCKED. Do not retry blind coordinates or
escalate a failed action into a broader action.
