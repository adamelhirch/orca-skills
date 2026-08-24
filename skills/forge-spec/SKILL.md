---
name: forge-spec
description: >-
  Distill any intent input — idea, brief, PRD, transcript, brain dump — into the
  SPEC kernel (Why, Capabilities, Constraints, Non-goals, Success signal): the
  machine contract downstream skills consume. Use when the user says 'create a
  spec', 'distill this into a spec', or 'validate this spec'. Invoke with
  /forge-spec.
disable-model-invocation: true
argument-hint: "Input to distill (path, paste, or describe)?"
---

# Spec kernel

The canonical transformer: any intent input becomes **SPEC.md** carrying the five-field kernel —
the machine contract every downstream skill consumes (`/orca-plan` reads it as objective +
constraints; workers meet it again in their task specs). Same slug = same spec folder; a second
run updates in place.

## Input handling

Accept anything: a file path, pasted text, a verbal brain dump, a PRD path, a forged idea doc.
Classify silently and extract what serves the kernel. Missing input: ask for one source — do not
interview here (that was forge-idea / forge-brief's job); this is distillation, not discovery.
Headless callers pre-supply input + slug.

## The five-field kernel

Every field is load-bearing; none may be empty:

1. **Why** — the root need (from five-whys, not the surface request).
2. **Capabilities** — what the thing does, numbered C-n, each independently verifiable.
3. **Constraints** — hard boundaries: performance budgets, compliance, stack decisions,
   environment limits. A constraint the worker can check beats one it must believe.
4. **Non-goals** — explicit exclusions. This field prevents drift more than any other.
5. **Success signal** — how anyone verifies the whole thing worked, end to end.

Rules of distillation:

- Preserve intent, compress prose. If a source sentence carries a decision, it lands verbatim-ish;
  if it carries only discussion, it dies here.
- Anything load-bearing that does not fit the kernel goes in a companion file in the same folder
  (`decisions.md` for settled context, `assumptions.md` for unverified claims) — referenced from
  SPEC.md by relative link, never inlined into the kernel.
- Unverified but necessary claims enter marked `ASSUMPTION:` so downstream verify-spec-facts rules
  pick them up as probes.

## Workspace

`docs/specs/spec-<slug>/SPEC.md` (+ companions). The folder is the unit: validate/update operate
on it whole.

## Validate mode

Check the kernel against its sources and against itself: every capability maps to the Why; every
constraint is worker-checkable; non-goals contradict nothing; the success signal is observable
without heroics. Findings become edits or marked assumptions. A validated spec is the ideal
`/orca-plan` input — plan cites it instead of re-deriving intent.
