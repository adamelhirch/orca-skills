---
name: forge-correct-course
description: >-
  Manage significant changes mid-run: a spec/plan meets reality (pivot, blocker,
  new constraint), decide what amends vs restarts, and update the affected docs
  with traceability. Use when the user says 'correct course' or reality just broke
  the plan. Invoke with /forge-correct-course.
disable-model-invocation: true
argument-hint: "What changed and which run/docs does it hit?"
---

# Correct course

Reality invalidated part of the plan. Decide deliberately — amend, pivot, or abort — then make
the docs tell the truth again. This skill runs **during** execution; it is not a retro
(`/forge-retrospective` closes work) and not a re-plan (`/orca-plan` starts one).

## Trigger inventory

Establish what actually changed, from evidence:

- **Spec-level** — a capability died, an assumption got refuted, a constraint appeared
  (compliance, provider outage like a model/endpoint going away).
- **Plan-level** — task decomposition wrong (shared-file conflicts, tasks over a context window),
  dependency edge missing, runtime/sandbox limit discovered.
- **External** — market/pricing shift, upstream API change, team availability.

## The decision

For each trigger, exactly one outcome:

- **Amend in place** — bounded change: edit the spec/plan sections concerned, keep ids stable,
  note the amendment inline. For changes that do not cascade.
- **Structured pivot** — a load-bearing decision flipped. Re-open only the frontier questions
  downstream of it (the design-tree rule), get explicit user sign-off on the new branch, rewrite
  the affected docs, and mark superseded decisions `superseded by <date>` — never delete them.
- **Abort scope** — the change invalidates the Why. Kill it cheaply and record why; a clean abort
  is a correct-course success, not a failure.

## Traceability duty

Every amendment records: what triggered it (dispatch id / finding / research artifact), which
docs changed, which in-flight tasks are affected (continue-as-is / needs-rebrief via coordinator
reply / abandon), and who decided. In an Orca run, affected workers get their rebrief through
`orchestration reply`, gates get opened for user decisions, and the handoff doc gets the course
change so the next session inherits truth instead of archaeology.

## Anti-patterns this skill exists to kill

Silent drift (workers adapting without docs changing), zombie plans (docs updated but nobody told
running workers), and pivot-by-vibes (load-bearing flips without user sign-off).
