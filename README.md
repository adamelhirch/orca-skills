# orca-skills

Skills for orchestrating multi-agent work on [Orca](https://orca.sh): the coordinator runbook,
durable project handoff/resume, and the supervised worker agents. Built for **orchestrator
sessions** (the persistent cockpit worktree), usable from opencode and Claude Code.

Install with a single command:

```bash
npx skills add adamelhirch/orca-skills
```

## Skills

| Skill | Purpose |
| --- | --- |
| `/orca-orchestrate` | Coordinator runbook: supervised worker loop, `check --wait` watchdog, `worker_done` recovery. |
| `/orca-handoff` | Write a durable project handoff (Orca state + session context) so a fresh orchestrator session resumes without losing context. |
| `/orca-resume` | Resume an Orca project: load the handoff doc, reconcile with live Orca state, flag drift, re-anchor. |
| `/orca-worker` | Set up the permissive `worker` agents (opencode + Claude Code) with the `worker_done` discipline. |

## Prerequisites

- The Orca runtime running (`orca status`), with the `orca-cli` and `orchestration` skills
  installed — the skills load their version-matched command guides from the binary:
  ```bash
  orca skills install
  ```
- The worker agents install opencode `~/.config/opencode/agents/worker.md` and Claude Code
  `~/.claude/agents/worker.md` via `/orca-worker`.

## Usage

1. `/orca-worker` — install the worker agents on this host.
2. `/orca-orchestrate` — run a supervised orchestration batch from the cockpit.
3. `/orca-handoff` at the end of a session, then `/orca-resume` in the next one.

All skills are user-invoked (`disable-model-invocation: true`) so they only fire when an
orchestrator calls them by name — never automatically in a worker session.

## Security note

The worker agents installed by `/orca-worker` are **permissive by design**: they run
unattended, so `external_directory`/`doom_loop` are allowed (opencode), `--auto` and
`permissionMode: bypassPermissions` (Claude Code) skip approval prompts. Skills audits
(Gen/Socket/Snyk) therefore flag `orca-worker` — that is the intended posture for an
unattended orchestration worker, not a defect. Scope it accordingly: worker terminals run
only dispatches the orchestrator injects, in ephemeral worktrees.

## Notes

- `npx skills add` installs copies; re-run it to pick up repo updates.
- The handoff document (`docs/agents/handoff.md` + `docs/agents/handoffs/`) is a per-project
  convention written by `/orca-handoff` inside each repo.

## License

MIT
