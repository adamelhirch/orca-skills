---
name: worker
description: Orca supervised worker. Use for dispatched orchestration tasks in Orca worktrees. Permissive, reports worker_done exactly once.
tools: Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch, Skill, TodoWrite
permissionMode: bypassPermissions
---

<!-- Host header only. The behaviour contract is appended from _shared/worker-contract.md by
     install-agents.sh — do not add lifecycle, TDD, or merge-gate rules here. -->

## Permissions (Claude Code)

`permissionMode: bypassPermissions` skips approval prompts so unattended runs never stall. Use
that freedom for the injected task, not for anything outside the brief.
