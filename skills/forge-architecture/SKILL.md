---
name: forge-architecture
description: >-
  Produce the architecture spine: invariants, boundaries, and technical decisions
  projected from a spec — lean by design, just enough to keep everything built
  from it consistent. Use when the user says 'create the architecture' or 'design
  the system' after a spec/brief exists. Invoke with /forge-architecture.
disable-model-invocation: true
argument-hint: "Spec or brief to project from?"
---

# Architecture spine

Produce the *lean spine*: the smallest set of decisions that keeps everything later built
consistent. Not a diagram museum — an invariant list workers can hold in their heads. Gate:
`docs/specs/spec-*/SPEC.md` (or at minimum `docs/brief.md`) must exist; architecture invented
before intent is fiction.

## The spine

Write `docs/architecture.md` with exactly these sections:

1. **Invariants** — numbered INV-n: properties that must hold forever ("every write goes through
   the repository layer", "no PII outside the EU region", "all state changes emit events"). These
   are checkable in review; each one names its enforcement point (lint rule, test seam, review
   checklist line).
2. **Boundaries** — the modules/layers and what crosses them. One paragraph per boundary: what it
   owns, what it never touches. Deep-module vocabulary welcome: narrow interfaces, hidden
   implementation.
3. **Decisions** — ADR-style one-liners with their rejected alternatives (ADR-n: chose X over Y
   because Z). Irreversible or expensive-to-reverse decisions live here; reversible ones do not
   earn an entry.
4. **Data shapes** — entities and their relationships at field level where it matters, hand-wavy
   where it does not. The test: two workers implementing different modules against this section
   produce compatible code without talking to each other.
5. **Failure posture** — what happens when each external dependency is down; where state can
   tear; what gets retried vs surfaced.

## Working rules

- Project from the spec's constraints; every NFR/Constraint must be visible somewhere in the
  spine or explicitly deferred with a reason.
- Prefer boring and proven; novelty must buy something the spec demands.
- When a decision could go two ways and neither is clearly better, present both with costs and
  ask — architecture decisions are user decisions when reversible-but-expensive.
- Keep it under ~2 pages. If section 3 exceeds ~10 ADRs, some of those decisions belong at task
  level instead.

## Validate mode

Re-read the spec next to the spine: every constraint honored? every capability implementable
without violating an invariant? any invariant unenforceable as written? Findings become edits.
