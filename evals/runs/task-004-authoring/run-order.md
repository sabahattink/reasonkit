# TASK-004 Run Order

1. Verify the clean v0.2 checkout, frozen candidate manifest, and candidate
   coverage before authoring.
2. Create the public fixture and the independent task contract under this new
   evaluation-only subtree.
3. Run public baseline, hidden baseline, reference-fix, and incomplete-fix
   sensitivity checks without invoking ReasonKit.
4. Repeat the checks and record deterministic results in
   `freeze/BASELINE-VALIDATION.json`.
5. Freeze every normative TASK-004 byte in `freeze/FREEZE-MANIFEST.json` and
   record the boundary and evidence in `freeze/FREEZE-RECORD.md`.
6. Recheck that no candidate-covered byte changed, run repository integrity
   checks, commit only TASK-004 material, and push the existing v0.2 branch.
7. Wait for the integrity CI run to succeed. Only then mark the task
   `TASK_004_FROZEN` and make it eligible for a later A/B/C/D evaluation.

The frozen ReasonKit candidate is not an authoring oracle and must not be run
against TASK-004 during steps 1–7.
