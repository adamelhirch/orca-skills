# Orca setup — orca-skills — 2026-08-21

## Primary worktree
`id:e37eaec6-7d90-47de-b1cd-01017c9742b8::/Users/adamelhirch/orca/workspaces/AdamHUB/orca-skills`
(display name: `main` — cockpit; stays on the default branch, receives merged PRs, never runs tasks)

## Repo
`github.com/adamelhirch/orca-skills` (remote `origin`)

## Worker runtime
`opencode` — default for this project. Independent of the orchestrator TUI. Override per task in the plan. `grok` and `hermes` are supported hosts, not the default here.

## Merge gate
`ci: github-actions` — workflow `.github/workflows/lint.yml` runs `node scripts/validate-skills.mjs`.
`gh pr checks <pr>` is authoritative; `no checks reported` is a failed gate, not a pass.

## Conventions
- One branch = one PR = one responsibility; delete branch + worktree after merge
- Tasks run in ephemeral worktrees, never the primary, unless a plan task is `isolated: no`
- TDD by default when there is a test seam; this repo's seam is `scripts/validate-skills.mjs`

## Issue tracker
`github` — `/orca-tasks` mirrors each task as a `gh issue` and links the task worktree.
(This is the full github tracker, not a PR-only exception.)

## Agents installed
- opencode: `worker` + `orchestrator` in `~/.config/opencode/agents/`
- Claude Code: `worker` + `orchestrator` in `~/.claude/agents/`
- Grok: `worker` + `orchestrator` in `~/.grok/agents/`
- Hermes: profiles `orca-worker` + `orca-orchestrator` (`SOUL.md` composed, `approvals.mode: off`, wrappers in `~/.local/bin/`) and the same-named skills in `~/.hermes/skills/` (verified 2026-08-22, Hermes Agent v0.20.5)

## Guides
- `orca orchestration` present in the binary
- `orca-cli` present in the binary

## Status
setup complete
