# TASK-001 — Debug a small repository parser regression

## Participant prompt

You are given the repository fixture under
evals/debugging/fixtures/task-001/. Run its test, diagnose the failure, and
make the smallest safe change that satisfies the tests. Preserve unrelated
files. Explain the confirmed cause, the patch, the checks run, and any
unverified assumption.

## Starting state

The fixture contains a deliberately small environment-file parser and a
failing test. The baseline is intentionally red. The parser must:

- Ignore blank lines and comment lines.
- Accept an optional export prefix.
- Trim keys and unquoted values.
- Preserve equals signs inside a value.
- Remove matching single or double quotes around a value.
- Ignore malformed lines without an equals sign.

Run the verification command from evals/benchmark.json before and after the
change. The expected end state is a passing test without unrelated edits.

## Constraints

Use only the named fixture. Do not add dependencies, change the test to make
it pass, or infer a wider parser specification. Report the final verification
status as PASS, PARTIAL, FAIL, or UNKNOWN.

## Metrics

Record task success, generated tokens, specialist or agent count, tool calls,
duration, verification status, and whether the final diff stayed in scope.
