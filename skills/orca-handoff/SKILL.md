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

1. Capture the live Orca state (read-only, `--json`):
   - Current worktree, branch, HEAD, and card comment:
     `orca worktree current --json` / `orca worktree show --worktree current --json`
   - Live checkouts and terminals:
     `orca worktree ps --json`, `orca terminal list --json`
   - Coordination, if a Run is bound: `orca orchestration run-list --json`; for the run,
     `orca orchestration task-list --run <id> --json` (tasks + statuses), unsettled dispatches
     (`dispatch-show --task <id>`), and unread mail (`orca orchestration check --unread --inject`).
     Capture a compact summary, not a dump.
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
## Coordination       (run objective, tasks + statuses, unsettled dispatches, unread mail)
## Plan               (plan.md status + path; setup.md conventions in force)
## Decisions          (what was decided; reference docs/adr/ or issues by path)
## In progress / next (open threads, next steps, who owns what)
## Suggested skills   (orca-resume, orca-orchestrate, ...)
```

## Done when

- Every section comes from a verified Orca read or this session's context, never from memory.
- The rolling file, the snapshot, and the card comment are all written and consistent.
- No secret is present in the document.
