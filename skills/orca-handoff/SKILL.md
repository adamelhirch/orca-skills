---
name: orca-handoff
description: >-
  Write a durable Orca project handoff (Orca state + session context) so a new
  orchestrator session can resume without losing context. Orchestrator sessions
  only. Invoke with /orca-handoff.
disable-model-invocation: true
argument-hint: "What will the next session focus on?"
---

# Orca project handoff

Capture where an Orca project stands — live Orca state plus the session's decisions and next
steps — into a durable document the next orchestrator session loads (`/orca-resume`). The
document lives in the repo at `docs/agents/handoff.md` (rolling) with timestamped snapshots
under `docs/agents/handoffs/`. It carries the pipeline state: the setup marker
(`docs/agents/setup.md`) and the current plan (`docs/agents/plan.md`) are part of what a fresh
session needs to resume.

## Load the guides before any command

```text
orca skills get orca-cli
orca skills get orchestration
```

## Steps

1. Capture the live Orca state with the **`/orca-status` sweep** — that skill owns the read-only
   reconstruction (cockpit worktree/branch/HEAD/card, run + task statuses, unsettled dispatches,
   pending gates, terminal accounting including `reclaimable` leaks, peeked mail). Capture its
   compact summary, not a JSON dump, and do not hand-roll a second copy of the sweep here.

   Mail is read with `check --peek`, never `--unread` and never `--ack`: a handoff that consumes
   the mailbox hands the next session a run whose messages have silently disappeared.
2. Capture the session context from this conversation: what was done, decisions made, open
   threads, and next steps. Reference artifacts by path instead of duplicating them
   (CONTEXT.md, docs/adr/, issues, PRs, specs, and the pipeline docs — `docs/agents/plan.md`,
   `docs/agents/setup.md`). Add a "suggested skills" section. Redact any
   secret (API keys, tokens, PII).
3. Write `docs/agents/handoff.md` (rolling, overwrite) and a snapshot
   `docs/agents/handoffs/<YYYY-MM-DD>-<slug>.md`.
4. Point the card at it: `orca worktree set --worktree active --comment "handoff → docs/agents/handoff.md"`.

## Document schema

```
# Handoff — <repo> — <date>

## Summary            (2-3 lines: where the project stands)
## Orca state         (worktree/branch/HEAD, card comment, live terminals)
## Coordination       (run objective, tasks + statuses, unsettled dispatches, pending gates,
                      unread mail, terminals still live)
## Plan               (plan.md status + path; setup.md conventions and merge-gate mode in force)
## Decisions          (what was decided; reference docs/adr/ or issues by path)
## In progress / next (open threads, next steps, who owns what)
## Suggested skills   (orca-resume, orca-orchestrate, ...)
```

## Done when

- Every section comes from a verified Orca read or this session's context, never from memory.
- The rolling file, the snapshot, and the card comment are all written and consistent.
- Pending gates and still-live terminals are named — a handoff that omits them hands the next
  session a run that looks idle but is actually blocked or leaking.
- No secret is present in the document.
