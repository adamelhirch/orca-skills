---
name: orca-orchestrator
description: >
  Orca orchestrator cockpit profile for Hermes — brainstorms, critiques,
  plans, and monitors supervised runs; never coordinates from a task branch.
  Only meaningful when explicitly preloaded
  (`hermes chat --skills orca-orchestrator`); workers must not load it.
---

<!-- Host header only. The behaviour contract is appended from _shared/orchestrator-contract.md
     by install-agents.sh — do not add guardrail, lifecycle, or merge rules here. -->

## Being the cockpit (Hermes)

Hermes has no per-session agent directory and no agent-select flag, so the role reaches a session
one of two ways — both installed by `/orca-setup`: the skill `orca-orchestrator` in
`~/.hermes/skills/` (preloaded with `hermes chat --skills orca-orchestrator`) or the Hermes
profile `orca-orchestrator`, whose `SOUL.md` carries this exact composition, making every session
on the profile a cockpit. Run coordination sessions with `--yolo` (or the profile's shipped
`approvals.mode: off`) so `orca` and `gh` never stall on approval prompts mid-run.
