# ReasonKit v0.2 — TASK-004 Final A/B/C/D Benchmark

Status: `TASK_004_BENCHMARK_COMPLETE`

## Identity

- Benchmark: `ReasonKit-v0.2-TASK-004-final-ABCD`
- Authoritative repository execution commit: `a97b3a5e9d0af96044683807a16a7c9adba34c94`
- Branch: `v0.2-phase-0`
- Candidate: `rk2-0.2.0`, version `0.2.0`
- Candidate manifest file SHA256: `d92130b16185e4f21af3223e51a8ea38269d3fd76b5e4462f7d33d8d53ee1621`
- Candidate canonical digest: `17f66740655adf279b217c6288b521212c579fc631dbc1fd44646cebd8cb1948`
- TASK-004 freeze manifest SHA256: `52ea13454a103ae441a7cf2a96600f35b64838513c00bbee35b103d1fe4b7c40`
- Frozen candidate source commit: `b421793162e8795200438473805bc5278dba77de`
- Runner shadow source commit: `b421793162e8795200438473805bc5278dba77de`; this was required by the frozen runner's source-binding check and did not alter the authoritative checkout.

## Direct comparison

| Arm | Condition | Final run ID | Public | Hidden | Frozen rubric | Scope | Files changed | Input tokens | Output tokens | Provider total |
|---|---|---|---|---|---:|---|---|---:|---:|---:|
| A | Luna vanilla | `20260921-113128-802-77e64175-A-TASK-004` | PASS | PASS | 4/4 | PASS | `src/config-loader.js` | 161060 | 3065 | None |
| B | Luna + Reliable Engineering v0.1 | `20260921-113247-574-6213f996-B-TASK-004` | PASS | PASS | 4/4 | PASS | `src/config-loader.js` | 169228 | 3095 | None |
| C | Luna + ReasonKit v0.2 | `20260921-113437-916-2eca41b4-C-TASK-004` | PASS | PASS | 4/4 | PASS | `src/config-loader.js` | 155471 | 2929 | None |
| D | Astra vanilla | `20260921-113557-340-c8f75f36-D-TASK-004` | PASS | PASS | 4/4 | PASS | `src/config-loader.js` | 129795 | 1068 | None |

All four completed arms passed public and hidden evaluation. Each final participant patch changed only `src/config-loader.js`; no tests, fixtures, dependencies, evaluator-only files, or unrelated production files changed.

## Run records

- A initial provider-aborted packet: `runs/20260921-113004-581-f5908727-A-TASK-004/`
- A recovery packet: `runs/20260921-113128-802-77e64175-A-TASK-004/` (`recovery_of` points to the aborted packet)
- B: `runs/20260921-113247-574-6213f996-B-TASK-004/`
- C: `runs/20260921-113437-916-2eca41b4-C-TASK-004/`
- D: `runs/20260921-113557-340-c8f75f36-D-TASK-004/`

Each completed packet retains `run.json`, context plan, telemetry, raw model output, provider `events.jsonl`/`stderr.txt`, host metadata, workspace final-state hashes, workspace patch, public verification, hidden evaluator output, lifecycle files, finalized evidence, and artifact hashes. Provider-home copies containing authentication/cache data were intentionally removed after execution and are not benchmark evidence.

## ReasonKit C telemetry

- Adaptive context: **activated**.
- Route: `debugging`; selected complexity: `L2`.
- Loaded module: `protocol.debugging` (200 measured module tokens).
- Omitted modules: `7` modules, `8744` bytes, `1806` measured tokens.
- Full bundle: **false**.
- Specialist authorization: `0`; actual provider agent starts: `0`; no specialist role started.
- Adversarial pass count: `0` host-level requests; no specialist/adversarial path was activated.
- Candidate binding: Tiny Kernel, generic adapter, registry, `reasonkit-v02` implementation, route context plan, `full_bundle_fallback=false`; all recorded hashes match the frozen binding.

## Context tax

`C_context_ratio = C input / B input = 0.9187073061195546`. Criterion `C <= 1.25 x B`: **PASS**. This is a post-run comparison only and did not influence runtime behavior. Provider `total_tokens` was not supplied for any arm and remains `null`; no total was synthesized.

## Observed evidence and interpretation

- A, B, C, and D independently diagnosed the profile-only cache key and produced the same minimal production-path repair. A, B, and C used explicit focused normalized-root/overlay checks in their final evidence; D reported the same checks and exact normalized key construction.
- B's raw host scope flag was conservative because the model printed the model-visible public README sentence that mentions evaluator-only material. Post-run command-path inspection found no forbidden evaluator path, so the frozen rubric scope result is PASS; the raw output is unchanged.
- C activated adaptive routing and loaded only the selected debugging module. It paid the mandated kernel/adapter/registry context cost but did not load the seven omitted modules or the full bundle. Its measured provider input was lower than B's in this single run.
- No arm used a broad rewrite, disabled caching, edited tests/fixtures, added dependencies, or used evaluator-only material as input.
- The first A attempt failed before model work because the provider session token was revoked (`401 token_revoked`). Its raw aborted packet is preserved and its required recovery completed successfully. No final arm result is based on the aborted attempt.

## Integrity and limitations

- Post-run candidate status: `PASS`; all 55 covered path hash/byte records pass and covered paths changed since freeze: `[]`.
- Post-run TASK-004 status: `PASS`; all 27 manifest entries pass and the normative package count is `28`.
- Base distribution, Tiny Kernel, and v0.2 registry checks passed.
- The result path is outside the frozen candidate and TASK-004 normative package. Raw model/provider/evaluator artifacts are preserved byte-for-byte; only derived evidence files were added.
- This is one task and one run per successful arm (plus A's required recovery). It does not establish statistical significance or generalize to other coding tasks.
- Provider cache/read metrics were reported only where the provider supplied them; unavailable fields remain `null`.
