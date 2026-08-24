---
name: forge-brief
description: >-
  Create, update, or validate a product brief: the one-pager that turns a forged
  idea into vision, target users, and success metrics before any spec exists.
  Use when the user says 'create/update/validate the product brief'. Invoke with
  /forge-brief.
disable-model-invocation: true
argument-hint: "Create, update, or validate? For which idea?"
---

# Product brief

The brief is the shortest document that lets a stranger understand what is being built, for whom,
and how success will be recognized. It sits between an idea (forge-idea / forge-prfaq output) and
a spec (forge-spec). Three intents: **create**, **update**, **validate**.

## The seven fields

A complete brief has exactly these — nothing more:

1. **Vision** — one paragraph: what the world looks like when this succeeds.
2. **Target users** — who has the pain, in concrete segments (not "developers", but "solo devs
   shipping their first SaaS on a budget"). Named anti-users are welcome: who this is *not* for.
3. **Problem** — what they do today instead, and what it costs them (time, money, risk).
4. **Solution** — what we build, at capability level. No UI, no stack.
5. **Differentiation** — why us, why now; what incumbents cannot easily copy.
6. **Success signal** — how anyone will know it worked: user-observable outcomes first, then the
   metric that proves it. If the metric needs instrumentation that does not exist yet, say so.
7. **Scope fence** — explicitly out: platforms, personas, features deferred. This field is what
   stops workers from drifting later.

## Create

Interview until every field holds. Push back on vague segments ("power users") and unfalsifiable
success signals ("users love it"). Write `docs/brief.md` (or `docs/brief-<slug>.md` when several
coexist). A field that genuinely cannot be filled gets `<open question>` — never filler.

## Update

Read the existing brief, apply what changed (new decision, pivot, market shift), keep a short
changelog section at the bottom. Re-run validate after.

## Validate

Attack each field: Is the segment real (could you name 5 of them)? Does the problem statement
survive "so what?"? Is the differentiation durable or a feature gap? Is the success signal
measurable before launch ends? Findings become edits or marked open questions. A validated brief
is the natural input to `/forge-spec`.
