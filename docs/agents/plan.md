# Plan — orca-skills: codify the `--depends-on` fallback in orca-tasks

Status: approved (lean path, user-authorized: "skip ce que tu peux si t'as déjà identifié le pb")

## Objective

`skills/orca-tasks/SKILL.md` says "(linked issues via `--depends-on` where supported)" — but on
the user's toolchain `gh issue create` (v2.83.1) has **no `--depends-on` flag at all**, and the
REST dependencies endpoint (`repos/{owner}/{repo}/issues/{n}/dependencies`) returns **404** on
their repos. Every session improvises the fallback. Codify a deterministic policy instead.

## Facts (verified this session)

- `gh issue create --help` (v2.83.1) — no `--depends-on` anywhere.
- `gh api repos/adamelhirch/adamHub/issues/141/dependencies` → 404 Not Found.
- The AdamHUB session already landed on the working behavior: Orca DAG (`--deps`) as the single
  source of truth for edges + edges documented in the issue body. It must be written down.

## Tasks

### t1 — Patch `skills/orca-tasks/SKILL.md` dependency-mirror policy (isolated: no)

No setup marker, no tracker configured, no CI in this repo → non-isolated run on the primary
worktree (integration pass on the current branch), done by the coordinator, no worker.

- Edit the github mirror step: the Orca DAG (`--deps`) is the single source of truth for edges;
  the issue mirror always documents `Blocked by: #N` / `Blocks: #M` in the body; attempt
  `--depends-on` only if the installed `gh` supports it (runtime detection), never depend on it.
- Keep the linear path unchanged (`orca linear relation add --type blocks` works).
- Branch `fix/orca-tasks-depends-on` → commit → push → PR → verify (no CI; gate = diff review +
  doc coherence) → squash-merge → delete branch.

## Seams / tests

No code, no tests. Validation: the patched skill reads coherently end-to-end, the linear path is
untouched, and the wording no longer implies `--depends-on` is available.
