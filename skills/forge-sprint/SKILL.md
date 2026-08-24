---
name: forge-sprint
description: >-
  Gate planning readiness, cut epics/stories into sprint-sized slices, and track
  sprint progress against them. Use when the user says 'plan the sprint',
  'sprint status', or 'are we ready to execute'. Invoke with /forge-sprint.
disable-model-invocation: true
argument-hint: "Plan readiness, cut stories, or status?"
---

# Sprint planning & tracking

Bridge intent documents and execution — three modes sharing one source of truth
(`docs/sprints/sprint-status.md`):

## Mode 1: readiness gate

Before committing to a sprint, verify the inputs exist and cohere: spec validated (or PRD + brief),
architecture spine covering the constraints, UX flows for interface stories, and — when this will
run as Orca orchestration — setup marker present. Output a checklist verdict: ready / blocked with
the named gaps. Refuse to cut stories from unvalidated intent; that debt is paid at 10× during
execution.

## Mode 2: cut epics/stories

Slice requirements into stories small enough to finish in one focused pass (one worker context
window in Orca terms):

- Per story: id, title, story sentence, acceptance criteria (testable, numbered), dependencies,
  size guess relative to siblings (S/M/L — never hours), files/modules touched.
- Epic = coherent delivery slice; stories within share a definition of done.
- Flag cross-story shared files explicitly — they are scheduling conflicts (/orca-plan's file-
  ownership rule applies downstream).
- Write `docs/sprints/<n>-<slug>.md`; create/update `sprint-status.md` with per-story states.

## Mode 3: status

Read-only sweep of current state: stories done/in-progress/blocked vs plan, blockers named,
what changed since last look, drift between status doc and reality (verify against git/tracker,
not vibes). No edits; findings only.

## Handoff to Orca

Stories cut here map 1:1 onto `/orca-plan` task blocks (story → task spec, deps → blocked-by);
`sprint-status.md` mirrors dispatch states after each run settles. Keep the two directions
explicit so neither document lies about the other.
