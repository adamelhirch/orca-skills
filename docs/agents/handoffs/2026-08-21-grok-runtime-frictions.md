# Handoff — orca-skills — 2026-08-21

## Summary

The grok-runtime honesty run is closed. `run_4cec44f0b982` (t1–t4) is fully `completed`; PRs #14–#17 are squash-merged, issues #10–#13 closed, CI `validate-skills` green on each. `origin/main` is at `d2f7d1d`. The cockpit checkout is **four commits behind** that tip and still holds uncommitted pipeline docs. Nothing is in flight.

## Orca state

- Worktree: `main` (`isMainWorktree: true`), id `e37eaec6-7d90-47de-b1cd-01017c9742b8::/Users/adamelhirch/orca/workspaces/AdamHUB/orca-skills`.
- Local HEAD `489fe1e` (`handoff: architecture hardening…`). `origin/main` `d2f7d1d` (`fix(orchestrate): two-step settle (#17)`). Divergence: #14, #15, #16, #17 are on origin, not in this working tree.
- Dirty / untracked on cockpit: `docs/agents/plan.md` (modified), `docs/agents/setup.md` (untracked), `BRIEF-frictions-runtime-grok.md` (untracked intake; not a skill).
- Card comment (pre-handoff): `run_4cec44f0b982 complete: t1-t4 merged PRs #14-#17`.
- Only this repo worktree exists (`git worktree list`: cockpit only). Task worktrees t1–t4 were `worktree rm --force`d; remote branches deleted.
- Terminals in this repo: `term_247c220d` (this Grok orchestrator). No task-worker terminals.
- Host-wide `worker-list --terminal-state reclaimable`: `workers: []`. Counts `retained: 58` / `released: 1` are **host-wide**, not this run. This run's `worker-list --run`: `workers: []`.
- Merge gate exercised: `ci: github-actions`. Last five Actions runs on this repo: `success`.

## Coordination

- Bound Run: `run_4cec44f0b982`. Objective: close the grok-runtime honesty gap measured on candigo `run_73627a191505`. Two-step recipe stays; promises it cannot keep are withdrawn.
- Tasks (all `completed`, ready list empty):
  - `task_1fe183aa61bc` t1 Honest grok recipe → PR #16, issue #10
  - `task_f1c2f8680c38` t3 Peek without a Run is unknown → PR #14, issue #11
  - `task_aa614780ccb2` t4 Tracker marker wins → PR #15, issue #12
  - `task_41ceacbf3172` t2 Two-step settle loop (blocked-by t1) → PR #17, issue #13
- Pending gates: 0.
- Unsettled dispatches: none. No `worker-start` TUI workers this run (plan: coordinator authors isolated branches; do not dispatch grok to document grok).
- Mail: Run is bound; `check --peek` → `ok: true, count: 0` (empty, not unknown). Not consumed.

## Plan

- `docs/agents/plan.md` — **approved (2026-08-21)**, executed. Still only on the cockpit working tree (not on `origin/main`).
- `docs/agents/setup.md` — **setup complete**, written this session, **untracked**. Tracker `github` (full issues+PRs, not `github-pr`). Worker runtime default `opencode`. Merge gate **`ci: github-actions`**.
- Prior rolling handoff (`docs/agents/handoffs/2026-08-21-architecture-hardening-and-grok.md`) is superseded by this one.

## Decisions

Recorded in `docs/agents/plan.md`; do not reopen without a new plan.

- Keep two-step grok launch (`terminal create --command "grok --agent worker --always-approve --trust"` then `worker-start --terminal`). Do not use `worker-start --agent grok`.
- That path is `external_terminal`. `worker-read --source auto` returns `source: "terminal"` / `fallbackReason: session_not_reported`. `-p` / `--prompt-file` remains real headless; it is not the supervised TUI path.
- Folder trust ≠ `--always-approve`. `--trust` accepted on grok `1.0.5` (`grok --help` still omits it). Availability = `terminal read` until status bar `always-approve` and prompt `❯`.
- Settle: `gh pr merge --squash` → `worker-release` → `terminal close` → `worktree rm` → `git push origin --delete <branch>`.
- `check --peek` without a bound Run is **unknown**, not empty. Token `github-pr` is first-class; **the setup marker wins**.
- Orca CLI patches (custom argv on `--agent grok`, `check --peek` → `run_required`, stdout JSON concat as a binary bug) stay out of this repo.

## In progress / next

Nothing in flight. Open threads, none blocking the DAG:

1. **Pull `origin/main` on the cockpit** (`489fe1e` → `d2f7d1d`) so local `main` matches GitHub. Dirty pipeline files must be stashed, committed, or left aside first.
2. **Commit `docs/agents/setup.md` + `docs/agents/plan.md`** (and this handoff) so the next `/orca-resume` does not depend on an uncommitted working tree. `BRIEF-frictions-runtime-grok.md` is intake; ship it only if you want the dossier in git.
3. **`/orca-freebuff` still has `gh pr merge --squash --delete-branch`.** t2 updated `/orca-orchestrate` only. Same cosmetic git error on a freebuff settle.
4. Host-wide retained count (58) is unrelated to this run; do not treat it as leaked grok workers from t1–t4.

Owner of 1–3: the next orchestrator session, unless this one continues.

## Suggested skills

- `/orca-resume` — load this handoff, pull `origin/main`, reconcile the uncommitted pipeline docs.
- `/orca-status` — same sweep this handoff ran; safe any time.
- `/orca-freebuff` — only if closing thread 3.
