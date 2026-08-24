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
| `dsh` | BitDeer key (primary) + DeepInfra key (fallback), ~$0.08-0.14/M in cached-cheap, ~$0.18/M out | none — headless one-shot process, no TUI | itself (native `worker_done`, pilot-proven) | cheap mechanical tasks at volume; the token-economy runtime |
| `freebuff` | free (ad-funded) | none — no agent in the terminal | **coordinator, impersonated** | throwaway tasks where free matters — **one at a time** |

`opencode`, `claude-code`, `grok`, and `hermes` are *supervised agent* runtimes: they run the
permissive `worker` profile installed by `/orca-setup`, follow the shared contract, and send their
own `worker_done`.
`dsh` is a *headless process* runtime: no TUI, no agent directory — each dispatch launches one
one-shot `dsh --profile headless "<task>"` that reads the injected task, works, sends its own
`worker_done`, and exits (exit 0 = completed). It follows the shared contract because the
contract is part of the prompt it receives. `freebuff` is a *driven TUI* runtime: there is no
agent, the coordinator types into it and signs the result.

`dsh` specifics, all verified on this toolchain (2026-08-24, dsh `0.1.1-rc.2`; component probes
on DeepInfra, end-to-end pilot on DeepInfra, provider probes on BitDeer):

- **Model config lives in `$DSH_HOME/settings.yaml`** (`~/.dsh/`), not in flags: custom
  providers under `llm-pi-ai.providers.<id>` with `api: openai-completions` and
  `compat: {supportsDeveloperRole: false, maxTokensField: max_tokens, thinkingFormat: deepseek}`
  — without those switches these gateways refuse reasoning-model requests. Current setup:
  **`bitdeer` primary** (`https://api-inference.bitdeer.ai/v1`, models `deepseek-ai/DeepSeek-V4-Flash`
  and `deepseek-ai/DeepSeek-V4-Pro` — BitDeer has **no** `-0731` id; a wrong model id is a bare
  `400 invalid request`) and **`deepinfra` fallback**
  (`https://api.deepinfra.com/v1/openai`, ids `deepseek-ai/DeepSeek-V4-Flash-0731` / `-Flash`).
  Keys go in `~/.dsh/.env` (`BITDEER_API_KEY=`, `DEEPINFRA_API_KEY=`). The default selection is
  env-commutable via the home patch layer (`~/.dsh/cordis.patch.yml`,
  `agent-default-model.provider: !!js process.env.DSH_DEFAULT_PROVIDER ?? 'bitdeer'`):
  `DSH_DEFAULT_PROVIDER=deepinfra dsh …` flips a whole fleet to the fallback. Two traps, both
  measured: a user-layer `agent-default-model:` section in `settings.yaml` overrides the patch
  layer at runtime (keep that section absent so the patch stays authoritative), and `!!js`
  expressions evaluate only in cordis *patch* layers — never in `settings.yaml`. The model id
  `deepseek-ai/DeepSeek-V4-Flash` is served by both providers, which makes the switch drop-in.
  Nothing per-worktree to install.
- **No trust/approval gate exists** (nothing to cover with a flag), and the shipped permission
  preset is `workspace-write`: bash + filesystem mutations are confined to the session workspace
  and platform temp roots by the harness itself (Seatbelt sandbox on macOS) — reads/network stay
  open. The shared contract's Sandbox-discipline section still applies on top.
- **No TUI to watch**: availability is process exit, not screen markers. There is no
  `tui-idle` trap because there is no TUI. A long dispatch shows as a live process running
  `dsh` inside its terminal.
- **The worker can execute the Orca CLI itself** (verified): a headless `dsh` task ran
  `orca orchestration check --peek --json` successfully, so a native `worker_done` from the
  injected preamble is expected to work — confirm on the first end-to-end dispatch before
  fanning out.
- **Known gaps of the headless surface**: no mid-task interaction (an unresolved `ask` cannot be
  answered — the coordinator must treat it as failed-and-follow-up), no heartbeat cadence of its
  own, and the model remains deepseek-flash: the Model-reliability rules (canary first,
  degenerate-signature escalation) fully apply.

### `dsh`

```bash
orca worktree create --name <slug> --no-parent --setup run --json
orca terminal create --worktree id:<wtId> --title <slug> \
  --command "dsh --profile headless '<task spec>'" --json   # exact injection path TBD below
```

The open integration question is how the dispatch preamble reaches the one-shot process:
`worker-start` binds a *terminal*, and a finished `headless` run has already exited. Two
candidate shapes, to be settled by the first real run:

1. **Wrapper-script shape** — a tiny wrapper launched via `terminal create` that waits for
   `dispatch --inject` text on stdin (or polls the Run mailbox), passes it to
   `dsh --profile headless`, then idles. This keeps the standard bind order intact.
2. **Coordinator-composed shape** — the coordinator fetches the preamble itself
   (`dispatch --return-preamble --dry-run --json`), appends it to the task spec, launches
   `dsh --profile headless "<spec + preamble>"`, then registers the dispatch so Orca tracks it.

The pilot run (2026-08-24, repo `dsh-pilot`, 2 parallel mechanical tasks) settled the open
questions:

- **Proven shape: mail-poll wrapper + coordinator-sent preamble.** `worker-start` refuses a
  non-agent terminal (`agent_unconfigured`), but the freebuff path works:
  `terminal create --command ./dsh-worker.sh` (a script that polls
  `orca orchestration check --unread` for its dispatch), then
  `dispatch --task <id> --to <handle>` **without** `--inject` — Orca records the dispatch
  (`agent_unconfigured` is only enforced on `worker-start`). The preamble itself is delivered by
  the coordinator with `orchestration send --type dispatch --to <handle> --body "<ids + spec +
  worker_done command>"`; the wrapper feeds it to `dsh --profile headless`. The worker then
  sends its own native `worker_done` (verified end-to-end, both workers).
- **Sandbox vs linked worktrees is the one real blocker.** The writable root of a session is
  its launch directory, immutable per session (`writableRoots`: workspace root + platform temp
  areas); `$DSH_HOME/cordis.patch.yml` can patch `sandbox-policy.workspaceRoot` but that field
  only backs *sessionless* calls. An Orca task worktree's git metadata lives in the primary
  worktree's `.git/worktrees/<name>/`, outside any session root — so `git add/commit` fails
  with `Operation not permitted`, and headless escalation to `danger-full-access` fails closed
  (`approval: ask`, no channel). Both pilot workers reported exactly this and honestly marked
  themselves `failed`. **v1 contract: the dsh worker produces and tests; the coordinator
  commits.** A wrapper-side `git add/commit` after `dsh` exits (outside the sandboxed process)
  is the v2 candidate if worker-side commits become necessary.
- **Retry mechanics:** an honest `failed` `worker_done` auto-marks the task failed;
  re-dispatch requires `task-update --status ready` first. `check` takes `--terminal`, not
  `--from`; `task-list` takes `--from`.
- Pilot outcome: 13/13 assertions green across both tasks, two evidenced `worker_done`s, zero
  degenerate output from flash-0731 under its native harness.

Until a second pilot proves worker-side commits or a wider policy, treat `dsh` as
**pilot-proven for produce+test+report**, coordinator commits included in the settle step.

`freebuff` also carries two hard limits the others do not, both verified on this toolchain:

- **One instance per machine.** A second freebuff refuses to start (`Freebuff is already running`,
  offering to *take over* — which kills the first). Freebuff tasks are therefore **strictly
  serial**: dispatch one, settle it, close its terminal, then dispatch the next.
- **A one-hour wall-clock session window.** The banner shows the minutes left; they decay whether
  you work or not. A task whose budget exceeds the minutes left must not be dispatched.

Both are detailed in `/orca-freebuff`.

## Model reliability and provider fallback

The runtime is the agent harness; the **model behind it** is a separate failure surface, and it
is the one that produced every zero-output worker observed so far. A weak or flaky model does
not fail loudly — it loops (`Force-push.` ×14, each time *announcing* an action it never
executes), repeats phrases verbatim, emits raw tool-call XML as text with leaked `</think>`
tags, returns empty responses (`Empty response … response_len=7, tool_turns=0`), or abandons at
~80 % with a tidy to-do list instead of settling. One measured run: 3 of 5 workers on a small
local model produced zero files in ~35 minutes at low context usage; 3 of 5 on the same family
via another provider died on empty first turns; two more burned whole budgets in semantic loops.
Equivalent specs ran clean on stronger models. The harness was never the bottleneck.

- **Canary rule: an unproven model gets one task, not five.** A new model/provider earns
  fan-out only after completing one real task end-to-end (work pushed, merge gate green,
  `worker_done` settled). One task is the cheapest canary you will ever buy.
- **Name the model in the plan** (`## Worker runtime + model`) whenever the default is not a
  proven one, so the choice is deliberate and reviewable after the fact.
- **Set a provider fallback before the run.** A worker whose provider dies mid-run
  (`HTTP 400 — Model is unavailable`) just dies; where the host supports a fallback model list,
  configure it at setup, not during the incident.
- **Degenerate output is a failed dispatch, not a slow worker.** Repetition/announcement loops,
  XML-as-text, and repeated empty responses do not recover into useful work — escalate early
  with the terminal evidence instead of waiting out the full budget.
- **Abandonment is a signature too.** A worker idle at its prompt at ~80 % with a "remaining
  work" list has ended its turn without settling: same watchdog path as any unsettled dispatch —
  re-inject the finalization from its own terminal, or cut the remainder into a follow-up task
  that names what the branch already holds.

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
orca terminal read --terminal <handle> --json
# ready ONLY when the screen shows the banner line `Profile: orca-worker` and the `❯` prompt.
# tui-idle is NOT sufficient for hermes: measured firing satisfied:true while the screen still
# showed the bare shell (same trap as grok). Cold start of a fresh profile is 2-4 minutes
# (first-run tirith install + MCP servers) — do not declare the worker dead inside that window;
# later launches on a warmed profile are far faster.
orca orchestration worker-start --task <task_id> --terminal <handle> --worktree id:<wtId> --json
```

Like every supervised recipe this is an `external_terminal`, so expect `worker-read --source auto`
to fall back to `source: "terminal"` until Orca proves Hermes sessions — no transcript claim is
made here. Exercised end-to-end once (2026-08-22, Hermes v0.20.5, Orca `1.4.x`): dispatch → the
worker read its injected preamble → executed the task → sent its own `worker_done`
(`outcome: succeeded`, correct task/dispatch ids) in 1m44s; the coordinator verified the artifact
independently. Watch the terminal for anything longer than that.

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
