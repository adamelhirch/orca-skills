---
name: forge-review
description: >-
  Multi-lens adversarial review over any diff, spec, doc, or artifact — edge
  cases, verification gaps, security/quality — with structured findings. Use when
  the user says 'review this', 'run a review', or before merging significant work.
  Invoke with /forge-review.
disable-model-invocation: true
argument-hint: "What to review (path/diff) + lenses?"
---

# Multi-lens review

Review any content — diff, branch, file, spec, plan, document — through independent adversarial
lenses. Overlap between lenses is signal, not duplication.

## Inputs

- **content** — path, diff ref, pasted text; classify silently as code or docs.
- **lenses** (optional) — explicit selection below; default = every applicable lens for the class.

## The lenses

| Lens | Applies to | Attacks |
| --- | --- | --- |
| **edge-case-hunter** | code + behavior docs | Unhandled inputs, boundaries off-by-one, empty/error states, concurrency tears. For each: trigger condition + concrete consequence |
| **verification-gap** | code + specs | Claims without tests, acceptance criteria untestable as written, "should" language hiding unverified behavior |
| **adversarial-general** | any | How does this get misused, gamed, or fail under load? What would its harshest reviewer say first? |
| **security** | code + data docs | Injection surfaces, authz gaps, secrets handling, unsafe deserialization, PII flows |
| **clarity** | docs | Ambiguity a worker/implementer could resolve two ways; missing definitions; contradictions |

## Execution

1. Announce in one line: content class + lenses running.
2. Run selected/applicable lenses **independently** (parallel subagents where available: give each
   only the lens brief + content location + "Return ONLY findings"). A lens sees content, never
   another lens's output — independence is where coverage comes from.
3. Assemble all findings; keep duplicates across lenses and mark them (two lenses finding the same
   defect raises its priority).

## Findings format

Each finding carries: `lens`, `location` (file:line / section), `trigger_condition` (one line),
`potential_consequence`, `guard_snippet` (concrete fix or test sketch). Severity is implied by
consequence, not asserted — the reader triages.

## Triage

Group at the end: **must-fix before merge** (exploitable/corrupting/unverifiable), **fix-forward**
(bounded follow-up task), **note** (context for later). In an Orca run, must-fix findings on a
worker's PR block the merge gate; fix-forwards become tasks via `/orca-tasks`.
