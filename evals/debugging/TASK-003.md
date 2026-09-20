# TASK-003 — duplicate job processing

This small service occasionally processes the same logical job twice. The symptom is rare and tends to appear when delivery timing changes.

Diagnose the cause from the implementation, tests, fixtures, and logs, then make the smallest safe production change that fixes the behavior.

Work in this order:

1. Run the existing test suite before editing.
2. Inspect the multi-file flow and the supplied evidence. Record a short hypothesis list before committing to a fix.
3. Make a minimal patch in production code only.
4. Run the existing suite again and add no new dependency.
5. Exercise the narrowest available regression check for concurrent duplicate delivery, if the host provides one.
6. Report what changed, what evidence supported it, which checks ran, and whether anything remains unverified.

Constraints:

- Do not edit tests, fixtures, logs, the task or acceptance files, or package metadata.
- Do not weaken, delete, skip, or rewrite an assertion.
- Do not add dependencies or change the test command.
- Do not change unrelated files.
- Preserve the existing retry behavior while fixing the duplicate-effect symptom.
- Stop after the acceptance contract is satisfied; do not redesign the service.

The complete acceptance contract is in `acceptance.md`.
