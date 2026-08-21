# Worker runtimes

A **worker runtime** is the coding agent that executes one dispatched task in its own worktree.
It is chosen at setup (`docs/agents/setup.md` → `## Worker runtime`) and may be overridden per
task in the plan (`runtime:`).

**The worker runtime is independent of the orchestrator.** The orchestrator is simply whichever
TUI you are sitting in — a Claude Code session, an opencode session — coordinating from the
primary worktree. Nothing stops a Claude Code orchestrator from dispatching opencode workers, or
an opencode orchestrator from dispatching freebuff ones. Pick the orchestrator for the interface
you want to work in, and the runtime for the cost and capability the tasks need.

| Runtime | Cost | Agent profile | Reports `worker_done` | Use it for |
| --- | --- | --- | --- | --- |
| `opencode` | your provider key | `~/.config/opencode/agents/worker.md` | itself | the default; broad model choice |
| `claude-code` | Claude subscription/API | `~/.claude/agents/worker.md` | itself | tasks wanting Claude Code's tooling |
| `grok` | xAI account | `~/.grok/agents/worker.md` | itself | another supervised agent runtime; `-p` / `--prompt-file` is real headless, not this TUI path |
| `freebuff` | free (ad-funded) | none — no agent in the terminal | **coordinator, impersonated** | throwaway tasks where free matters — **one at a time** |

`opencode`, `claude-code`, and `grok` are *supervised agent* runtimes: they run the permissive
`worker` profile installed by `/orca-setup`, follow the shared contract, and send their own
`worker_done`.
`freebuff` is a *driven TUI* runtime: there is no agent, the coordinator types into it and signs
the result. That difference is the whole reason to prefer the first two by default.

`freebuff` also carries two hard limits the others do not, both verified on this toolchain:

- **One instance per machine.** A second freebuff refuses to start (`Freebuff is already running`,
  offering to *take over* — which kills the first). Freebuff tasks are therefore **strictly
  serial**: dispatch one, settle it, close its terminal, then dispatch the next.
- **A one-hour wall-clock session window.** The banner shows the minutes left; they decay whether
  you work or not. A task whose budget exceeds the minutes left must not be dispatched.

Both are detailed in `/orca-freebuff`.

## Dispatch recipes

All three follow the same shape — **create the worktree, launch the terminal, then bind the
dispatch** — and all three obey one task = one branch = one worktree, never the primary.
Grok is the exception on availability: `terminal read` (its recipe), not `tui-idle`.

```bash
orca worktree create --name <slug> --no-parent --setup run --json
# dependent task → --parent-worktree active instead of --no-parent
```

### `opencode`

opencode's `-a <agent>` is broken in TUI mode (prints help and exits), so the `worker` profile is
selected through config, with `--auto` as the safety net:

```bash
orca terminal create --worktree id:<wtId> --title <slug> \
  --command "OPENCODE_CONFIG_CONTENT='{\"default_agent\":\"worker\"}' opencode --auto -m <model>" --json
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
orca orchestration worker-start --task <task_id> --terminal <handle> --worktree id:<wtId> --json
```

### `claude-code`

Claude Code selects the agent with a real flag, so no env-var trick is needed. The `worker`
profile already carries `permissionMode: bypassPermissions`; passing it again on the command line
is the equivalent of opencode's `--auto` safety net:

```bash
orca terminal create --worktree id:<wtId> --title <slug> \
  --command "claude --agent worker --permission-mode bypassPermissions" --json
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
orca orchestration worker-start --task <task_id> --terminal <handle> --worktree id:<wtId> --json
```

Do **not** reach for `worker-start --agent claude` as a shortcut: `--agent` launches a known TUI
app, it does not select the permissive `worker` profile, so the run stalls on permission prompts.
Launch the terminal yourself and bind with `--terminal`.

### `grok`

Grok selects the profile with `--agent` and uses the same `permission_mode: bypassPermissions` name
as Claude Code. The profile already carries it; `--always-approve` is the safety net equivalent to
opencode's `--auto`. Folder trust is a separate gate: first launch in a repo shows
`Do you trust the contents of this directory?` and waits. `--always-approve` does not cover it.
Trust is per git repo — later worktrees of the same repo skip the invite. Persist with `--trust`.
If this binary rejects `--trust`, drop the flag, answer `y` on the invite, then bind.

```bash
orca terminal create --worktree id:<wtId> --title <slug> \
  --command "grok --agent worker --always-approve --trust" --json
orca terminal read --terminal <handle> --json
# ready when the status bar shows always-approve and the prompt is ❯
orca orchestration worker-start --task <task_id> --terminal <handle> --worktree id:<wtId> --json
```

This path is an `external_terminal`. `worker-read --source auto` returns `source: "terminal"` with
`fallbackReason: session_not_reported` — not a hook-reported Grok transcript. Watch the terminal.

Grok reads agent definitions from `~/.grok/agents/` (user) and `.grok/agents/` (project). It also
discovers `~/.claude/agents/` — but as **subagents**, not as the session profile, so the Grok header
in `~/.grok/agents/` is what `--agent worker` resolves. `-p` / `--prompt-file` is real headless;
the supervised TUI recipe does not use it, and `worker-read` does not return that output.

### `freebuff`

Freebuff has no headless mode and is not a recognised Orca agent, so `worker-start` and
`dispatch --inject` both refuse it with `agent_unconfigured`. It is dispatched without injection
and settled by the coordinator. Before launching, confirm no other instance holds the machine
(`pgrep -fl freebuff`) and that the session window covers the task's budget — the lock file
`~/.config/manicode/freebuff-instance-owner.json` is not cleaned up on exit, so probe the process,
not the file. The full recipe — marker contract, polling loop, impersonated
`worker_done`, and the verification the coordinator must perform itself — is
the `/orca-freebuff` skill. Read that skill before dispatching this
runtime; the summary here is not enough to run it.

## Mixing runtimes in one run

The plan's per-task `runtime:` field overrides the setup default, so a single run can send its
cheap mechanical tasks to `freebuff` and its design-sensitive ones to `claude-code` or `grok`.
Two rules:

- **Never put a `freebuff` task on the critical path of an unattended stretch.** It needs the
  coordinator present to poll for the marker and sign the result.
- **Freebuff tasks never run in parallel — with each other.** One instance per machine means a set
  of ready `freebuff` tasks is a queue, not a fan-out, and costs the *sum* of their budgets in
  wall-clock. Tasks on the other runtimes still run alongside them.
- **State the runtime in the task spec**, not just the plan metadata. A worker that knows it is
  the free tier behaves differently from one that assumes it is not, and the dispatch record is
  what a later handoff reads.
