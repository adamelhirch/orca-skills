---
name: orca-plan
description: >-
  Brainstorm an Orca run with the user before any worker runs: grill the objective
  until the agent and the user share a mental model, then write docs/agents/plan.md
  and get explicit approval before tasks are cut. Orchestrator sessions only.
  Invoke with /orca-plan.
disable-model-invocation: true
argument-hint: "What are we planning?"
---

# Plan an Orca run

Turn an objective into a shared, approved plan before any task is cut. This is the brainstorm
step of the pipeline (`/orca-setup` → `/orca-plan` → `/orca-tasks` → `/orca-orchestrate`). The
orchestrator interrogates the objective relentlessly until the agent and the user are on the
same page, then writes a durable plan document the next skills consume.

## Gate

Check the setup marker first: if `docs/agents/setup.md` does not exist, route the user to
`/orca-setup` before planning (the conventions — CI-green, one-task-one-branch, TDD — come
from setup).

## The interview

Work the objective as a **design tree** in **rounds**. Every decision branches into the
decisions that hang off it; the **frontier** is every decision whose prerequisites are already
settled — the questions you can ask *now* without guessing at answers you haven't heard yet.
Ask the whole frontier in one round; then wait for the user's answers before the next round.

Per-question format:

```
❓ **Q<n>** - **<question title>**: <question body, might be multiple paragraphs, options>

➡️ <your recommended answer>
```

Each round the user's answers reshape the tree — settled decisions push the frontier outward and
unblock questions that depended on them. Recompute the frontier and ask the next round. A
question whose answer depends on another question still open in this round belongs to a *later*
round, not this one.

Finding *facts* is your job, never the user's. When a frontier question needs a fact from the
environment (filesystem, issues, tracker, git history), dispatch a sub-agent to find it — don't
ask the user for anything you could look up yourself. Don't block on it: a running exploration
is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to
report — ask the rest of the frontier now. The *decisions* are the user's — put each to them and
wait.

Interview until the frontier is empty: every branch of the design tree visited, nothing left
silently assumed. Do not write the plan before the user confirms the shared understanding.

### Cover at minimum

- **Goal and scope** — what done looks like, what is explicitly out of scope.
- **Task decomposition** — the natural slices and their dependency edges. Keep chains shallower
  than 3-4 steps (each task sized to one fresh worker context window).
- **Test seams** — the pre-agreed seams each task tests at, and whether TDD applies (default:
  yes). Seams must be settled *now* because the worker cannot ask mid-run.
- **Isolation** — which tasks run in their own worktree/branch (default: all) vs. explicitly
  non-isolated (integration pass, validate current branch). Tasks never run on the primary
  worktree unless marked.
- **Worker runtime + model** — which runtime executes each task. The default comes from
  `docs/agents/setup.md` (`## Worker runtime`: `opencode`, `claude-code`, or `freebuff`) and is
  independent of the agent the orchestrator itself runs in. Override it per task when the mix
  is worth it — cheap mechanical work to `freebuff`, design-sensitive work to a paid runtime —
  and remember a `freebuff` task needs the coordinator present to poll and sign it, so it must
  not sit on the critical path of an unattended stretch. Settle model/effort choices here too.

  Two `freebuff` specifics change the shape of a plan, not just its cost: only **one** freebuff
  worker can run on a machine at a time, so several freebuff tasks are a queue costing the **sum**
  of their budgets in wall-clock; and each runs inside a **one-hour session window**, so no single
  freebuff task may be budgeted beyond what that window holds. Say both out loud before approval.
- **Merge policy** — `docs/agents/setup.md` already records the **merge gate** (`github-actions`,
  `local <command>`, or `unverified`) and the **tracker**, which decides the merge path: **github**
  → squash-merge the PR; **linear** (local-only) → merge the branch into `main` locally. Read the
  recorded gate back to the user in the interview and confirm it still holds for this run — a run
  planned against `unverified` needs saying out loud before any task is cut.
- **Time budget per task** — how long a task may run before a stuck worker becomes a decision for
  the user (default 60 min). `/orca-orchestrate` climbs its escalation ladder off this number;
  without one, a stuck dispatch waits forever and the run looks healthy.

## Write the plan

Write `docs/agents/plan.md` (rolling, overwrite) with this schema:

```
# Plan — <repo> — <date>

## Objective       (one or two lines: what done looks like)
## Context         (why now, constraints, references by path — CONTEXT.md, docs/adr/, issues)
## Decisions       (what was settled, one line each)
## Out of scope    (explicitly excluded, so workers don't drift)

## Tasks
<!-- one block per task, keyed by stable id -->
### <id>: <title>
- spec: <one-paragraph worker brief, including the test seam and TDD expectations>
- blocked-by: <ids or none>
- runtime: <opencode|claude-code|freebuff — default: the setup marker's worker runtime>
- isolated: <yes|no — no means it runs in the primary worktree>
- budget: <minutes before a non-settling worker escalates to a user gate; default 60>

## Status
draft → approved (date) — set to approved only after the user approves in conversation
```

Each task id is stable (`t1`, `t2`, ...) so `/orca-tasks` can reference it and
`/orca-orchestrate` can reconcile. Do not duplicate CONTEXT.md or ADR bodies — reference them by
path.

## Approval checkpoint

End by presenting the plan summary in conversation and asking for approval. Only on an explicit
"approved" do you set `Status: approved` + date in the plan doc. `/orca-tasks` refuses to run on
a plan that is not approved. Approval is a doc state, not an Orca gate — it survives
`/orca-resume`.

## Done when

- The frontier is empty: no decision left silently assumed.
- `docs/agents/plan.md` exists, approved, with stable task ids, dependency edges, test seams,
  isolation flags, a worker runtime, and a time budget per task.
- The merge gate recorded at setup was read back to the user and confirmed for this run.
- The user has confirmed the shared understanding in conversation.
