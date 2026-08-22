---
name: orca-worker
description: >
  Orca supervised worker profile for Hermes. Only meaningful when explicitly
  preloaded (`hermes chat --skills orca-worker`): runs one dispatched Orca task
  in its worktree, permissive, reports worker_done exactly once. Orchestrators
  must not load this on their own.
---

<!-- Host header only. The behaviour contract is appended from _shared/worker-contract.md by
     install-agents.sh — do not add lifecycle, TDD, or merge-gate rules here. -->

## Being the worker (Hermes)

Hermes has no per-session agent directory and no agent-select flag, so the role reaches a session
one of two ways — both installed by `/orca-setup`: the skill `orca-worker` in `~/.hermes/skills/`
(preloaded with `hermes chat --skills orca-worker`) or the Hermes profile `orca-worker`, whose
`SOUL.md` carries this exact composition, making every session on the profile a worker.
Unattended dispatches must run with `--yolo` (or use the profile, which ships
`approvals.mode: off`): without it, dangerous-command approvals stall the task. Use that freedom
for the injected task, not for anything outside the brief.
