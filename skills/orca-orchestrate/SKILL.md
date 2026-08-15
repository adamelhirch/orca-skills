---
name: orca-orchestrate
description: >-
  Orca orchestration coordinator runbook for orchestrator sessions only: the
  supervised worker loop, the check --wait watchdog, and worker_done recovery.
  Invoke with /orca-orchestrate.
disable-model-invocation: true
argument-hint: "Objective of the run?"
---

# Orca orchestration runbook

Run supervised multi-agent work on Orca from the orchestrator cockpit: create a Run, dispatch
independent tasks to `worker` agent terminals, and wait for each worker to settle with
`worker_done`. Re-orient first if you are in a fresh session (`/orca-resume`); this runbook
assumes you know what the run is for.

## Load the guides before any command

The exact command surface lives in version-matched guides served by the binary, not here:

```text
orca skills get orchestration
orca skills get orca-cli
```

Read them before running anything. Prefer `--json` for agent-driven calls. Never guess
subcommands or flags from memory.

## The supervised loop

1. Create the Run and every independent Task first, then start all workers before waiting:
   ```bash
   orca orchestration run-create --objective "<objective>" --json
   orca orchestration task-create --spec "<worker A task>" --json
   orca orchestration task-create --spec "<worker B task>" --json
   ```
   Express dependencies with `--deps` / `--parent`; keep chains shallower than 3-4 steps.
2. Launch each worker through a fresh agent terminal running the permissive `worker` agent
   (see `/orca-worker`; the workers are opencode unless the run says otherwise):
   ```bash
   orca terminal create --worktree <selector> --command "OPENCODE_CONFIG_CONTENT='{\"default_agent\":\"worker\"}' opencode --auto -m <model>" --title "<task>" --json
   orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
   orca orchestration worker-start --task <task_id> --terminal <handle> --worktree <same-selector> --json
   ```
   For a new worktree, `orca worktree create --setup run` first, then `terminal create` in it.
3. Wait in rolling windows and process every message before acknowledging:
   ```bash
   orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000 --json
   ```
   A timeout or `{count:0}` is a checkpoint, not a worker failure. Keep waiting until every
   dispatch settles; workers routinely run 15-60 minutes.
4. For each accepted `worker_done`, choose the terminal's next owner before you acknowledge:
   - same agent has a follow-up Task → reuse it: `worker-start --task <next> --terminal <handle> --worktree <sel>`
   - otherwise → `orca orchestration worker-release --dispatch <dispatch_id> --json`
   Acknowledge only after every message and release decision is handled:
   ```bash
   orca orchestration check --ack <delivery_id> --wait --types worker_done,escalation,question --timeout-ms 900000 --json
   ```

## Watchdog: worker finished but no worker_done

A worker can finish its work and idle at the prompt without sending `worker_done`. When a wait
window times out, inspect each unsettled dispatch instead of waiting blindly:

1. `orca orchestration worker-read --dispatch <id> --json` and
   `orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json`.
2. If the worker is idle and its last message shows the work done (PR/commits pushed, final
   summary) but no `worker_done` arrived, re-inject the finalization from the worker's own
   terminal — the authority must come from there:
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

## Hard-won notes

- opencode's `-a <agent>` is broken in TUI mode (prints help and exits) → pass the agent with
  `OPENCODE_CONFIG_CONTENT='{"default_agent":"worker"}'` and add `--auto` as a safety net.
- `worker-start --terminal <handle>` requires `--worktree` to match the terminal's worktree,
  or it fails with `terminal_worktree_mismatch`.
- opencode defaults to prompting (`ask`) for `external_directory` and `doom_loop`; the `worker`
  agent auto-allows them so unattended runs never stall on a permission prompt.
- `worker_done` must come from the worker's own terminal with the injected
  `--task-id` / `--dispatch-id`; it marks the task and dispatch complete automatically — do not
  follow it with a manual `task-update`.
