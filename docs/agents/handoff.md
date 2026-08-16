# Handoff — orca-skills — 2026-08-16

## Summary

orca-skills v2 is complete and pushed to `main`: a self-contained plan-first pipeline
(`/orca-setup` → `/orca-plan` → `/orca-tasks` → `/orca-orchestrate` → `/orca-handoff`/`/orca-resume`)
with two exclusive issue trackers (github via `gh`, linear via the native `orca linear` CLI).
The whole loop was validated end-to-end on two real test projects. Working tree clean, nothing
in progress on this repo.

## Orca state

- Worktree: `main` (isMainWorktree), branch `refs/heads/main`, HEAD `d7d7974`
  ("docs: english diagram + PNG export; README embeds the pipeline image"), card comment empty.
- Repo: `e37eaec6-7d90-47de-b1cd-01017c9742b8::/Users/adamelhirch/orca/workspaces/AdamHUB/orca-skills`.
- Live terminals relevant to this work: `term_daa0105b` (orchestrator on `test`, idle),
  `term_80232ccc` (orchestrator on `test-github`, idle). Other terminals belong to other Orca
  projects — do not touch.

## Coordination

- `run_1d5a000016c2` — linear smoke test (project `test`): task `task_38507d375204` **completed**.
  Issue Linear TES-5 created/linked, PR #1 squash-merged, worktree removed.
- `run_186bd480d81d` — github smoke test (project `test-github`): task `task_b393f145a04a`
  **completed**. Issue gh #1 created/closed, PR #2 squash-merged, worktree removed.
- `run_cbd0766413e2` — earlier linear run on `test` (abandoned during this session's work).
- No unsettled dispatch, no unread mail needing action on this repo.

## Plan

- No `docs/agents/plan.md` in this repo — the plans live in the test projects (`test`,
  `test-github`), which are throwaway validation sandboxes.
- Setup conventions for projects using the suite are recorded per-project in their own
  `docs/agents/setup.md` (see the test projects).

## Decisions

- The suite is fully standalone: no dependency on external skills (`/grill-me`, `to-tickets`,
  `setup-matt-pocock-skills`, etc.) — the grill interview method and tracker config are inline.
- Trackers are exactly two and exclusive per project: **github** (via `gh`, worktree link
  `--issue`, issue auto-closed on merge) or **linear** (native `orca linear`, workspace + team
  resolved at setup, `--linear-issue`, issue moved to Done explicitly after merge — Linear does
  not auto-close on merge).
- Merge gate is CI/tests green; nothing red merges. Coordinator owns the merge (squash PR or
  local), workers never merge.
- One task = one branch = one worktree; tasks never run in the primary worktree unless the plan
  marks a task `isolated: no`. TDD by default; failures gate to the user, no silent redispatch.
- `/orca-setup` replaces the old `/orca-worker` (agents: worker + orchestrator, opencode + Claude
  Code).

## In progress / next

- **2026-08-16 (post-handoff)** — `orca-tasks` patched: codified the `--depends-on` fallback
  (Orca DAG `--deps` = single source of truth; issue body documents `Blocked by/Blocks`; the
  flag is runtime-detected — `gh` 2.83.1 lacks it and the REST dependencies endpoint 404s).
  Merged via PR #1 (`016d4cf`), branch deleted, plan at `docs/agents/plan.md` (approved, lean
  path, `isolated: no`). Working tree clean.
- Optional cleanup of throwaway validation artifacts: repos `adamelhirch/test` and
  `adamelhirch/test-github` (and their local clones under `~/orca/projects/`), Linear issues in
  the `testing-orca` workspace, and the two idle orchestrator terminals on this host.
- The visual-check screenshots for the pipeline diagram are regenerated with the English diagram
  but are not referenced in the README; delete them if you want a clean `docs/diagrams/` (keep
  `orca-pipeline.html` + `orca-pipeline.png`).
- Nothing else is open on this repo.

## Suggested skills

- `/orca-resume` — to re-anchor this project in a fresh session (will confirm the clean state).
- `/orca-orchestrate` — to run a real project through the pipeline (e.g. AdamHUB) now that the
  suite is validated.
