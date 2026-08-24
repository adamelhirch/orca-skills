---
name: forge-retrospective
description: >-
  Evidence-based retrospective over completed work (an epic, a release, a set of
  merged runs): collect artifacts, verify findings against sources, render verdict
  and process changes. Use when the user says 'retro this epic/release/project'
  or after closing a major milestone. Invoke with /forge-retro.
disable-model-invocation: true
argument-hint: "What are we retrospecting (epic/runs/milestone)?"
---

# Retrospective

An evidence-based retro over finished work: what was produced, what it cost, what the process got
wrong, and which changes survive contact with the evidence. Never state time estimates — AI-era
development speed makes hour/day predictions noise; count tasks, PRs, retries instead.

## Phases

### 1. Collect

Inventory from real sources only: merged PRs, task statuses, handoff docs, post-mortems, CI
history, the plan(s) the work came from. List them; everything later cites this list. Missing
records are themselves a finding (observability gap).

### 2. Verify

For every candidate claim ("t3 needed two retries", "the merge gate held"), check the source
before it becomes a finding. A claim that cannot be verified is dropped or logged as anecdote —
clearly separated from evidence. This phase exists because retrospectives lie by compression:
memory keeps the drama, drops the base rates.

### 3. Analyze

Compare intended vs as-built per dimension:

- **Estimation quality** — planned task count/size vs actual; which splits were wrong.
- **Failure taxonomy** — every retry/failure classified (spec defect, runtime limit, model
  degeneracy, integration conflict); counts per class.
- **Gate integrity** — did anything merge without its gate? did gates ever pass vacuously?
- **Knowledge flow** — did discoveries get written to durable sinks, or re-derived?
- **Human-gate latency** — where did decisions stall?

### 4. Verdict + changes

Render: what worked (keep doing), what failed (stop doing), what to change (specific, owned,
checkable). Each proposed change names its mechanism — a contract line, a skill patch, a plan-schema
field — not a sentiment. End with at most 3 changes; a retro producing ten actions produces none.

## Output

`docs/retro/<slug>.md`: evidence inventory → verified findings (each with source) → verdict →
changes with owners. If this project runs Orca orchestration, feed the changes to their targets:
contract edits land via `/orca-setup`'s composition, planning changes in `/orca-plan`, and the
whole thing links from the next `/orca-handoff`.
