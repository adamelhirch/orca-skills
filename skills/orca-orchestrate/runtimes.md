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
| `hermes` | your Hermes provider key (e.g. ox-alpha via opencode-go) | profile `orca-worker` / skill in `~/.hermes/skills/` | itself | another supervised agent runtime; persistent memory/skills ecosystem |
| `freebuff` | free (ad-funded) | none — no agent in the terminal | **coordinator, impersonated** | throwaway tasks where free matters — **one at a time** |

`opencode`, `claude-code`, `grok`, and `hermes` are *supervised agent* runtimes: they run the
permissive `worker` profile installed by `/orca-setup`, follow the shared contract, and send their
own `worker_done`.
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

All supervised runtimes follow the same shape — **create the worktree, launch the terminal, then
bind the dispatch** — and all of them obey one task = one branch = one worktree, never the primary.
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

### `hermes`

Hermes has no agent directory and no agent-select flag, so the permissive profile reaches a
session one of two ways, both installed by `/orca-setup`:

- **Profiles (preferred).** `/orca-setup` creates the Hermes profiles `orca-worker` /
  `orca-orchestrator` (`--clone` of your default config), ships `approvals.mode: off` in each,
  and composes header + shared contract into their `SOUL.md` — every session on the profile IS
  the role, no flags needed. The wrapper aliases make them plain commands:
- **Skills.** The same composition installs as skills `orca-worker` / `orca-orchestrator` in
  `~/.hermes/skills/`, preloaded at launch with `--skills`; add `--yolo` yourself in this path
  (it is Hermes' approval bypass, the opencode `--auto` equivalent — without it an unattended
  dispatch stalls on dangerous-command approvals).

```bash
orca terminal create --worktree id:<wtId> --title <slug> \
  --command "orca-worker chat" --json
# skill path instead of the profile:
#   --command "hermes chat --skills orca-worker --yolo"
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
# tui-idle is necessary, not sufficient (it once fired before the TUI had started):
# confirm the Ink banner + ❯ prompt are up via `orca terminal read` before binding.
orca orchestration worker-start --task <task_id> --terminal <handle> --worktree id:<wtId> --json
```

Like every supervised recipe this is an `external_terminal`, so expect `worker-read --source auto`
to fall back to `source: "terminal"` until Orca proves Hermes sessions — no transcript claim is
made here, and the runtime has not yet been exercised end-to-end on a real run (first run should
update the Hermes row of the suite's `docs/COMPAT.md` with what it measures).

The cockpit works the same way: coordinate from `orca-orchestrator chat` (or `hermes chat
--skills orca-orchestrator --yolo`). The `/orca-*` skills are symlinked into `~/.hermes/skills/`
by `/orca-setup`, and AGENTS.md in the worktree is auto-loaded. Model/provider come from the
cloned config (`model.default`, e.g. ox-alpha via opencode-go); pass `-m/--provider` only when
the plan names a specific one. Verified on Hermes Agent v0.20.5: `--profile/-p` is a global flag
(works before or after the subcommand), `chat -q` is headless, `--skills` preloads, and there is
no per-session agent directory — do not invent an `--agent` flag.

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
