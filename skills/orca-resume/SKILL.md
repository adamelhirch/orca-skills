---
name: orca-resume
description: >-
  Resume an Orca project in a new orchestrator session: load the handoff doc,
  reconcile it with live Orca state, flag drift, and re-anchor the work.
  Orchestrator sessions only. Invoke with /orca-resume.
disable-model-invocation: true
argument-hint: "What are we picking up?"
---

# Resume an Orca project

Re-anchor into an Orca project from a fresh orchestrator session. Reconstruct context from the
handoff document plus live Orca state — never from memory about what was supposed to happen.

## Load the guides before any command

```text
orca skills get orca-cli
orca skills get orchestration
```

## Steps

1. Find the handoff first: `docs/agents/handoff.md` (rolling) and the most recent snapshot in
   `docs/agents/handoffs/`. Load it as the working context.
2. Reconcile it against live Orca state:
   - `orca worktree current --json` / `orca worktree show --worktree current --json`
     (worktree, branch, HEAD, card comment)
   - `orca worktree ps --json`, `orca terminal list --json`
   - Coordination, if a Run is bound: `orca orchestration run-list --json`, then
     `task-list --run <id> --json` and `orca orchestration check --unread --inject`.
   - Flag every drift between the document and reality: a `worker_done` received since the
     handoff, a changed comment, a merged branch, a closed terminal, an advanced Run.
3. Produce the resume: the project, the current worktree/branch, the last known status, the
   open threads, and the next steps — corrected by the drift. Set the working method: comment
   milestones on the card (`orca worktree set --worktree active --comment ...`); keep the
   `orca-cli` vs `orchestration` boundary (simple ownership handoffs via `orca-cli`, supervised
   coordination via `/orca-orchestrate`).
4. Close the loop: update the card comment with the resume status, e.g.
   `orca worktree set --worktree active --comment "resumed; <status>"`.

If no handoff exists, re-orient purely from live Orca state (same reads, no document) and say
so — the context is thinner and everything above comes from the reads alone.

## Done when

- The summary names the project, the current worktree/branch, and its last status — all from
  verified reads, not inference.
- Every drift between the handoff document and live state is called out.
- The next steps and ownership are unambiguous, and the card comment reflects the resume.
