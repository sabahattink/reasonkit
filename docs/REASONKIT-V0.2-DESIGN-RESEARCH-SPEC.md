# ReasonKit v0.2 Design / Research Spec

**Status:** `DESIGN_FROZEN`  
**Document version:** `0.2.0-draft.3`  
**Date:** 2026-09-17  
**Scope:** design and research only; no v0.2 implementation is authorized by this document.

The architecture and research design are frozen under the approved `DESIGN_FROZEN` decision. Future benchmark acceptance remains separate.

## 1. Decision summary

ReasonKit v0.2 should reduce the cost of its always-loaded context and make specialist delegation an explicit, evidence-based decision. It should not add more instructions to the default path.

The proposed operating loop remains:

```text
classify → gather evidence → load only the needed context →
use bounded specialists only when their expected value is non-trivial →
execute → verify → stop
```

The primary baseline is **B: Luna + Reliable Engineering v0.1**. ReasonKit must justify any additional context or orchestration cost with a measurable improvement in correctness, robustness, or quality. “More agents” is not an objective.

The `C ≤ 1.25 × B` value below is a **post-run benchmark acceptance target only**. It is not a runtime policy, token governor, prompt instruction, routing condition, or product promise. The running system must not see, optimize against, or alter its behavior because of this threshold; the benchmark analysis applies it after the frozen runs are complete.

The first v0.2 implementation should contain three work items:

| ID | Work item | Intended leverage |
|---|---|---|
| RK2-01 | Tiny Kernel | Keep only the invariants that must be present on every run. |
| RK2-02 | Lazy Context Loader | Load a small module through a traceable interface only when the route or evidence requires it. |
| RK2-03 | Evidence-based Specialist Gate + telemetry | Make delegation observable, bounded, and skippable. |

The v0.1 benchmark phase is frozen history. TASK-001, TASK-002, and TASK-003 become the v0.2 regression suite. TASK-004 remains deferred until after the v0.2 design and implementation are frozen and an independent specialist-appropriate challenge has been authored.

## 2. Observed v0.1 evidence

All observations below are bounded by the recorded tasks, providers, host configuration, bundles, and sample sizes. They are not general model-performance or billing claims.

| Frozen task | Evidence | Design implication |
|---|---|---|
| TASK-001 | 12 confirmatory runs; every arm passed 3/3. C median input was `290,124` versus B `166,305`; C median tools `12` versus B `9`; all arms had `agent_count=0`. | The fixture has a ceiling effect, but C’s extra context did not separate correctness or success. Keep the simple path small. |
| TASK-002 | C passed 3/3 with no scope violations, but used median `533,745` input tokens and a `31,254`-byte bundle. Blind pairwise win rate was `33.3%`; A was `62.5%`, B `11.1%`, and D `100%` while D violated scope in 3/3 completed runs. | Creative quality was not shown to repay the context cost. Keep the design/taste layer optional and measurable; keep task success separate from visual preference. |
| TASK-003 | 12 confirmatory runs; all arms passed the strict contract 3/3. C median input was `232,393` versus B `113,571` (`~2.05x`), with `9` versus `6` tools and `110.605s` versus `68.583s`; all runs had `agent_count=0`. | The causal-diagnosis task did not need a specialist under the observed conditions. The gate must be able to prove and record that zero-specialist decision. |

Cross-task signal:

- v0.1 did not demonstrate a measurable quality or correctness advantage sufficient to justify its observed context overhead.
- The v0.1 ReasonKit path loaded substantial instructions without opening a specialist in the evaluated runs.
- Zero specialists is not itself a failure. It may be the correct adaptive decision; v0.1 did not expose enough evidence about why the decision was made.
- B is the **primary efficiency baseline**. It is the bar for simple and medium tasks; the central v0.2 question is whether ReasonKit justifies any additional orchestration cost relative to B.
- The v0.1 creative and debugging bundles must remain unchanged as historical artifacts. They are evidence, not implementation inputs for a silent rewrite.

The dataset’s existing distinctions remain normative:

```text
MODEL_FAIL        completed model work that violates the frozen task contract
EVALUATOR_INVALID completed model work invalidated by the evaluator seam
PROVIDER_ABORTED  provider interruption before a valid model completion
```

These categories must never be collapsed into one success rate.

## 3. Research hypotheses

Each hypothesis has a measurable consequence and a possible falsifier.

| ID | Hypothesis | Expected observation | Falsifier |
|---|---|---|---|
| H1 | Eager loading is the main source of the v0.1 context tax. | A kernel plus one or two lazy modules materially reduces provider `input_tokens` and instruction bytes. | v0.2 loads nearly the same context despite no full bundle. |
| H2 | A small, explicit kernel can preserve the useful invariants. | TASK-001/002/003 task and scope success does not fall relative to B. | Removing eager instructions increases contract or verification failures. |
| H3 | Evidence can distinguish “delegate” from “do it directly.” | Deterministic single-cause tasks complete with `specialist_started=false` and a recorded reason. | The gate opens specialists on routine tasks or cannot justify a no-agent decision. |
| H4 | Some unresolved tasks have positive specialist value. | An independently authored challenge shows a bounded specialist being started for a recorded high-value reason, with a measurable verification or quality benefit. | Specialists add cost without improving the pre-registered outcome, or no challenge reliably reaches the gate. |
| H5 | The design/taste layer is not a default dependency. | Removing or deferring it does not regress engineering tasks; creative value is measurable only when the design route requests it. | A frozen creative evaluation shows a repeatable advantage that requires the module. |
| H6 | B is the right efficiency control for the first v0.2 study. | C can approach B’s cost while preserving or improving the task contract. | B is not reproducible under the frozen host, or its own task success is unstable. |

## 4. Goals

v0.2 should:

1. Minimize default context while preserving ReasonKit’s core operating contract.
2. Load protocol content progressively, with provenance and byte/token telemetry.
3. Make the specialist decision explicit before any specialist starts.
4. Preserve hub-and-spoke orchestration: specialists report to the orchestrator and do not chat with one another.
5. Keep verification, scope discipline, stop discipline, and unsupported-claim avoidance first-class.
6. Measure both the cost and the value of every loaded module and specialist.
7. Make a correct zero-agent run a first-class outcome.

## 5. Explicit non-goals

v0.2 will not:

- claim that ReasonKit turns one model into another model;
- claim universal model superiority, lower billing, or higher quality from these fixtures;
- force a specialist because a task is labelled L3;
- maximize agent count, reasoning length, or tool usage;
- make specialists converse with one another;
- rewrite TASK-001, TASK-002, or TASK-003 to favor ReasonKit;
- design or run TASK-004 before the v0.2 implementation is complete and its candidate is frozen; TASK-004 must then be authored independently;
- add new capabilities or features to make v0.2 look more valuable; this release is a context, decision, and measurement reduction effort;
- add provider-specific behavior to the core interface;
- replace a model, provider, sandbox, or host policy;
- make the full v0.1 bundle the default context;
- infer `total_tokens` by adding input, cached input, output, or reasoning fields;
- hide failed, aborted, invalid, or scope-violating runs;
- treat a visual preference as task success;
- turn the first v0.2 study into a product-performance claim.

The following are explicitly out of scope and deferred from v0.2:

- persistent user/project memory system;
- MCP orchestration layer;
- planner graph or workflow DAG;
- autonomous workflow engine;
- new product or UI surface;
- unrelated agent roles or features;
- model-routing product or multi-model router;
- new provider abstraction unrelated to context reduction;
- benchmark-specific hidden hints;
- benchmark-fixture-aware routing;
- new long-term learning or self-improvement system.

Adding any item in this list requires a new proposal and a new design review; it is not a v0.2 implementation detail.

## 6. Proposed architecture

### 6.1 Operating shape

```text
host adapter
    ↓
Tiny Kernel
    ↓
task router / L0–L4 classifier
    ↓
evidence ledger
    ↓
Lazy Context Loader ──→ route module / protocol / taste module
    ↓
Evidence-based Specialist Gate
    ├─ no specialist → execute
    └─ bounded specialist(s) → orchestrator receives reports → execute
    ↓
Verification Gate
    ↓
Stop Gate
    ↓
run packet + telemetry
```

The architecture is intentionally composed of deep modules with small interfaces. The implementation behind a module should hide prompt assembly, provenance bookkeeping, and provider adaptation. The seams between routing, loading, delegation, execution, and verification must remain inspectable in the run packet.

### 6.2 Proposed modules and interfaces

| Module | Small interface | Hidden implementation / seam |
|---|---|---|
| Tiny Kernel | `classify`, `evidence_first`, `verify`, `stop` invariants | The kernel does not contain full protocol prose or provider instructions. |
| Task Router | `route(task, evidence) → route + complexity` | Maps the task to a module set without loading every module. |
| Evidence Ledger | `record(fact, source, confidence)` and `summarize()` | Keeps observed evidence distinct from hypotheses and guesses. |
| Lazy Context Loader | `load(module_id, reason, phase) → content + provenance` | Resolves module paths, hashes, byte counts, cache state, and load order. |
| Specialist Gate | `consider(evidence, hypotheses, risk, verification) → decision` | Computes an auditable expected-value decision; it does not start agents itself. |
| Specialist Adapter | `start(role, bounded_input) → report` | Provider-specific invocation stays behind the adapter. |
| Verification Gate | `verify(changes, acceptance) → result` | Runs the task’s frozen checks and records their evidence. |
| Stop Gate | `stop(state, acceptance, unresolved_risk) → decision` | Prevents needless extra iterations after the contract is satisfied. |
| Host Adapter | `execute(request) → events` | Codex, Claude Code, ChatGPT, and generic adapters share the contract without copying core policy. |

### 6.3 L0–L4 complexity model

The classifier is a routing hint, not a command to open agents.

| Level | Shape | Default context | Specialist default |
|---|---|---|---|
| L0 | Answer, lookup, or direct transformation with no meaningful external action. | Kernel only. | Never, unless a risk policy explicitly requires review. |
| L1 | Single-file or local, deterministic change. | Kernel + one route module if needed. | Usually none. |
| L2 | Bounded multi-file change with a reproducible verification path. | Kernel + route module + targeted protocol. | None unless evidence remains ambiguous. |
| L3 | Causal diagnosis, cross-file ownership ambiguity, competing hypotheses, or unresolved creative direction. | Kernel + targeted modules + evidence ledger. | Consider; do not force. |
| L4 | High-impact, irreversible, externally consequential, or long-horizon work. | Kernel + explicitly approved modules and risk policy. | Consider bounded review; require stronger verification and human approval where the host policy demands it. |

The observed TASK-003 runs demonstrate why this distinction matters: a task can be L3-shaped in its fixture while a single hypothesis becomes sufficiently supported after evidence collection. In that case `agent_count=0` is a valid adaptive result.

## 7. RK2-01 — Tiny Kernel

### 7.1 Kernel responsibility

The Tiny Kernel is the always-loaded operating contract. It should target **no more than 1,000–2,000 model tokens** after implementation, measured separately from the task prompt and lazy modules. This is an engineering budget, not a provider billing claim.

### 7.2 Provisional source budget and CI seam

The kernel needs a real, machine-checked boundary rather than a qualitative “keep it small” rule. The initial proposal is:

```text
KERNEL_SOURCE_BYTES_MAX = 8,000 UTF-8 bytes
KERNEL_ESTIMATED_TOKENS_MAX = 2,000 tokens using a pinned CI tokenizer
```

These are **provisional engineering parameters**, not product behavior and not sacred constants. The byte ceiling is deterministic; the token figure is a pinned build-time estimate and must not be presented as provider usage. A v0.2 implementation must add a CI check that fails when the kernel source exceeds the selected ceiling and reports both measurements in the build artifact. The implementation may not silently raise the ceiling after benchmark results are observed: changing it requires a new document version, an explicit rationale, and a new candidate freeze. A budget breach is a candidate/build failure, not a reason to change the benchmark acceptance rule or to claim that a model is generally inefficient.

The CI check is a source/build control only. It does not cause the runtime to budget itself to `1.25 × B`, shorten work opportunistically, or suppress evidence. Runtime behavior is governed by the kernel invariants and the evidence gate; the `1.25 ×` value is evaluated after the run.

It should contain only these invariants:

1. Classify before choosing context.
2. Use tools and local evidence before spending additional model tokens.
3. Keep facts, hypotheses, decisions, and assumptions distinct.
4. Load only the smallest module that answers the current need.
5. Ask the specialist gate before starting a specialist.
6. Keep specialists bounded and hub-and-spoke; no peer conversation.
7. Preserve scope and do not weaken tests, acceptance checks, or dependencies.
8. Verify the changed behavior before declaring completion.
9. Stop when the acceptance contract is satisfied and no material unresolved risk remains.
10. Do not invent measurements, citations, tool results, or performance claims.

The kernel must not reproduce the detailed contents of coding, debugging, architecture, research, design, computer-use, or taste protocols.

### 7.3 Kernel acceptance seam

The kernel’s useful seam is the transition from “what is required on every run” to “what is required for this route.” Any instruction that is not invariant belongs in a lazy module or adapter. A code review should be able to identify why each kernel sentence is always necessary.

## 8. RK2-02 — Lazy Context Loader

### 8.1 Loading policy

The loader maintains a small index, not a full prompt bundle. A normal run follows this order:

```text
kernel → route module → evidence-triggered protocol sections →
optional specialist role → verification material
```

The loader must:

- load by stable module ID, not by an uncontrolled directory glob;
- support section-level or module-level loading where practical;
- record the reason, phase, parent route, and order for every load;
- record source path, content hash, instruction bytes, provider-reported token fields when available, and cache state;
- make `full_bundle_loaded=false` explicit for normal runs;
- avoid loading design/taste context for engineering tasks unless the route requests it;
- preserve source, fixture, task, and instruction provenance;
- fail closed when a requested module is missing or its hash does not match the frozen manifest.

The registry itself is part of the always-loaded context and therefore has a provisional engineering budget:

```text
REGISTRY_SOURCE_BYTES_MAX = 2,000 UTF-8 bytes
REGISTRY_ESTIMATED_TOKENS_MAX = 500 tokens using the same pinned CI tokenizer
```

The registry may contain only canonical module IDs, short purpose/trigger metadata, and hash/reference data. Full module bodies do not belong in it. These are provisional build guardrails, materially smaller than the Tiny Kernel budget, not performance claims or runtime targets. CI must measure them; a later threshold change requires a versioned design decision.

### 8.2 Proposed loader contract

```text
load({
  module_id,
  reason,
  phase,
  parent_route,
  required_capabilities
}) → {
  module_id,
  content,
  source_path,
  sha256,
  instruction_bytes,
  input_tokens,
  cached_input_tokens,
  load_reason,
  load_phase
}
```

Unavailable provider fields remain `null`. The loader may not synthesize totals from partial fields.

### 8.2.1 Deterministic per-run deduplication

Every loadable module is identified by its canonical `module_id` and immutable content `sha256`. The loader maintains a per-run loaded-state keyed by `(module_id, sha256)`:

- the first request supplies the module and records `load_action="loaded"`;
- a repeated request for the same key reuses the existing loaded-state, injects no second copy into model context, and records `load_action="reused"` with `module_reuse.reused=true`;
- a request for the same module ID with a different content hash or revision records `load_action="reloaded"` and must include the previous hash, new hash, reason, and phase;
- a reload at the same hash is allowed only with an explicit phase-boundary reason and must still record that reason;
- a duplicate request without an explicit reload reason is rejected or collapsed to the existing state; it is never silently injected again.

Provider cache hits do not count as `module_reuse`. Reuse here means deterministic reuse by the ReasonKit loader before provider billing or cache semantics are considered.

The minimum load-action record is:

```json
{
  "module_id": "debugging.core",
  "module_sha256": "content-hash",
  "load_action": "loaded",
  "reload_reason": null,
  "previous_sha256": null,
  "context_injected": true
}
```

For `reused`, `context_injected` is `false` and `reload_reason` is `null`. For `reloaded`, both hashes and the explicit reason are required. This deduplication is a loader invariant, not a post-run analytical assumption.

### 8.3 Loader-cost contract

Loading is not free merely because it is lazy. The loader must expose its own cost and make the avoided-context comparison auditable. Every run must record at least:

```text
kernel_bytes / kernel_tokens
loader_index_bytes / loader_index_tokens
loader_request_count
loader_decision_duration_ms
modules_loaded[]
  module_id
  module_bytes / module_tokens
  load_reason
  load_phase
  module_reuse
```

`module_reuse` is a structured field, not an inference from a cache-looking token count:

```json
{
  "reused": false,
  "count": 0,
  "scope": "none"
}
```

Allowed loader reuse scopes are `none`, `same_run`, and verified `host_cache`. A provider cache hit is recorded separately as provider cache telemetry and never sets `module_reuse.reused=true`. If the loader or host cannot expose the reuse scope, it remains `null` with an explanation.

`reused=true` is allowed only when the exact module content hash matches and a ReasonKit loader or verified host-loader event establishes that the content was reused without being supplied again. The same module ID, a cache-looking token count, or an assumed provider cache is not evidence. Use `reused=false` when the module was supplied again; use `reused=null` with a reason when reuse cannot be proven.

For each route, the analysis must distinguish:

1. loader overhead: kernel, loader index, routing/retrieval decisions, and their recorded time/bytes/tokens;
2. loaded context: the modules actually supplied to the model;
3. omitted eager context: the comparable frozen v0.1 material that was not supplied.

The authored-byte comparison is deterministic. Provider token comparisons are reported only when the provider exposes attributable fields. If a valid counterfactual cannot be computed, context savings are `INCONCLUSIVE`; they are not assumed from the word “lazy.” A lazy loader that costs more than the omitted eager context fails its cost hypothesis even if task success is unchanged.

The `omitted_context` record must never be a guessed provider-token value. It is computed only from a frozen build manifest containing known module byte sizes and, where available, a pinned tokenizer estimate:

```json
{
  "omitted_context": {
    "source_manifest_sha256": "frozen-manifest-hash",
    "module_ids": ["debugging", "design"],
    "bytes": null,
    "tokens": null,
    "derivation": "frozen_build_manifest",
    "status": "null_until_manifest_resolution"
  }
}
```

`bytes` is deterministic when the manifest is present. `tokens` is `null` unless the pinned build tokenizer or provider attribution makes it valid. It must not be inferred from a provider total, cached-input count, or the difference between unrelated runs.

### 8.4 Context locality rule

A module is loaded where its leverage is highest and its locality is clear:

- task-independent invariants live in the kernel;
- route-specific guidance lives in a route module;
- evidence interpretation lives beside the relevant protocol;
- role instructions live with the specialist adapter;
- host permissions live in the host adapter;
- design/taste guidance is opt-in for creative work.

This prevents a small task from paying for unrelated modules and makes the cost/value seam measurable.

### 8.5 Full-bundle escalation

The normal path never loads the full ReasonKit bundle. Full-bundle loading is permitted only through an explicit escalation decision recorded outside the ordinary fallback path:

```text
full_bundle_loaded
escalation_reason
requested_by
approved_by_or_gate
source_hash
loaded_bytes / loaded_tokens_if_deterministic
```

An absent module, loader error, or provider interruption cannot silently fall back to the full bundle. Full-bundle loading is not normal error recovery. If escalation is not explicitly approved and recorded, the loader fails closed.

## 9. RK2-03 — Evidence-based Specialist Gate

### 9.1 Decision rule

The gate is a decision point between evidence collection and execution. It should return a decision even when it chooses not to start an agent.

A specialist is worth considering when one or more of these signals is present after initial evidence collection:

- two or more live hypotheses remain materially plausible;
- evidence conflicts or cannot distinguish the hypotheses;
- cross-file ownership or causal responsibility remains ambiguous;
- an unfamiliar external domain requires independent research;
- a high-impact or irreversible decision needs an independent review;
- verification is nondeterministic or cannot reliably expose a regression;
- creative direction remains unresolved in a way that a focused art/design critic could clarify.

These signals are **OR conditions for consideration, not OR conditions for spawning**. A trigger puts the gate on the decision path; it does not authorize an agent. Before starting a specialist, the gate must run the cheapest available deterministic reproduction, local inspection, or verification step. It may reject delegation when that evidence collapses the uncertainty or when expected value does not exceed the added cost. Multiple triggers are recorded as an array, but one trigger alone never implies `started=true`.

The gate should normally decline delegation when:

- one causal hypothesis is supported by a deterministic reproduction;
- the change is local and low risk;
- the acceptance checks are deterministic and available;
- the remaining work is direct execution rather than independent investigation.

### 9.2 Bounded execution

The initial v0.2 design proposes:

- at most **three specialists per task**;
- at most **one adversarial-reviewer pass** per task;
- one bounded request and one report per specialist unless the gate records a new decision;
- no specialist-to-specialist conversation;
- no unrestricted shared transcript;
- role output limited to evidence, decision, risk, and recommended next action;
- the orchestrator remains responsible for integration, execution, verification, and stop.

The following negative invariants are explicit:

- a specialist may not invoke the Specialist Gate or spawn another specialist;
- specialists may not delegate to or converse with one another;
- there is no specialist voting, majority rule, or peer consensus mechanism; the hub is the sole decision authority;
- model uncertainty alone, including “I am unsure,” is not a spawn or deeper-reasoning trigger; additional evidence or verification is required;
- raw specialist transcripts are never returned wholesale to the hub context; only a bounded structured report is eligible for integration.

The structured report should contain only `role`, `evidence_refs`, `conclusion`, `residual_risk`, and `recommended_next_action`. The initial adapter budget is a provisional maximum of `512` estimated report tokens per specialist; actual provider output remains separately recorded, and an unavailable provider field remains `null`.

The cap is a proposed design parameter and becomes frozen only after review. Exceeding it is a telemetry and validity event, not something to hide by truncating the record.

### 9.3 No-agent success

The following is a successful gate outcome when the recorded evidence supports it:

```json
{
  "considered": true,
  "started": false,
  "trigger": [],
  "evidence_state": "single_causal_hypothesis_confirmed",
  "competing_hypotheses": [],
  "rejection_reason": "expected_value_low_after_deterministic_reproduction",
  "role": null,
  "specialist_count": 0,
  "expected_value": "low",
  "selected_complexity": "L2",
  "gate_version": "rk2-specialist-gate-v1"
}
```

The absence of a specialist must not be represented as missing telemetry or as an automatic failure.

### 9.4 Specialist-start outcome

```json
{
  "considered": true,
  "started": true,
  "trigger": ["competing_hypotheses", "conflicting_repository_evidence"],
  "evidence_state": "material_conflict_unresolved",
  "competing_hypotheses": [
    {"id": "hypothesis-a", "status": "live"},
    {"id": "hypothesis-b", "status": "live"}
  ],
  "rejection_reason": null,
  "role": "investigator",
  "specialist_count": 1,
  "expected_value": "high",
  "budget_cap": 3,
  "adversarial_pass_allowed": true,
  "gate_version": "rk2-specialist-gate-v1"
}
```

The gate does not require a particular role or force delegation by complexity level. It must explain the choice in a short, reusable record. The exact fields `considered`, `started`, `trigger`, `evidence_state`, `competing_hypotheses`, `rejection_reason`, and `role` are required even when their values are empty or `null`. This keeps `agent_count=0` from becoming a dark metric.

## 10. Verification, stop, and computer-use boundaries

The v0.1 contracts remain in force:

- verification is a separate phase, not a claim inferred from a plausible diff;
- public and held-out checks remain separate when the task defines them;
- scope, test integrity, dependency integrity, and acceptance evidence are recorded independently;
- the stop gate ends work once the frozen contract is satisfied and unresolved risk is low;
- a failed verification or scope violation remains a failure even if the output looks good;
- computer use remains risk-tiered: `GREEN` for reversible/read-only actions, `YELLOW` for bounded changes with explicit confirmation or review, and `RED` for destructive, irreversible, credential, financial, or safety-critical actions;
- host adapters may impose stricter controls, but the core must not silently weaken them.

## 11. Required telemetry

Every run packet should record the following without recombination:

```text
run_id
task_id
arm
candidate_id
candidate_version
candidate_manifest_sha256
source_tag
source_commit
task_hash
fixture_hash
host_fingerprint
kernel_id / kernel_sha256
module_manifest_sha256
runner_sha256 / adapter_sha256
telemetry_schema_version
kernel_bytes / kernel_tokens
loader_index_bytes / loader_index_tokens
loader_request_count / loader_decision_duration_ms
route
selected_complexity
modules_loaded[]: module_id / module_sha256 / module_bytes / module_tokens / load_reason / load_phase / module_reuse / load_action / previous_sha256 / reload_reason / context_injected
omitted_context: source_manifest_sha256 / module_ids / bytes / tokens / derivation / status
full_bundle_loaded / escalation_reason / requested_by / approved_by_or_gate / source_hash / loaded_bytes / loaded_tokens_if_deterministic
instruction_bytes
specialist_gate: considered / started / trigger / evidence_state / competing_hypotheses / rejection_reason / role
specialist_roles / specialist_count
specialist_reports[]: role / evidence_refs / conclusion / residual_risk / recommended_next_action / report_tokens
verification result
stop decision
provider_status
model_completion_status
task_success
scope_violation
evaluator_validity
input_tokens
cached_input_tokens
output_tokens
reasoning_tokens
total_tokens
tool_calls
agent_count
duration_seconds
changed_files
tests_weakened
dependencies_changed
failure_class
```

The token fields are provider fields. If the provider does not expose `total_tokens`, it remains `null`; no derived total is written. Cached and uncached input remain separate so later billing analysis can use the provider’s actual semantics.

Context-load telemetry should include at least:

```json
{
  "module_id": "debugging",
  "load_reason": "route=debugging; evidence=concurrency_hypothesis",
  "load_phase": "evidence",
  "instruction_bytes": 0,
  "sha256": "provider-or-run-recorded-hash",
  "full_bundle_loaded": false
}
```

The placeholder hash above is illustrative; production packets must contain the actual hash or an explicit `null` with a failure reason.

## 12. Measurable acceptance criteria

These are engineering acceptance criteria for a frozen v0.2 candidate, not public performance claims.

| ID | Criterion | Evidence required |
|---|---|---|
| RK2-AC-01 | **Post-run benchmark target only:** on TASK-001 and TASK-003, C’s per-task median `input_tokens` is no more than `1.25 ×` B’s median. The runtime receives no rule or budget based on this value. | Frozen 3-repeat-per-arm dataset; static prompt/config audit proving the threshold was not runtime input; analysis applies the target only after collection. |
| RK2-AC-01a | The Tiny Kernel stays within the reviewed provisional source/build budget. | CI hard-fails on the selected UTF-8 byte ceiling and reports the pinned token estimate; the budget is not a product claim, and any threshold change versions the design. |
| RK2-AC-01b | Lazy loading has lower measured overhead than the comparable omitted eager context, or is explicitly marked inconclusive when provider attribution is unavailable. | Kernel/index/module bytes and tokens, loader decision cost, load reason, module reuse, and a frozen v0.1 counterfactual ledger. |
| RK2-AC-02 | C has no lower task-success rate than B on the v0.2 regression suite. | Strict task contract, verification output, and failure-class accounting. |
| RK2-AC-02a | **Quality retention is a hard gate:** efficiency or a smaller kernel cannot compensate for a task, verification, scope, or task-specific quality regression relative to B. | Pre-registered task-specific primary outcomes; a lower outcome is candidate FAIL even when `C ≤ 1.25 × B`. |
| RK2-AC-03 | C has no creative scope regression on TASK-002; visual preference is reported separately from task success. | Uniform blind evaluation plus scope and task records. |
| RK2-AC-04 | On tasks where the gate records low expected value, specialist execution remains zero and `agent_count=0`. | Gate decision and host event telemetry in every applicable run. |
| RK2-AC-05 | On an independently authored specialist-appropriate challenge, the gate can start a bounded specialist when the frozen evidence supports it. | Pre-registered challenge, gate record, role report, verification result, and cost/value comparison. |
| RK2-AC-06 | No task exceeds the proposed three-specialist cap or the one-adversarial-pass cap without an explicit validity event. | Per-run specialist ledger. |
| RK2-AC-07 | Normal regression runs do not load the full v0.1 bundle. | `full_bundle_loaded=false`, module manifest, hashes, and instruction-byte totals. |
| RK2-AC-08 | Every run has complete provenance and separates provider, model, evaluator, and scope outcomes. | Schema validation and raw packet audit. |
| RK2-AC-09 | TASK-001/002/003 fixture files, acceptance contracts, and frozen historical records are unchanged. | Before/after hashes and clean source comparison. |
| RK2-AC-10 | Provider-unavailable fields remain `null`, especially `total_tokens`; no token estimate is presented as a provider measurement. | Raw provider event audit. |
| RK2-AC-11 | Every specialist decision contains the complete gate record, including the no-agent rejection path. | Schema validation for `considered`, `started`, `trigger`, `evidence_state`, `competing_hypotheses`, `rejection_reason`, and `role`. |
| RK2-AC-12 | B is the primary efficiency baseline for all simple/medium comparisons; A and D are descriptive controls only. | Pre-registered analysis plan and per-task C-vs-B tables. |

For TASK-002, the `1.25 ×` context target is not the primary gate because its creative artifact and blind-evaluation path have a different context shape. It remains a secondary optimization target and must not be omitted from the report. The TASK-002 quality-retention outcome is still a hard gate under RK2-AC-02a. No runtime component may use the `1.25 ×` target as a token budget or behavior rule.

### 12.1 Frozen primary outcome semantics

The primary outcome for each regression task is frozen before v0.2 candidate data collection. These are evaluation and acceptance rules, not runtime behavior rules, and they cannot be changed after results are observed.

- **TASK-001:** the primary outcome is the frozen deterministic acceptance result, including verification and scope discipline. `PASS` ranks above `FAIL`. `PROVIDER_ABORTED` and `EVALUATOR_INVALID` are excluded from the model-quality comparison rather than relabeled as model failures. When arms share the same frozen correctness outcome, correctness is a tie and efficiency is reported separately.
- **TASK-002:** the primary quality outcome is the existing frozen blind visual-evaluation methodology. Task-contract success and scope discipline remain separate first-class outcomes. The operational order is: `anonymize artifacts → evaluate → freeze rubric/pairwise scores → reveal A/B/C/D mapping → aggregate/report`. The evaluator must not see arm, model, token, or other treatment metadata while scoring. Higher frozen blind rubric results and pairwise preference are better; `EVALUATOR_INVALID` artifacts are excluded from the quality aggregate. A scope/model failure with a visual artifact is not silently removed from visual reporting, but it remains a task failure in the contract analysis. No undisclosed composite score may replace these outcomes. Historical `TASK-002-blind-v1` and `TASK-002-blind-v1.1` records remain unchanged; unblinded rescoring is forbidden, and any correction requires a new evaluator version applied uniformly to the complete frozen artifact set.
- **TASK-003:** the primary outcome is the strict frozen task result: provider completion, public tests, held-out regression, expected duplicate-effect and acknowledgement behavior, scope compliance, test integrity, and dependency integrity. `PASS` ranks above `FAIL`. When arms share the same strict correctness outcome, correctness is a tie and efficiency is reported separately.

Across all three tasks, `MODEL_FAIL`, `EVALUATOR_INVALID`, and `PROVIDER_ABORTED` are distinct, non-interchangeable lifecycle classes. Provider or evaluator invalidity is not a model failure and does not enter a model-quality denominator. These semantics are immutable for the v0.2 regression study.

## 13. Benchmark protocol after implementation

No run starts until the v0.2 candidate, module manifest, telemetry schema, and this protocol are reviewed and frozen.

### 13.1 Regression tasks and arms

Use the existing frozen TASK-001, TASK-002, and TASK-003 materials without edits. Their prompts, fixtures, acceptance contracts, rubrics, validity rules, and run order are immutable for this study. Adding the new v0.2 telemetry fields is allowed; changing an acceptance condition or adding a task-specific hint is not.

| Arm | Condition | Role |
|---|---|---|
| A | Luna vanilla | descriptive lower-context model control |
| B | Luna + frozen Reliable Engineering v0.1 | primary efficiency and correctness baseline |
| C | Luna + ReasonKit v0.2 | treatment condition |
| D | Astra vanilla | descriptive continuity arm; not the primary C-vs-B comparison |

### 13.1.1 Candidate identity and immutable manifest

Every v0.2 candidate has an immutable identity and manifest containing at least:

```text
candidate_id
candidate_version
source_commit
candidate_manifest_sha256
kernel_sha256
module_manifest_sha256
```

The manifest covers the Tiny Kernel file and hash, module registry and hash, every loadable module and hash, the Specialist Gate policy and hash, the telemetry schema/version and hash, and the runner/adapter hashes. Every run packet carries the candidate identity and manifest hash. Any post-freeze change to a covered component creates a new candidate ID, candidate version, and manifest hash. Raw, failed, aborted, and invalid packets remain preserved; a fix or rerun is never presented as the same candidate, and no silent tuning is permitted under an old identity.

For C, the route and lazy-loader telemetry are part of the treatment. The full v0.1 bundle must not be substituted for the v0.2 path.

### 13.2 Run structure

Keep the v0.1 discipline:

```text
pilot smoke: A → B → C → D, kept separate
confirmatory cohort 1: B → C → D → A
confirmatory cohort 2: C → D → A → B
confirmatory cohort 3: D → A → B → C
```

Each confirmatory arm/task cell has three independent repeats. Every repeat uses a fresh model session and fresh isolated workspace. The host, sandbox, network policy, tool permissions, model settings, task prompt, fixture, and verification commands remain fixed within the study.

The model receives only the public task materials. Held-out tests, reference fixes, evaluator-only evidence, and other arm outputs remain unavailable until the model run is complete.

### 13.3 Validity and recovery

Record these fields independently:

```text
provider_status
model_completion_status
task_success
scope_violation
evaluator_validity
failure_class
```

Use `MODEL_FAIL`, `EVALUATOR_INVALID`, and `PROVIDER_ABORTED` as separate classes. A provider recovery gets a new run ID and links to the aborted packet; the original packet is never replaced. An evaluator correction creates a new evaluator version and is applied uniformly to the complete frozen artifact set, never selectively.

Do not tune the host, prompt, bundle, rubric, fixture, or run order after observing a result. If a smoke run exposes a fixture or evaluator defect, preserve the raw record, create a versioned correction, and decide whether the study is invalid before confirmatory collection.

### 13.4 Analysis outputs

Report per arm and per task:

- attempted, provider-completed, model-completed, and provider completion rate;
- model PASS/FAIL and failure classes;
- evaluator-valid quality results;
- scope-violation rate;
- median and variance for input, cached input, output, reasoning, tools, agents, and duration;
- instruction bytes, modules loaded, full-bundle flag, gate decisions, and specialist roles;
- verification, render, keyboard, reduced-motion, journey, or held-out outcomes as applicable;
- blind rubric medians and pairwise win rate for TASK-002;
- `total_tokens` only when the provider exposes it, otherwise `null`.

Primary comparison: **C versus B**. B is designated before data collection as the primary efficiency and task-quality baseline and cannot be replaced after observing results. A and D provide descriptive controls and should not be used to turn a single task into a general model ranking.

## 14. Independent specialist challenge

The existing regression suite is not to be retrofitted to force delegation. The independent challenge is designed **only after the v0.2 implementation is complete and the v0.2 candidate is frozen**. Its author must not use observed v0.2 outputs to plant a known ReasonKit-favorable seam.

The challenge must be independently:

1. specified;
2. fixture-built;
3. acceptance-defined;
4. hidden-regression-tested;
5. rubric- and validity-defined where quality is relevant;
6. hash-frozen before any arm runs.

It may later receive the identifier TASK-004, but TASK-004 is intentionally not designed, outlined, or fixture-tuned in this document. The required sequence is:

```text
review/freeze this spec
  → implement RK2-01..03
  → verify and freeze the v0.2 candidate
  → independently author TASK-004
  → freeze TASK-004
  → benchmark
```

## 15. Research backlog and sequence

### RK2-01 — Tiny Kernel

**Deliverable:** a reviewed kernel contract and measured token/byte budget.  
**Exit:** every always-loaded rule has a stated invariant; route-specific prose is removed from the kernel; no benchmark fixture changes.

### RK2-02 — Lazy Context Loader

**Deliverable:** a module index, small loader interface, provenance/hash record, and load telemetry.  
**Exit:** a normal regression run can explain every loaded module and proves it did not load the full bundle.

### RK2-03 — Evidence-based Specialist Gate + telemetry

**Deliverable:** a gate contract, bounded role adapter, zero-agent path, cap enforcement, and schema validation.  
**Exit:** the gate records both no-agent and started-agent decisions and remains hub-and-spoke.

Recommended implementation order:

```text
RK2-01 → RK2-02 → RK2-03 → local contract tests → frozen benchmark candidate
```

No implementation work should be considered authorized until this document is approved or explicitly revised.

## 16. Risks and open questions

- **Provider cache semantics:** cached input may affect cost differently by provider. Record it, but do not interpret it without provider billing evidence.
- **The 1.25× target:** it is a post-run engineering acceptance target for simple/medium regression tasks, never a runtime rule or product promise. If it is unattainable, record the miss and its cause rather than moving the target after results.
- **Kernel budget calibration:** the provisional byte/token ceilings need real build measurements. Calibrate before candidate freeze; do not tune them after seeing benchmark outcomes.
- **Loader overhead:** retrieval can erase the benefit of lazy loading. Report the loader’s own cost and mark the comparison inconclusive when attribution is unavailable.
- **Zero-agent interpretation:** no specialist may be the correct result. The gate’s evidence and expected-value record matter more than agent count alone.
- **Challenge independence:** the specialist challenge must be authored independently and frozen before model runs to avoid overfitting.
- **Creative module value:** design/taste may be useful only for the design route. Its default inclusion is not assumed.
- **Host variability:** the benchmark must freeze host, sandbox, network, model settings, and tool permissions just as the v0.1 study did.
- **Telemetry overhead:** telemetry must be machine-readable and complete without becoming another large always-loaded instruction bundle.
- **Failure accounting:** provider aborts and evaluator invalidity must remain recoverable history, not be silently counted as model failures.

## 17. Lifecycle and freeze gates

The current document status is `DESIGN_FROZEN`. Design approval and later benchmark acceptance are separate lifecycle events:

```text
DESIGN_FREEZE_PENDING_REVIEW
↓
DESIGN_FROZEN
↓
IMPLEMENTATION_IN_PROGRESS
↓
CANDIDATE_FREEZE_PENDING
↓
V0.2_CANDIDATE_FROZEN
↓
REGRESSION_EVALUATION
↓
V0.2_CANDIDATE_ACCEPTED
or
V0.2_CANDIDATE_REJECTED
```

`DESIGN_FROZEN` means that the interfaces, non-goals, telemetry, and evaluation rules are approved. It does not assert that v0.2 passed a future benchmark. `V0.2_CANDIDATE_ACCEPTED` requires the Section 12 outcomes and the future candidate acceptance gate.

### 17.1 Design freeze gate — complete

```text
[x] v0.1 evidence is traceable to each v0.2 design change
[x] Tiny Kernel boundary, provisional budget, and CI seam are explicit
[x] Lazy loading, deduplication, reuse, escalation, and loader cost are explicit
[x] Specialist consideration, negative invariants, and bounded hub-and-spoke behavior are explicit
[x] Complete provider, context, candidate, and specialist telemetry is defined
[x] The 1.25× target is post-run only and B is the primary efficiency baseline
[x] TASK-001/002/003 rules and TASK-004 independence are frozen
[x] Named v0.2 non-goals are explicit; no new capability is included
```

### 17.2 Candidate acceptance gate — future

These checks apply only after implementation and candidate freeze; they are not prerequisites for `DESIGN_FROZEN`.

```text
[ ] Same or better correctness, scope discipline, verification, and task-specific quality than frozen v0.1/B
[ ] C median context ≤ 1.25 × B on the designated tasks
[ ] Kernel and registry remain within their provisional budgets
[ ] Normal routes are evidence-backed, lazy, deduplicated, and telemetry-complete
[ ] Specialist decisions are bounded and valid no-spawn outcomes are recorded
[ ] No benchmark hints or fixture-aware routing are present
[ ] TASK-004 is independently authored after candidate freeze
[ ] No new product capability exists beyond context reduction and routing observability
```

## 18. Definition of done for this spec

This design/research phase is complete when:

- the observed v0.1 evidence and its interpretation boundary are recorded;
- Tiny Kernel, Lazy Context Loader, and Specialist Gate have small interfaces and explicit seams;
- L0–L4 routing, bounded hub-and-spoke behavior, one adversarial pass, verification, stop, and computer-use risk tiers are specified;
- context, specialist, provenance, and provider-token telemetry are defined;
- non-goals and anti-overclaim boundaries are explicit;
- measurable acceptance criteria and the post-implementation benchmark protocol are frozen;
- TASK-001/002/003 are designated as an unmodified regression suite;
- the independent specialist challenge is deferred until after v0.2 implementation and candidate freeze rather than retrofitted;
- no ReasonKit source, prompt, bundle, fixture, or historical run packet has been changed.

**Final decision gate:** Design review is complete. Implementation planning for RK2-01 through RK2-03 is authorized under this frozen design. v0.1.0 remains the only implemented and benchmarked release until a v0.2 candidate is frozen and evaluated.
