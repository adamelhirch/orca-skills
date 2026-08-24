---
name: forge-ux
description: >-
  Plan UX patterns and design specs: flows per user journey, screen inventory,
  interaction states, and acceptance criteria designers/devs share. Use when the
  user says 'plan the UX', 'create UX specs', or after PRD stories exist that
  touch interfaces. Invoke with /forge-ux.
disable-model-invocation: true
argument-hint: "Which stories/journeys to design?"
---

# UX plan

Turn PRD stories into interface plans precise enough that implementation tasks carry real
acceptance criteria — without designing pixels prematurely. Gate: `docs/prd.md` (or stories in a
spec) should exist; if nothing downstream consumes the flows yet, a rough pass is fine.

## Output

`docs/ux/<slug>/ux-plan.md` with:

1. **Journeys** — per target-user story: the happy path as numbered steps (user action → system
   response), plus the top 2 failure paths per journey (what if the network dies mid-step, the
   input is invalid, the user goes backwards).
2. **Screen inventory** — one entry per screen/surface: purpose in one sentence, entry points,
   exit points. Screens nobody enters are deleted features; catch them here.
3. **States matrix** — per critical surface: empty, loading, error, success, edge (long content,
   no data, permission denied). The states nobody designs are the bug reports nobody wants.
4. **Interaction patterns** — only where non-obvious: how destructive actions confirm, how async
   work communicates progress, what keyboard/mobile parity requires.
5. **Acceptance criteria hooks** — map each journey step to the FR/story id it realizes, so
   `/orca-plan` can cut UI tasks whose tests reference real behavior.

## Working rules

- Flows before screens: a flow that cannot be drawn as steps is not understood yet.
- Copy matters: draft the actual microcopy for error and empty states (users read those more than
  any marketing page). Vague copy in the plan becomes vague UI in the product.
- Accessibility is a state-matrix column, not a postscript: focus order and contrast constraints
  land with each surface.
- Do not specify visual design (colors, type, spacing) beyond constraints — that belongs to a
  design phase or a style guide, not to planning.
