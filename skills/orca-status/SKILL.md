---
name: orca-status
description: >-
  Read-only status sweep of an Orca project: cockpit worktree, Run and task DAG,
  unsettled dispatches with their age against the plan budget, pending decision
  gates, worker terminal accounting (leaked terminals), unread mail, and the
  pipeline docs (setup gate, plan approval, handoff age). Renders one dashboard
  and names what needs a decision. Changes nothing and consumes no mail — safe to
  run at any point in a run. Orchestrator sessions only. Invoke with /orca-status.
disable-model-invocation: true
argument-hint: "Which run or project?"
---

# Orca project status

Answer "where does this run actually stand?" in one pass, without blocking and without changing
anything. `/orca-orchestrate` waits — it tells you nothing until a message arrives. This is the
instrument for every other moment: mid-run when a worker has been quiet, before a handoff, after
a resume, or when the host feels loaded and you suspect leaked terminals.

It is also the **shared read sweep**: `/orca-resume` and `/orca-handoff` both need exactly this
picture, and both should run this rather than re-deriving it.

## Read-only contract

Every command below is a read. Two traps make that non-obvious, and both are real:

- **`orca orchestration check --unread` marks messages read.** Use **`--peek`** (unread, without
  marking) or `--all` (everything, does not mark read). Never `--unread` here, and never `--ack`
  — acknowledging is a coordination act that belongs to `/orca-orchestrate`'s loop. Consuming the
  mailbox during a status read is how a `worker_done` gets lost.
- **There is no `--inject` flag on `check`** (it fails with `invalid_argument`). Do not pass it.

Do not dispatch, merge, resolve, release, or write. If the sweep reveals something that needs
acting on, report it and hand off to the skill that owns the action.

## The sweep

Run these and keep a compact summary of each — never dump raw JSON at the user.

```bash
# 1. Cockpit: are we even in the right worktree?
orca worktree current --json          # isMainWorktree must be true to coordinate
orca worktree show --worktree current --json   # branch, HEAD, card comment
orca worktree ps --json                        # live checkouts

# 2. The run and its DAG
orca orchestration run-current --json          # what this terminal is bound to
orca orchestration run-list --json             # other runs, if none is bound
orca orchestration task-list --run <run_id> --json          # every task + status
orca orchestration task-list --run <run_id> --ready --json  # what could start now

# 3. What is waiting on a human
orca orchestration gate-list --run <run_id> --status pending --json

# 4. Workers and terminals (accounting is tracked separately from task status)
orca orchestration worker-list --run <run_id> --json
orca orchestration worker-list --terminal-state reclaimable --json
orca terminal list --json
orca orchestration dispatch-show --task <task_id> --json    # per unsettled task

# 5. Mail, without consuming it
orca orchestration check --peek --json
```

Then read the pipeline docs in the repo: `docs/agents/setup.md` (merge gate mode, tracker),
`docs/agents/plan.md` (`Status: approved|draft`, task ids, `budget:` per task), and
`docs/agents/handoff.md` (its date — how stale the durable context is).

## The report

Render one dashboard, ordered so the things needing a decision come first:

```
# Status — <repo> — <date>

## Needs a decision        ← always first; "nothing" is a valid and welcome answer
  - pending gates (id, task, question) — these BLOCK the DAG until resolved
  - dispatches past their plan budget
  - tasks failed with dependents blocked
  - a succeeded report whose evidence does not match the setup merge gate

## Run                     objective, run id, and tasks by status
                           (completed / running / ready / blocked / failed)
## In flight               per unsettled dispatch: task, worker handle, elapsed,
                           budget from the plan, and last-known activity
## Terminals               active / retained / reclaimable
                           (reclaimable = finished work still holding a terminal — a leak)
## Mail                    unread count by type, peeked not consumed
## Cockpit                 worktree, branch, HEAD, card comment, isMainWorktree
## Pipeline docs           setup merge gate + tracker; plan status; handoff age
## Drift                   where the docs and live state disagree
```

Rules for the report:

- **Elapsed vs budget, not elapsed alone.** "Running 40 min" means nothing; "running 40 min
  against a 30 min budget" is a decision. Take the budget from the plan's `budget:` field
  (default 60 min).
- **A quiet worker is not a stuck worker.** Idle, a timeout, or a missing heartbeat mean alive,
  not done. Report the fact; never conclude failure from silence, and never act on it here.
- **Name the merge gate explicitly** (`github-actions` / `local <command>` / `unverified`). A run
  proceeding under `unverified` should be visible every single time it is looked at.
- **`reclaimable` terminals are always worth naming.** Orca does not reclaim terminals it did not
  create through `worker-start`, so the `external_terminal` workers `/orca-orchestrate` launches
  accumulate silently.
- Close with a one-line verdict: **healthy / waiting on a worker / waiting on you / stalled**,
  and the single next action.

## When there is no bound Run

Say so plainly and report what still applies: the cockpit, the pipeline docs, any other runs from
`run-list`, and leaked terminals. Never bind a Run to produce a nicer report — binding is a
coordination act, and this skill does not coordinate.

## Done when

- The user has one dashboard whose first section is what needs a decision.
- Every number came from a verified read this session, not from the handoff or from memory.
- Nothing was changed: no ack, no dispatch, no merge, no gate resolved, no mail consumed.
