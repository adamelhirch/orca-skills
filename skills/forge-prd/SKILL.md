---
name: forge-prd
description: >-
  Create, update, or validate a PRD: requirements and functional scope derived
  from a brief, precise enough to derive tasks from later. Use when the user says
  'create/edit/validate the PRD' or 'turn the brief into requirements'. Invoke
  with /forge-prd.
disable-model-invocation: true
argument-hint: "Create, update, or validate? From which brief?"
---

# PRD

Turn a validated brief (`docs/brief.md`) into requirements precise enough that `/orca-plan` can
later cut them into worker-sized tasks without inventing scope. Three intents: **create**,
**update**, **validate**. Gate: if no brief exists, route to `/forge-brief` first — a PRD grown
from nothing inherits nothing checkable.

## Structure

Write `docs/prd.md` (or `docs/prd-<slug>.md`) with:

1. **Objective** — lifted from the brief's vision; one paragraph, unchanged.
2. **Users and stories** — per target segment, "As <user>, I can <capability>, so that <outcome>."
   Stories are capabilities users have, not screens they click.
3. **Functional requirements** — numbered FR-n, each testable in one sentence. "Fast" is not a
   requirement; "search returns results in <300ms for a 10k-row dataset" is. Every FR traces up
   to a story; a story with no FR is vapor.
4. **Non-functional requirements** — NFR-n: performance budgets, security posture, data handling,
   compliance constraints (RGPD etc.). These become worker constraints verbatim later.
5. **Out of scope** — copied from the brief's fence and extended. Repetition here is duty, not
   redundancy: this list is what workers read.
6. **Open questions** — each with its resolution path (research probe, user answer, spike task).

## Create

Work story-first: extract stories from the brief, then derive FRs per story, then sweep NFRs.
Interview the user only where the brief is silent or contradictory — do not re-litigate settled
decisions.

## Update

Apply changes, renumber carefully (FR ids are referenced by tasks and tests downstream), log the
change per section. Renaming or deleting an FR requires checking where it was cited.

## Validate

Three passes, in order:

- **Traceability** — every story has ≥1 FR; every FR cites its story; nothing in Out of scope
  contradicts an FR.
- **Testability** — read each FR as if writing its acceptance test next week. Any FR you cannot
  turn into a test gets rewritten or flagged.
- **Worker-fit** — could each FR be verified by one worker in one worktree? Requirements needing
  three subsystems at once get decomposed now, by you, not discovered mid-run.

Output the findings as edits or open questions; a validated PRD feeds `/forge-spec` (machine
contract) or directly `/orca-plan` for small-enough scopes.
