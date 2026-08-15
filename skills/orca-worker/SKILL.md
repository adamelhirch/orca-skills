---
name: orca-worker
description: >-
  Set up the Orca supervised worker agents for opencode and Claude Code: permissive
  permissions so unattended orchestration runs never stall on a prompt, plus the
  worker_done discipline. Orchestrator sessions only. Invoke with /orca-worker.
disable-model-invocation: true
---

# Set up the Orca worker agents

Install the `worker` agents used by `/orca-orchestrate` for dispatched orchestration work.
The canonical definitions live in this skill's `agents/` folder; copy them to each host agent's
directory. Both agents carry the same contract: permissive so a run never stalls on a prompt,
and disciplined to report `worker_done` exactly once.

## Steps

1. opencode: copy `agents/opencode/worker.md` to `~/.config/opencode/agents/worker.md`
   (create the `agents` directory if missing). The agent is `mode: primary` with
   `external_directory` / `doom_loop` allowed and `question` denied.
2. Claude Code: copy `agents/claude/worker.md` to `~/.claude/agents/worker.md`
   (create the `agents` directory if missing). It is a subagent with
   `permissionMode: bypassPermissions` so it runs unattended.
3. If the target `agents` directory did not exist when the agent session started, restart that
   agent once so the definition is picked up.

## Launch the worker

- opencode (note: `-a <agent>` is broken in opencode TUI — set the agent through config):
  ```bash
  OPENCODE_CONFIG_CONTENT='{"default_agent":"worker"}' opencode --auto -m <model>
  ```
- Claude Code:
  ```bash
  claude --agent worker
  ```
  When running as a main agent (not a subagent), pass `--permission-mode bypassPermissions`
  as well, since frontmatter `permissionMode` applies to subagent runs.

## Done when

- `~/.config/opencode/agents/worker.md` and `~/.claude/agents/worker.md` match the canonical
  files in `agents/`.
- A fresh opencode run answers through the worker agent:
  `opencode run --agent worker -m <model> "reply with exactly: ok"` shows `worker`.
- Claude Code lists `worker` under its agents.
