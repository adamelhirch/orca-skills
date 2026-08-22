# Plan — orca-skills — 2026-08-21

## Objective
Close the grok-runtime honesty gap measured on `run_73627a191505`: a coordinator who follows this suite literally can dispatch, watch, merge, and tear down a grok worker without hitting an undocumented stall. The two-step recipe stays (it is what makes the permissive `worker` profile selectable). Promises that recipe cannot keep are withdrawn.

## Context
- Intake: `BRIEF-frictions-runtime-grok.md` (9 frictions from candigo `run_73627a191505`, 5 grok dispatches, PRs #59–#63).
- Host grok landed in `4bc69d3`. Verification this session: Orca `1.4.185`, grok `1.0.5`, `gh` `2.83.1`. Point 6 reproduced here (`check --peek` with no bound Run → `{count:0, ok:true}` vs `gate-list` → `run_required`). Point 2 is a structural contradiction in `skills/orca-orchestrate/runtimes.md` vs the Orca `worker-read` contract, not a grok bug.
- Setup marker: `docs/agents/setup.md` (written this session). Merge gate `ci: github-actions`. Tracker `github`. Default runtime `opencode`.
- Prior plan in this file was the executed `/orca-freebuff` plan — superseded.

## Decisions
- Keep the two-step launch (`terminal create --command "grok --agent worker --always-approve"`, then `worker-start --terminal`). Do not switch to `worker-start --agent grok`.
- Withdraw the supervised-path transcript promise. Grok's `-p` headless mode remains real and stays in COMPAT.md; it is not what `worker-read` gets on this recipe (`external_terminal` → `session_not_reported`).
- Folder trust is a distinct gate from `--always-approve`. Document the invite; add `--trust` only if the installed grok accepts it (completions and hooks doc say yes; `grok --help` omits it — probe, do not assume).
- `tui-idle` is not grok-ready. Readiness is `terminal read` for the real TUI markers (`always-approve` in the status bar and the `❯` prompt).
- `worker-release` → `retained / external_terminal` is nominal for this recipe. Close the terminal yourself, before `worktree rm`.
- Merge without `--delete-branch` while the task worktree still exists; delete the branch after `worktree rm`.
- `check --peek` without a bound Run is unknown, not empty. Bind or `run-use` before concluding the mailbox is empty.
- Tracker recorded in `docs/agents/setup.md` wins. A marker that says no issue mirror is a valid recorded choice; `/orca-tasks` must honor it rather than fight it. This repo's own tracker is full `github` (issues + PRs).
- Heartbeat wakeups and concatenated JSON / stderr keepalives are documented, not "fixed" in Orca.
- No worker is dispatched for this run. The orchestrator authors each isolated branch. Do not dispatch grok to document grok.
- Orca CLI changes (custom argv on `--agent grok`, `check --peek` returning `run_required`, stdout JSON concat as a binary bug) are out of this repo.

## Out of scope
- Patching the Orca binary or grok CLI.
- Replaying the candigo run.
- Making grok the default worker runtime of *this* repo.
- Shipping `BRIEF-frictions-runtime-grok.md` as a skill.
- Regenerating `docs/diagrams/orca-pipeline.*`.
- A `docs/agents/setup.md` tracker enum validator unless t4's spec needs a shared token list to stay consistent.

## Tasks

### t1: Honest grok recipe
- spec: Edit `skills/orca-orchestrate/runtimes.md` (and the grok row of `docs/COMPAT.md`) so the prescribed grok launch is honest. Keep the two-step command that selects `--agent worker` and `--always-approve`. State that this path is an `external_terminal` and `worker-read --source auto` will not return a hook-reported Grok transcript (`fallbackReason: session_not_reported` is expected). Qualify "has a real headless mode" as `grok -p` / `--prompt-file`, not the supervised TUI path. Document the first-launch folder-trust invite (`Do you trust the contents of this directory?`) as a gate `--always-approve` does not cover; persist via `--trust` only after probing that the installed grok accepts the flag. Replace `tui-idle` as the grok availability step with `terminal read` until the status bar shows `always-approve` and the prompt is `❯`. Do not edit `orca-orchestrate/SKILL.md` in this task (t2 owns the settle loop). Seam: `node scripts/validate-skills.mjs` green; every relative link in the touched files still resolves. TDD does not apply to prose — the failing check is a coordinator who follows the page as written stalling on trust, `tui-idle`, or `worker-read`.
- blocked-by: none
- runtime: opencode
- isolated: yes
- budget: 45

### t2: Two-step settle loop
- spec: Edit `skills/orca-orchestrate/SKILL.md` so the DAG settle path matches the recipe t1 tells the truth about. Treat `worker-release` → `retained / external_terminal` as the nominal outcome of `terminal create` workers (all three supervised runtimes), then `orca terminal close` before `worktree rm`. Change the merge sequence so `gh pr merge --squash --delete-branch` is never run while the task worktree still exists: merge without deleting the branch, release, close the external terminal, `worktree rm --force`, then delete the remote branch. Watchdog: if `worker-read` returns `source: "terminal"` / `session_not_reported`, fall through to `terminal read` rather than treating an empty message list as a quiet-but-healthy worker. One sentence on `--wait --types worker_done,escalation,question`: type filters decide *when* the waiter wakes; the Delivery is still the oldest full batch, so heartbeats produce empty-looking windows. One sentence on `check --json`: keepalives go to stderr every 15s; concatenated JSON objects need a decoder loop, not a single `json.load`. Add or update the matching `docs/COMPAT.md` row for Orca `check`. Seam: `node scripts/validate-skills.mjs`; TDD does not apply — the check is the merge/teardown order a coordinator can follow without a cosmetic git error or a leaked terminal.
- blocked-by: t1
- runtime: opencode
- isolated: yes
- budget: 45

### t3: Peek without a Run is unknown
- spec: Edit `skills/orca-resume/SKILL.md` and `skills/orca-status/SKILL.md` so `orca orchestration check --peek` is never treated as an empty mailbox unless a Run is bound (`run-current` shows a run, or the call used `--run <id>`). Without that, `{ok: true, count: 0}` is a false negative — `gate-list` already fails with `run_required` in the same situation. Positive rule: read `run-current` (or pass `--run`) before reporting mail; if none is bound, say so and do not conclude "0 unread". Seam: `node scripts/validate-skills.mjs`; TDD does not apply.
- blocked-by: none
- runtime: opencode
- isolated: yes
- budget: 30

### t4: Tracker marker wins
- spec: Edit `skills/orca-setup/SKILL.md` and `skills/orca-tasks/SKILL.md` (README tracker table only if the new token must be visible there) so a setup marker that records GitHub follow-by-PR with **no issue mirror** is a first-class, recorded choice, not a coordinator improvisation. Introduce one explicit tracker token (do not parse free prose). `/orca-setup` may offer it; `/orca-tasks` step 5 follows the marker: mirror issues only for `github` and `linear`; skip issue create and worktree `--issue` / `--linear-issue` links when the marker says so. Precedence is one sentence in both skills: the marker wins. This repo's own marker stays full `github`. Seam: the token string is identical in setup and tasks (grep); `node scripts/validate-skills.mjs` green. TDD does not apply unless you add a validator assertion that the two skills list the same tracker tokens — do that only if it is a one-place list, not a duplicated enum.
- blocked-by: none
- runtime: opencode
- isolated: yes
- budget: 45

## Status
approved (2026-08-21)
