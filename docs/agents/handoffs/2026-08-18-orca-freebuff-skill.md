# Handoff — orca-skills — 2026-08-18

## Summary

A new skill `/orca-freebuff` was planned (spike-validated), written, live-validated, and merged
(PR #2, squash-merge `2ab4092`): dispatching tasks to free (ad-funded) **Freebuff** coding agents
as **terminal-driven TUI workers** (DeepSeek V4 Flash 07/31, unlimited). The whole loop works —
launch → prompt → completion marker → impersonated `worker_done` — proven on a real task
(`t2-fb-validation` completed). Repo clean on `main`, no worktrees left over, no in-progress
work.

## Orca state

- Worktree: `main` (isMainWorktree), branch `refs/heads/main`, HEAD `2ab4092`
  ("orca-freebuff: terminal-driven free TUI worker skill (#2)").
- Repo: `e37eaec6-7d90-47de-b1cd-01017c9742b8::/Users/adamelhirch/orca/workspaces/AdamHUB/orca-skills`.
- Card comment: stale ("resumed; orca-tasks --depends-on fallback fixed (PR #1 merged 016d4cf);
  clean") — update to point to this handoff.
- Live terminals: none owned by this session (both spike terminals closed). No other worktrees
  of this repo exist (`orca worktree list` → main only).

## Coordination

- `run_c7833894419b` (spike-freebuff-worker-done): task `spike-fb-done` **completed** — proved
  the integration joint (dispatch without inject + impersonated worker_done). Contains 3 unread
  test messages (`status` + 2 `worker_done` artifacts) in its mailbox — disposable spike run,
  ignore.
- `run_d121c1805457` (t2 validation): task `t2-fb-validation` **completed** — live follow of the
  skill's own recipe (marker FREEBUFF_TASK_DONE seen as final reply, `freebuff-ok.md` created,
  `worker_done` impersonated settled it, `worker_release` correctly absent because auto-settled).
- Note: other runs in `run-list` belong to other projects (AdamHUB, test, Stitch) — untouched.

## Plan

- `docs/agents/plan.md` — **approved + executed** (merged in PR #2). Plan was: skill
  `orca-freebuff` (t1) + live validation (t2). Both done.
- No `docs/agents/setup.md` in this repo — orca-tasks/orchestrate's setup gate does not apply;
  this repo follows the lean coordinator path (branch → PR → review/validate → squash-merge).

## Decisions

- Freebuff is integrated **only** via terminal-driven TUI: all headless flags rejected
  (verified on v0.0.149), `@codebuff/sdk` is paid. Codified in the skill's "Why this pattern"
  table.
- `tui-idle` is NOT a completion signal → completion = unique marker `FREEBUFF_TASK_DONE` in the
  prompt contract + polling loop (wait → read → grep).
- `worker-start` / `dispatch --inject` refuse non-agent terminals → use
  `dispatch --task <id> --run <id> --to <handle>` WITHOUT `--inject`, then send the prompt
  manually; settle with `orca orchestration send --type worker_done ... --from <worker_handle>`
  (impersonated, the deliberate deviation from /orca-orchestrate). This auto-settles the dispatch
  — skip `worker-release` (returns `dispatch_not_found`, expected).
- New skill documented: `skills/orca-freebuff/SKILL.md` (+ README row).

## In progress / next

- Nothing in progress. Suggested next uses: dispatch a real task to a freebuff worker in a
  project repo (AdamHUB etc.) via `/orca-freebuff` to see the free-agent pool in production.
  Watch freebuff session quotas (PREMIUM 6/day, resets hourly; UNLIMITED Flash tier is the free
  default).

## Suggested skills

- `/orca-resume` — to resume any future session on orca-skills.
- `/orca-freebuff` — the new skill, for terminal-driven free workers.
- `/orca-handoff` — to rewrite this document after the next run.