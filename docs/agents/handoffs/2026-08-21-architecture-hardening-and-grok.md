# Handoff — orca-skills — 2026-08-21

## Summary

An architecture review of the suite turned into seven merged PRs (#3–#9) that closed the gaps it
found: the repo now has CI of its own, the merge gate is a real capability instead of a phrase,
the DAG loop closes the gates it opens, the suite gained observability (`/orca-status`) and a
worker-runtime choice, and Grok joined as a fourth agent host. Every change was validated against
the live binary rather than assumed, and the freebuff runtime was exercised end to end on a real
throwaway project. `main` is green and clean at `c7182df`; nothing is in progress.

## Orca state

- Worktree: `main` (`isMainWorktree: true`), branch `refs/heads/main`, HEAD `c7182df`
  ("feat(setup): install-agents.sh links the suite's skills for opencode (#9)").
- Working tree clean. No other worktree of this repo exists.
- Card comment is **stale** — still reads "resumed; orca-freebuff skill merged (PR #2, 2ab4092)".
  Updated as the last step of this handoff.
- Live terminals in this repo: 2 — `term_96dd20da` ("Terminal 1", idle shell) and `term_21fb496f`
  (this Claude Code session). Neither is a worker.
- CI: `lint` green on the last three runs.

## Coordination

- **Drift worth knowing:** this coordinator terminal is still bound to `run_f6e69b04489e`, whose
  objective ("e2e freebuff: implémenter slugify") belongs to a **different project** —
  `~/orca/workspaces/AdamHUB/orca-e2e-freebuff`. This repo has no run of its own; the work here
  went through plain branch → PR → CI → squash-merge.
- That run is fully settled: `task_f746bf59f8a9` and `task_20e3e536b852` both `completed`,
  0 pending gates, 0 unread mail (peeked, not consumed), 0 reclaimable worker terminals.
- The e2e project itself is clean: only `main`, no leftover worktree or terminal, `node --test`
  green (`pass 2 / fail 0`), four commits telling the whole run.

## Plan

- `docs/agents/plan.md` is **stale**: it is the approved-and-executed plan for `/orca-freebuff`
  from 2026-08-18. None of this session's work was planned through it.
- **There is still no `docs/agents/setup.md` in this repo.** The suite does not yet run its own
  gate chain (finding ⑨ of the review). Its merge gate would now be `ci: github-actions` since
  PR #3 added the workflow, but the tracker choice is the user's and was not made.

## Decisions

Seven PRs, each fixing something measured rather than suspected:

- **#3 — CI for the suite itself.** It had none: both prior PRs merged with
  `statusCheckRollup: []`. `scripts/validate-skills.mjs` asserts frontmatter shape, manifest and
  README coverage, and link resolution. It caught `orca-freebuff` missing from `skills.sh.json`
  on its first run. Added `docs/COMPAT.md`; dropped 537 KB of generated artifacts.
- **#4 — the merge gate became a capability.** Measured: `gh pr checks` prints `no checks
  reported` and **exits 0** on a repo with no workflows, so a worker could report `succeeded`
  having run nothing. `/orca-setup` now records `ci: github-actions | local <cmd> | unverified`.
  Same PR closed the gate loop (`gate-list`/`gate-resolve` appeared **nowhere** in the repo) and
  single-sourced the agent contract into `agents/_shared/`.
- **#5 — `/orca-status`.** The suite had no observability: `worker-list`, `gate-list`, `inbox`,
  `run-show`, `worker-stop` were unreferenced anywhere. Also fixed a real bug — both
  `/orca-resume` and `/orca-handoff` documented `check --unread --inject`; `--inject` does not
  exist (`invalid_argument`) and `--unread` **marks messages read**, so a read-only orientation
  was consuming the mailbox. Now `--peek`.
- **#6 — worker runtime chosen at setup**, independent of the orchestrator, overridable per task.
  Recipes live in `skills/orca-orchestrate/runtimes.md`. Added the validator rule that a
  `SKILL.md` may not link outside its own directory (installed skills are standalone).
- **#7 — two freebuff constraints, measured live.** One instance per machine (a second refuses
  with *Take over / Exit*), so freebuff tasks are **strictly serial**; and the session is a
  **one-hour wall-clock window**, not a task counter (42m → 41m after a 20s task → 37m idle). A
  task consumes minutes, never a session; a new terminal joins the running session.
- **#8 — Grok as a fourth host and runtime.** `--agent` + `permission_mode: bypassPermissions`,
  verified headlessly. Grok reads `~/.claude/agents/` only as *subagents*, so the pair genuinely
  needs `~/.grok/agents/`. Hosts are no longer hardcoded — the validator discovers them and fails
  if the installer does not know one.
- **#9 — `install-agents.sh` links the suite's skills for opencode.** `skills add` wires Claude
  Code and Grok automatically but not opencode, which reads `~/.config/opencode/skills`; an
  opencode session had the agents and none of the `/orca-*` commands.

Validated end to end on `~/orca/workspaces/AdamHUB/orca-e2e-freebuff`: a free opencode
orchestrator (`opencode-go/deepseek-v4-flash`) drove a free freebuff worker through
setup → plan → tasks → dispatch → verify → merge without leaving the contract. It caught a broken
test command in the scaffold and refused to engrave a gate that tested nothing.

## In progress / next

Nothing in progress. Open threads, none blocking:

1. **This repo does not run its own gate chain.** No `docs/agents/setup.md`; `plan.md` is stale.
   Closing it needs one decision from the user: the tracker (github, given the remote).
2. **The opencode `question` tool deadlocks a terminal-driven orchestrator.** Its question widget
   blocks the agent loop, and text sent via `orca terminal send` lands in the message queue as
   `QUEUED` instead of answering it. Harmless while a human orchestrates at the keyboard; a hard
   blocker for orchestrator-driving-orchestrator. The `worker` profile already denies `question`
   for this reason.
3. **The pipeline diagram is stale** — `docs/diagrams/orca-pipeline.png` predates `/orca-status`
   and `/orca-freebuff`. Captioned honestly as covering the five-step main path; regenerating it
   is an archify job of its own.
4. **The e2e test project still exists** at `~/orca/workspaces/AdamHUB/orca-e2e-freebuff`, clean
   and green. Keep as a fixture or delete.

Host state as of this handoff: 8/8 skills installed for Claude Code, opencode and Grok; 6/6 agents
composed from the shared contracts. Sessions started before that still hold the old definitions —
restart them.

## Suggested skills

- `/orca-resume` — to pick this up in a fresh session.
- `/orca-status` — read-only sweep; also what `/orca-resume` and this handoff run.
- `/orca-setup` — to finally give this repo its own setup marker (thread 1 above).
