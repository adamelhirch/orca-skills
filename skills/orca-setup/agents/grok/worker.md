---
name: worker
description: >
  Orca supervised worker. Use for dispatched orchestration tasks in Orca worktrees.
  Permissive, reports worker_done exactly once.
prompt_mode: full
model: inherit
permission_mode: bypassPermissions
agents_md: true
---

<!-- Host header only. The behaviour contract is appended from _shared/worker-contract.md by
     install-agents.sh — do not add lifecycle, TDD, or merge-gate rules here. -->

## Permissions (Grok)

`permission_mode: bypassPermissions` skips tool approvals so unattended runs never stall. Use that
freedom for the injected task, not for anything outside the brief.
