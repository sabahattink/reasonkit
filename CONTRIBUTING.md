# Contributing to ReasonKit

Thank you for helping make model-agnostic orchestration more useful and more
honest. The project values small interfaces, explicit evidence, and practical
verification over large prompt collections.

## Before opening a change

- Read README.md and skill/SKILL.md.
- Keep the change inside one clear protocol, policy, role, or adapter seam.
- Prefer a concise reusable rule over a long model-specific prompt.
- State whether a claim is observed, derived, hypothetical, or unknown.
- Do not add provider claims, benchmark numbers, customer stories, or field
  results without evidence.

## Design expectations

- Keep the orchestrator hub-and-spoke.
- Add a specialist only when it resolves a distinct seam.
- Keep one adversarial pass as the default maximum.
- Preserve L0-L4 ceilings and make any exception explicit.
- Use tools before spending more tokens.
- Treat visual output as incomplete until it has been rendered and inspected.
- Keep Computer Use GREEN, YELLOW, and RED gates intact.
- Never hide destructive, credential, financial, or safety-sensitive effects
  behind a generic "execute" instruction.

## Documentation changes

Every protocol or role prompt should answer: when it runs, what it receives,
what it may do, what it returns, and how its work is verified. Cross-links
should use repository-relative paths and point to a concrete policy or example.

## Pull request checklist

- [ ] The change has a focused purpose and a small interface.
- [ ] The relevant README or protocol reference is updated.
- [ ] Budgets, stop conditions, and safety gates remain explicit.
- [ ] New claims have evidence or are labelled as assumptions.
- [ ] Markdown links and required files are valid.
- [ ] Evaluation coverage is added or the missing coverage is explained.

## Code of conduct

Be precise, constructive, and respectful. A disagreement should identify the
assumption, evidence, and consequence that differ. See the MIT License for the
terms governing contributions to this repository.
