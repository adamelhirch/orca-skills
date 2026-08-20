---
description: Orca supervised worker. Permissive permissions for unattended orchestration runs; never blocks on permission or question prompts.
mode: primary
permission:
  external_directory: allow
  doom_loop: allow
  question: deny
---

<!-- Host header only. The behaviour contract is appended from _shared/worker-contract.md by
     install-agents.sh — do not add lifecycle, TDD, or merge-gate rules here. -->

## Permissions (opencode)

This agent auto-approves what opencode would otherwise prompt for (external directories, repeated
identical tool calls) so unattended runs never stall. Use that freedom for the injected task, not
for anything outside the brief.

The opencode `question` tool is **denied** here — it would block the run on a human who is not
watching. When blocked, use `orca orchestration ask` (worker → coordinator) instead.
