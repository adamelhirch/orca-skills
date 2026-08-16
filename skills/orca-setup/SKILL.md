---
name: orca-setup
description: >-
  Hook a project up to Orca supervised orchestration: register the repo (creating
  or linking a GitHub repo when none exists, asking public/private), install the
  worker + orchestrator agent pairs (opencode and Claude Code), and record the
  per-repo conventions (CI-green, one-task-one-branch, primary worktree) plus the
  issue tracker (github via gh, or linear via orca linear — always resolving the
  workspace). Two flows: a brand-new empty project and an existing repo.
  Orchestrator sessions only. Invoke with /orca-setup.
disable-model-invocation: true
argument-hint: "New project or existing repo?"
---

# Set up a project for Orca orchestration

Prepare a project so the planning-to-orchestration pipeline (`/orca-plan`, `/orca-tasks`,
`/orca-orchestrate`) can run on it. This skill replaces the old `/orca-worker`: a project needs
both agents to be orchestrated — the `worker` runs the tasks, the `orchestrator` is the
persistent cockpit agent that brainstorms, critiques, plans, and monitors before any worker
runs.

The pipeline refuses to run without a setup marker (`docs/agents/setup.md`). If a session
lands on `/orca-plan`, `/orca-tasks`, or `/orca-orchestrate` and the marker is missing, it
routes back here. A user can deliberately skip setup — record that choice in the marker too.

## Load the guides before any command

```text
orca skills get orca-cli
orca skills get orchestration
orca skills get orca-linear   # only when Linear is chosen
```

Read them before running anything. Prefer `--json` for agent-driven calls. Never guess
subcommands or flags from memory.

## Two flows

Pick the flow by the state of the target directory:

- **New** — an empty or nearly-empty directory that should become a fresh Orca project.
  Initialize git, register it, and leave it ready to plan the first run.
- **Existing** — a repo where work has already started and you want to take it over with Orca
  orchestration. Register it if Orca does not know it, then hook it up without touching the
  existing work.

## Steps

1. Identify the project directory and its state:
   - `orca repo list --json` — is the path already registered in Orca?
   - `git status` / `ls -a` in the directory — empty vs. already a working repo?
   - `git remote -v` — is there a GitHub (or other) remote already?
2. Register the repo if needed:
   ```bash
   orca repo add --path <abs/path> --json
   ```
   For a brand-new directory that is not yet a git repo, initialize it first
   (`git init -b main`) and commit an initial scaffold, then register.
3. **GitHub repo create/link (when there is no remote):** run `git remote -v`. If there is no
   remote, ask the user explicitly:
   - **Create a GitHub repo** — ask **public or private**, then:
     ```bash
     gh repo create <name> --public --source . --remote origin --push
     # or: --private
     ```
     Push the current branch and re-run `git remote -v` to confirm.
   - **Link an existing GitHub repo** — `git remote add origin <url>` then `git push -u origin main`.
   - **Keep local-only** — no remote; record that choice.
   Never silently create a repo, and never assume `github` tracking without a remote.
4. Detect the primary worktree: `orca worktree list --json` and take the worktree whose
   `isMainWorktree` is `true`. If none is tagged, ask the user which worktree is primary.
   The primary worktree is the cockpit: it stays on the default branch, receives merged PRs,
   and is where the orchestrator coordinates from. Tasks never run in it.
5. Install the agent pairs for this host (opencode + Claude Code):
   - opencode: copy `agents/opencode/worker.md` to `~/.config/opencode/agents/worker.md`
     and `agents/opencode/orchestrator.md` to `~/.config/opencode/agents/orchestrator.md`
     (create the `agents` directory if missing).
   - Claude Code: copy `agents/claude/worker.md` to `~/.claude/agents/worker.md` and
     `agents/claude/orchestrator.md` to `~/.claude/agents/orchestrator.md`.
   - If a target `agents` directory did not exist when the agent session started, restart that
     agent once so the definitions are picked up.
6. Verify the official guides are present (the skills load their command surface from the
   Orca binary, never from this repo): `orca skills get orchestration` and
   `orca skills get orca-cli` must both return the guides. If either fails, run
   `orca skills install` first. This is a presence check only — the guides stay in the binary.
7. **Record the issue tracker.** Ask the user which tracker to use. The two supported trackers
   are **github** (via `gh`) and **linear** (via the native `orca linear` CLI). There is no
   markdown tracker and no "none" choice — issue tracking lives in the tracker itself. Record
   the choice directly in the setup marker (no separate config file):
   - **github** — requires a GitHub remote (set in step 3). `/orca-tasks` mirrors each task as a
     `gh issue` and links the task worktree (`orca worktree set --worktree <sel> --issue <num>`),
     which surfaces it in Orca's Tasks tab under GitHub.
   - **linear** — mandatory workspace resolution. Orca never creates a Linear workspace; it only
     works on workspaces already connected in Orca settings. Run
     `orca linear team list --workspace all --json` and present the returned list (each team
     shows its `key`, `name`, and `workspace.id`). Ask the user which workspace (and which team
     key) issues should mirror to. Do **not** proceed past setup with Linear chosen but no
     workspace recorded — every later `orca linear` call needs `--workspace <id>` to target the
     right one. A task worktree then links to its Linear issue
     (`orca worktree set --worktree <sel> --linear-issue <key>`) so the tracking shows up in
     Orca's Tasks tab under Linear.

   **The two trackers are exclusive.** One project mirrors to exactly one tracker — `github` or
   `linear`, never both. With `github`, only `gh` issues are created; with `linear`, only Linear
   issues. An empty GitHub issue list on a linear-tracker project is expected, not a bug.
8. Write the setup marker `docs/agents/setup.md` (create the `docs/agents` directory if
   missing). It records everything the rest of the pipeline relies on:
   ```
   # Orca setup — <repo> — <date>

   ## Primary worktree   (selector / display name of the cockpit worktree)
   ## Repo               (remote or "local-only")
   ## Conventions        (CI-green merge gate, one-task-one-branch, TDD by default)
   ## Issue tracker      (github | linear — with workspace id + team key for linear)
   ## Agents installed   (worker + orchestrator for opencode and Claude Code)
   ## Guides             (orca orchestration + orca-cli present in the binary)
   ## Status             (setup complete | skipped — <reason>)
   ```
9. Point the primary worktree card at it:
   `orca worktree set --worktree <primary-selector> --comment "setup → docs/agents/setup.md"`.

## What appears in Orca's Tasks tab

The Tasks tab is the **issue-tracker view** — it shows GitHub issues and Linear issues only, and
a task shows up there **only if its worktree is linked to an issue** (`--issue` / `--linear-issue`).
Orchestration tasks (`orca orchestration task-*`) are coordination state — the DAG, dispatch
statuses, and gates — visible in the orchestration context and the worktree card, **not** in the
Tasks tab. `/orca-tasks` always sets the worktree link after creating a mirror issue, so every
task appears in the Tasks tab under the chosen tracker.

## Done when

- The repo is registered in Orca; the primary worktree is identified; a GitHub remote exists
  or "local-only" was explicitly recorded.
- Both agent pairs (`worker` + `orchestrator`) are installed for opencode and Claude Code.
- The official guides (`orca orchestration`, `orca-cli`) are confirmed present in the binary.
- The tracker is recorded in `docs/agents/setup.md`: **github** with a confirmed remote, or
  **linear** with a concrete `workspace` id + `team` key chosen by the user from
  `orca linear team list --workspace all`. Setup is not complete otherwise.
- The card comment points at `docs/agents/setup.md`.

## Troubleshooting

- If the Claude Code copy fails because `~/.claude/agents/` is not writable (e.g. owned by
  another account), make that directory user-owned first, then retry. The opencode agents are
  unaffected — they live in `~/.config/opencode/agents/`.
- `gh repo create --source .` requires an initial commit on the default branch; make one before
  creating. If the repo name already exists on GitHub, pick a different name.
- A Linear workspace must already be connected in Orca settings; `orca linear team list
  --workspace all` returning an empty list means no workspace is connected — surface that to the
  user instead of guessing.
