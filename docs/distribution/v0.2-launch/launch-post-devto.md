# DEV.to technical article draft

## Title

ReasonKit v0.2: routing the smallest useful reasoning context

## Introduction

Reasoning prompts tend to grow by accumulation. A new task gets another policy, another role, another protocol, and eventually every run carries a large undifferentiated bundle.

ReasonKit v0.2 takes a narrower approach: classify the task, load the relevant context, authorize bounded specialists only when needed, verify the result, and stop.

This is a prompt-pack and orchestration contract. The host still supplies the model, tools, permissions, and runtime.

## What changed from the v0.1 work

The v0.1 evidence made a useful limitation visible: broad context can add overhead without reliably changing the evaluated outcome. v0.2 therefore focused on selective context and observability rather than adding a larger specialist system.

The release includes a compact kernel, a module registry, task-shaped protocols, bounded specialist rules, provider-neutral adapters, and structured expectations for provenance, verification, and stopping.

## The runtime loop

```text
classify → evidence → bounded specialists only when needed → execute → verify → stop
```

The default path is intentionally small. A task can complete without a specialist. The full bundle is reserved for explicit escalation rather than loaded by default.

## A concrete held-out result

On one frozen held-out debugging task, all four tested conditions scored 4/4. The ReasonKit condition selected the debugging route, loaded only `protocol.debugging`, started no specialist, and kept the full bundle disabled.

Its measured provider input was 155,471 versus 169,228 for Luna plus the Reliable Engineering baseline: 8.1% lower in that comparison. This is one task, one successful final run per arm, and not statistically significant. It does not show a quality advantage. Astra vanilla used the least measured input and output overall in the same run.

## How to try it

There is no package install or runtime client in v0.2.0. Clone the frozen release, open `dist/v0.2/reasonkit-kernel.md` with `adapters/generic/SYSTEM.md`, and add the protocol that matches the task. Give the host one real task, its constraints, and the acceptance condition.

Start with one task in one repository. Record whether setup was clear, which task category you tried, what the host returned, and whether you would use ReasonKit again. Do not share private repository contents.

## What this release does not claim

- It does not make a weaker model equivalent to a stronger model.
- It does not beat Astra or any provider baseline.
- It does not claim universal token savings.
- It does not include provider runtime integrations or a hosted telemetry service.
- It does not turn one benchmark task into a general statistical conclusion.

## The distribution experiment

The next 30 days are deliberately adoption-focused. The primary signal is second use. The target is 20 real tries, 5 repeat users if measurable, 5 concrete feedback items, and at least 3 task categories.

If you try it, the most useful response is not a star. Tell us where it helped, where it got in the way, and whether you came back for a second task.

Release: https://github.com/sabahattink/reasonkit/releases/tag/v0.2.0

Feedback: https://github.com/sabahattink/reasonkit/issues/new/choose
