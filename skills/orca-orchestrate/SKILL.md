---
name: orca-orchestrate
description: >-
  Orca orchestration coordinator runbook for orchestrator sessions only: bind the
  Run created by /orca-tasks, dispatch ready tasks one-worktree-one-branch, drive
  the task DAG, watchdog check --wait, gate failures, auto-merge green PRs, release
  workers. Also has a quick path for 1-2 task runs without a plan. Invoke with
  /orca-orchestrate.
disable-model-invocation: true
argument-hint: "Objective of the run?"
---

# Orca orchestration runbook

Drive a supervised multi-agent run on Orca from the orchestrator cockpit. The orchestrator is
the DAG driver: it dispatches only ready tasks, watches every worker settle with `worker_done`,
unblocks dependents only after their parent's green PR is merged, and gates on failures. It
never schedules workers itself — Orca does not infer placement or conflicts. The agents choose
placement; the orchestrator decides *what* runs *when*.

Re-orient first if you are in a fresh session (`/orca-resume`). Confirm the worktree guardrail
first: you must be in the **primary worktree** (see `/orca-setup`) — never coordinate from a
task branch.

## Two entry paths

- **Planned run** (recommended): `/orca-plan` → `/orca-tasks` produced a Run and its Tasks. You
  **bind** that Run and drive it.
- **Quick path**: a small 1-2 task job that skipped planning. `run-create` + `task-create`
  directly from the objective, then drive identically.

## Load the guides before any command

```text
orca skills get orchestration
orca skills get orca-cli
```

Read them before running anything. Prefer `--json` for agent-driven calls. Never guess
subcommands or flags from memory.

## Pre-flight

1. Verify the primary worktree: `orca worktree current --json` → `isMainWorktree` must be
   `true`, or the run is being coordinated from a task branch. Stop and move to the cockpit
   worktree if not.
2. Verify the setup marker exists (`docs/agents/setup.md`), else route to `/orca-setup`.
3. Bind the Run (planned path):
   ```bash
   orca orchestration run-use --id <run_id> --json
   ```
   or create it (quick path): `orca orchestration run-create --objective "<objective>" --json`.

## The DAG loop

1. **Sweep** what is ready to run:
   ```bash
   orca orchestration task-list --run <run_id> --ready --json
   ```
   Every `ready` task has all its blockers merged on `main`. Dispatch each ready task to a
   worker in its own worktree — **one task = one branch = one worktree**, never the primary.

   **Create the task worktree first**, then launch the `worker` profile in it, then bind the
   dispatch (the `worker` profile is selected through config, not `--agent`, because opencode's
   `-a <agent>` is broken in TUI mode):
   ```bash
   # independent (no blockers) → top-level worktree; dependent → child worktree
   orca worktree create --name <slug> --no-parent --setup run --json
   # or: orca worktree create --name <slug> --parent-worktree active --setup run --json
   orca terminal create --worktree id:<newWorktreeId> --title <slug> --command "OPENCODE_CONFIG_CONTENT='{\"default_agent\":\"worker\"}' opencode --auto -m <model>" --json
   orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
   orca orchestration worker-start --task <task_id> --terminal <handle> --worktree id:<newWorktreeId> --json
   ```
   Use a fresh terminal per worker (one worktree = one branch = one worker). Reuse a worker
   terminal only for an immediate follow-up Task on the same worktree, and only when the plan
   allows it. Tasks the plan marked `isolated: no` are the sole exception to the worktree rule —
   they run in the primary worktree and must be declared before dispatch.

   Note: the bare `worktree create` above (no `--agent`) may open a fallback shell alongside the
   later `terminal create`. Target only the agent handle; close a fallback shell only after
   `orca terminal list --worktree id:<id> --json` confirms it is an unused shell.

   **Alternative — composed launch:** when the agent is not opencode (e.g. Claude Code) and its
   `worker` profile can be the launched agent, `worker-start` can create the worktree and launch
   in one call: `orca orchestration worker-start --task <task_id> --worktree new-top-level --name <slug> --agent <tui> --json`. Only use this when the launched TUI actually runs the permissive `worker` profile — otherwise the run stalls on permission prompts.
2. **Wait** in rolling windows and process every message before acknowledging:
   ```bash
   orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000 --json
   ```
   A timeout or `{count:0}` is a checkpoint, not a worker failure. Keep waiting until every
   dispatch settles; workers routinely run 15-60 minutes.
3. **On each `worker_done`**, settle it before acknowledging the Delivery:
   - `succeeded` → the worker already verified the tests are green (CI for github, `uv run
     pytest`/equivalent for local). **Merge** the task branch, then clean up the task worktree,
     then re-sweep:
      ```bash
      # github tracker: merge the PR (auto or via the user's review gate)
      gh pr merge <pr_number> --squash --delete-branch
      # local-only (linear tracker, no remote): merge the branch into main in the cockpit
      #   git merge --squash <task-branch> && git push (if a remote exists)
      orca orchestration worker-release --dispatch <dispatch_id> --json
      orca worktree rm --worktree <task_worktree_id> --force --json
      # linear tracker: move the linked issue to Done explicitly — merge does not do it
      #   orca linear status set <issue_key> --to "Done" --workspace <workspace_id> --json
      ```
      Merging unblocks dependents: after cleanup, run `task-list --ready` again and dispatch
      what is newly ready. The worker merged nothing itself — the coordinator owns the merge.
      An `external_terminal` worker stays live after `worker-release`: close it with
      `orca terminal close --terminal <handle>` (see hard-won notes).
   - `failed` → **never redispatch silently.** Mark the task failed, block its dependents, and
     raise a decision gate to the user:
     ```bash
     orca orchestration task-update --id <task_id> --status failed --json
     # dependents are blocked by the failure — surface them via gate
     orca orchestration gate-create --task <dependent_id> --question "<task> failed; retry bounded (worker-start --retry-of), fix forward, or abandon?" --options '["retry","fix-forward","abandon"]' --json
     ```
     The recommended option is a single bounded retry: create a fresh worktree/terminal (same
     recipe as step 1) and bind `worker-start --task <id> --terminal <handle> --worktree <sel> --retry-of <failed_dispatch_id> --json`. Your call through the gate decides.
4. Acknowledge only after every message and release/merge/gate decision is handled:
   ```bash
   orca orchestration check --ack <delivery_id> --wait --types worker_done,escalation,question --timeout-ms 900000 --json
   ```
5. Repeat until `task-list` shows every task `completed` and no dispatch is unsettled.

## Watchdog: worker finished but no worker_done

A worker can finish its work and idle at the prompt without sending `worker_done`. When a wait
window times out, inspect each unsettled dispatch instead of waiting blindly:

1. `orca orchestration worker-read --dispatch <id> --json` and
   `orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json`.
2. If the worker is idle and its last message shows the work done (branch pushed, CI green, PR
   ready, final summary) but no `worker_done` arrived, re-inject the finalization from the
   worker's own terminal — the authority must come from there:
   ```bash
   orca terminal send --terminal <handle> --text 'orca orchestration send --type worker_done --subject "<status>" --body "<done, found, left>" --task-id <task_id> --dispatch-id <dispatch_id> --outcome succeeded --files-modified "path/a" --json' --enter --json
   ```
   then continue `check --wait`.
3. If it still does not settle, recover manually:
   `orca orchestration task-update --id <task_id> --status completed` then
   `orca orchestration worker-release --dispatch <dispatch_id> --json`.

Never stop, close, or kill a worker because of a timeout, TUI idle, heartbeat, or status — those
mean alive, not done. Never leave a settled worker live: reuse, retain only at the user's
request, or `worker-release`.

## Merge policy

- CI green is the gate. Nothing red merges — better to test and fix than merge and break.
- **github** tracker: squash-merge the PR (`gh pr merge --squash --delete-branch`) once green.
- **linear** tracker with no remote: the worker's tests are the gate; merge the task branch into
  the cockpit `main` locally (`git merge --squash <task-branch>`), push if a remote exists.
- The coordinator merges, the worker never does. The merge is what unblocks dependents, so
  merge promptly after a `succeeded` report — a dependent blocked on an unmerged parent looks
  identical to a stuck run.

## Hard-won notes

- opencode's `-a <agent>` is broken in TUI mode (prints help and exits) → pass the agent with
  `OPENCODE_CONFIG_CONTENT='{"default_agent":"worker"}'` and add `--auto` as a safety net:
  ```bash
  OPENCODE_CONFIG_CONTENT='{"default_agent":"worker"}' opencode --auto -m <model>
  ```
  `worker-start --agent <tui>` launches the named TUI app; it does **not** select the permissive
  `worker` profile. For opencode, select the profile with `OPENCODE_CONFIG_CONTENT` and bind via
  `--terminal` (see the DAG loop).
- `worker-start --terminal <handle>` requires `--worktree` to match the terminal's worktree, or
  it fails with `terminal_worktree_mismatch`.
- opencode defaults to prompting (`ask`) for `external_directory` and `doom_loop`; the `worker`
  agent auto-allows them so unattended runs never stall on a permission prompt.
- `worker_done` must come from the worker's own terminal with the injected
  `--task-id` / `--dispatch-id`; it marks the task and dispatch complete automatically — do not
  follow it with a manual `task-update` (except in recovery).
- `worker-start` `--worktree new-child`/`new-top-level` creates a fresh worktree + branch and
  does not rerun setup. Do not reuse the primary worktree for tasks.
- A worker launched through `terminal create` (custom argv / `OPENCODE_CONFIG_CONTENT`) is an
  `external_terminal`: after `worker-release` returns `retained / external_terminal`, close the
  worker terminal yourself (`orca terminal close --terminal <handle>`) — Orca does not close
  terminals it did not create through `worker-start`.
- Tracker updates after merge are **not automatic**: `gh pr merge` closes the GitHub issue on its
  own, but Linear does **not** move the issue state when the PR merges. After a successful
  linear-tracker merge, update the linked issue explicitly
  (`orca linear status set <key> --to "Done" --workspace <id>` and
  `orca linear comment add <key> --body "Merged in <pr/branch>"`) so the tracker reflects the run.
