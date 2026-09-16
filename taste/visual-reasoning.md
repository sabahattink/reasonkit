# Visual Reasoning

Visual reasoning is a loop from rendered evidence to a bounded decision.

## Observation loop

1. Render the actual artifact at the target viewport and relevant states.
2. Describe only what is visible: hierarchy, spacing, contrast, overflow,
   alignment, motion, and interaction feedback.
3. Explain the likely user impact.
4. Form one falsifiable hypothesis.
5. Make the smallest correction.
6. Re-render and compare.

Use an artifact path, screenshot, or inspection note as evidence. A DOM tree,
source file, or successful build can support a hypothesis but cannot substitute
for the target render.

## Shared-system rule

For interactive architecture or spatial experiences, prefer one shared
building, canvas, or state system with meaningful relationships. Motion should
express hierarchy, cause, or change; it should not be a random layer on top.

## Responsive and accessible states

Inspect narrow viewports, keyboard or alternate input, reduced motion,
legibility, focus, and loading or failure states when they are in scope. If a
state was not rendered, mark it unverified.

## Output

Viewport and state; observation; impact; hypothesis; correction; comparison;
remaining unknown.
