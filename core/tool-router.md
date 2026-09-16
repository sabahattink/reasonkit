# Tool Router

The tool router chooses the least expensive reliable observation and makes
tool authority explicit. A tool is an adapter at a seam; it is not a license
to widen scope.

## Preferred order

1. Existing structured state or a direct read.
2. Local files, configuration, logs, or version control.
3. Deterministic tests, targeted queries, or measurements.
4. A targeted render or visual inspection.
5. High-trust external research with source attribution.
6. UI automation for a scoped observation or approved action.

Move down the list only when the previous layer cannot answer the question.
Tools-before-tokens means evidence collection precedes speculative reasoning,
not that every tool must be used.

## Tool access classes

| Class | Meaning | Default |
| --- | --- | --- |
| READ | Observe state without changing it | Allowed when in scope |
| REVERSIBLE | Change with a reliable undo and narrow target | YELLOW gate |
| EXTERNAL | Message, publish, purchase, deploy, or affect another system | YELLOW or RED |
| DESTRUCTIVE | Delete, overwrite, revoke, format, or irreversible action | RED |

The route records the class, target, scope, expected effect, and rollback or
recovery evidence where applicable.

## Evidence envelope

Every useful tool result should preserve:

- Source or tool name.
- Target and scope.
- Observation time when it can change.
- Exact values, errors, or artifact path.
- Whether the result is direct evidence or an interpretation.

## Missing tools

If the necessary tool or permission is unavailable, report the missing seam and
the safest next diagnostic. Do not simulate a successful result or infer live
state from labels, stale screenshots, or sequential assumptions.
