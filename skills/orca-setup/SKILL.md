---
name: orca-setup
description: >-
  Hook a project up to Orca supervised orchestration: register the repo (creating
  or linking a GitHub repo when none exists, asking public/private), install the
  worker + orchestrator agent pairs (opencode and Claude Code), resolve the merge
  gate that defines what "verified" means here (github-actions, a local test
  command, or an explicitly accepted unverified project), and record the per-repo
  conventions plus the issue tracker (github, github-pr, or linear via orca linear —
  always resolving the workspace). Two flows: a new empty project and an existing repo.
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
   Never silently create a repo, and never assume `github` or `github-pr` tracking without a
   remote.
4. Detect the primary worktree: `orca worktree list --json` and take the worktree whose
   `isMainWorktree` is `true`. If none is tagged, ask the user which worktree is primary.
   The primary worktree is the cockpit: it stays on the default branch, receives merged PRs,
   and is where the orchestrator coordinates from. Tasks never run in it.
5. Make every supported host runnable (opencode, Claude Code, Grok) with the installer:
   ```bash
   <skill-dir>/install-agents.sh --dry-run   # show the four destinations
   <skill-dir>/install-agents.sh             # compose and install
   ```
   Each installed agent is a **host header** (`agents/<host>/<role>.md`: frontmatter +
   host-specific permission notes) concatenated with the **shared behaviour contract**
   (`agents/_shared/<role>-contract.md`). The contract exists once per role, so a rule fixed once
   is fixed on every host. Never edit an installed agent in place and never copy the host headers
   by hand — a header without its contract is a worker with no lifecycle, TDD, or merge-gate
   rules at all.

   It also **links this suite's skills into opencode's skills directory**. `skills add` installs
   into the universal root (`~/.agents/skills`) and wires Claude Code and Grok up automatically,
   but not opencode, which reads `~/.config/opencode/skills` — without the link an opencode session
   has the agents but none of the `/orca-*` commands. The skill names come from the suite's own
   directory, so one added or retired upstream needs no edit here. On a machine without opencode
   the step is skipped rather than demanded.

   The script exits non-zero and names what failed: an agent destination that cannot be written
   (the known case is a `~/.claude/agents/` owned by another account), or skills that are not
   installed yet — it prints the `skills add` command to fix that. A half-installed host stalls a
   run, so **setup is not complete until it exits 0.** Restart any agent session that was already
   running: agents and skills are read at startup.
6. Verify both layers of skills are present on this host:
   - **The Orca binary guides** (the skills load their command surface from the binary, never
     from this repo): `orca skills get orchestration` and `orca skills get orca-cli` must both
     return the guides. If either fails, run `orca skills install` first. Presence check only —
     the guides stay in the binary.
   - **The pipeline skills themselves.** A host missing `/orca-plan` or `/orca-tasks` cannot run
     the pipeline, and the symptom is confusing: the slash command simply does not exist. Check
     `ls ~/.claude/skills/ | grep orca` (Claude Code) and the equivalent for other hosts, and
     re-install what is missing:
     ```bash
     cd ~ && npx -y skills add adamelhirch/orca-skills --global --skill '*' -y
     ```
     Two traps worth knowing. **Run it from outside a project directory, or pass `--global`** —
     `skills add` auto-detects scope and installs *project-locally* when run inside a repo,
     which drops a copy of the suite into that repo's working tree. And **an old install does
     not self-heal**: skills added since the last install are simply absent, and skills deleted
     from the repo (e.g. the retired `orca-worker`) stay behind as ghosts until removed by hand
     (`rm -rf ~/.claude/skills/<name>`). New skills only appear after the agent restarts.
7. **Record the issue tracker.** Ask the user which tracker to use. Record the chosen token
   verbatim under `## Issue tracker` in the setup marker (no separate config file). The three
   tokens:
   - **github** — issues + PRs. Requires a GitHub remote (set in step 3). `/orca-tasks` mirrors
     each task as a `gh issue` and links the task worktree (`orca worktree set --worktree <sel>
     --issue <num>`), which surfaces it in Orca's Tasks tab under GitHub.
   - **github-pr** — GitHub follow-by-PR only. Requires a GitHub remote (set in step 3). The
     Orca DAG is the source of truth for dependencies; PRs are the human-visible trail.
   - **linear** — Linear issues. Mandatory workspace resolution. Orca never creates a Linear
     workspace; it only works on workspaces already connected in Orca settings. Run
     `orca linear team list --workspace all --json` and present the returned list (each team
     shows its `key`, `name`, and `workspace.id`). Ask the user which workspace (and which team
     key) issues should mirror to. Do **not** proceed past setup with Linear chosen but no
     workspace recorded — every later `orca linear` call needs `--workspace <id>` to target the
     right one. A task worktree then links to its Linear issue
     (`orca worktree set --worktree <sel> --linear-issue <key>`) so the tracking shows up in
     Orca's Tasks tab under Linear.

   One token per project. There is no markdown tracker — `github-pr` is the recorded
   GitHub-PRs-only choice. **The setup marker wins.** `/orca-tasks` follows the recorded token;
   it does not override a `github-pr` marker by creating issues because the skill's default is
   `github`. An empty GitHub issue list under `linear` or `github-pr` is the recorded choice.
8. **Choose the worker runtime.** This is *what runs the tasks*, and it is **independent of the
   orchestrator** — the orchestrator is simply whichever TUI you coordinate from. Ask the user
   which runtime the workers should use by default; the plan can override it per task:
   - **`opencode`** (default) — permissive `worker` profile, broad model choice, reports its own
     `worker_done`.
   - **`claude-code`** — the `worker` agent installed in `~/.claude/agents/`, reports its own
     `worker_done`.
   - **`grok`** — the `worker` agent installed in `~/.grok/agents/`, reports its own `worker_done`.
   - **`freebuff`** — free and ad-funded, but there is **no agent in the terminal**: the
     coordinator types the prompt, polls for a completion marker, verifies the work itself, and
     signs the `worker_done` in the worker's name. It cannot run unattended. Only record it as
     the default when the user wants free workers knowing that cost; otherwise leave it as a
     per-task override.

   Confirm the chosen runtime is actually usable before recording it: the agent pair installed in
   step 5 for `opencode`/`claude-code`/`grok`, or `freebuff --version` plus a logged-in session for
   `freebuff`. The dispatch recipes for all three ship with `/orca-orchestrate` (its
   `runtimes.md`) — this step only records the choice.
9. **Determine and record the merge gate.** "CI green" is meaningless until you know what runs
   here — and it degrades silently: `gh pr checks` prints `no checks reported` and **exits 0** on
   a repo with no workflows, so a worker that trusts the exit code reports success having run
   nothing. Resolve the gate now, at setup, where a human is present. Probe, then confirm with
   the user:
   ```bash
   gh api repos/:owner/:repo/actions/workflows --jq '.total_count'   # 0 = no GitHub Actions
   ls .github/workflows 2>/dev/null
   ```
   Record exactly one mode:
   - **`ci: github-actions`** — the probe found at least one workflow. `gh pr checks` is
     authoritative, **and an empty check set is a failure, not a pass**. Only valid with a
     GitHub remote.
   - **`ci: local <command>`** — no CI, but the repo has a test command. Ask the user for the
     exact command (`uv run pytest`, `npm test`, `cargo test`, …), **run it once yourself** to
     confirm it exists and exits 0 on a clean tree, and record it verbatim. This is the normal
     mode for a local-only or linear-tracked project.
   - **`ci: unverified`** — no CI and no test command. Do **not** choose this for the user:
     state plainly that every task will merge with nothing verifying it, and record it only on
     an explicit acceptance, with the reason.

   A repo with tests but no recorded gate is the failure this step exists to prevent. If the
   probe finds workflows *and* the user names a local command, prefer `github-actions` and note
   the local command alongside it.
10. Write the setup marker `docs/agents/setup.md` (create the `docs/agents` directory if
   missing). It records everything the rest of the pipeline relies on:
   ```
   # Orca setup — <repo> — <date>

   ## Primary worktree   (selector / display name of the cockpit worktree)
   ## Repo               (remote or "local-only")
   ## Worker runtime     (opencode | claude-code | grok | freebuff — default for this project)
   ## Merge gate         (ci: github-actions | ci: local <command> | ci: unverified — verbatim)
   ## Conventions        (one-task-one-branch, TDD by default)
   ## Issue tracker      (github | github-pr | linear — with workspace id + team key for linear)
   ## Agents installed   (worker + orchestrator for opencode and Claude Code)
   ## Guides             (orca orchestration + orca-cli present in the binary)
   ## Status             (setup complete | skipped — <reason>)
   ```
11. Point the primary worktree card at it:
   `orca worktree set --worktree <primary-selector> --comment "setup → docs/agents/setup.md"`.

## What appears in Orca's Tasks tab

The Tasks tab is the **issue-tracker view** — it shows GitHub issues and Linear issues only, and
a task shows up there **only if its worktree is linked to an issue** (`--issue` / `--linear-issue`).
Orchestration tasks (`orca orchestration task-*`) are coordination state — the DAG, dispatch
statuses, and gates — visible in the orchestration context and the worktree card, **not** in the
Tasks tab. `/orca-tasks` sets the worktree link after creating a mirror issue for `github` and
`linear`. Under `github-pr` the trail is the PRs; the DAG stays visible as orchestration state.

## Done when

- The repo is registered in Orca; the primary worktree is identified; a GitHub remote exists
  or "local-only" was explicitly recorded.
- Both agent pairs (`worker` + `orchestrator`) are installed for opencode and Claude Code —
  `install-agents.sh` exited 0, so all four destinations are composed, not just some.
- The **merge gate** is recorded verbatim in `docs/agents/setup.md`: `github-actions` (workflows
  confirmed present), `local <command>` (command run once and confirmed), or `unverified`
  (explicitly accepted by the user, with the reason). A project whose gate is unrecorded cannot
  be orchestrated — the worker has no definition of "verified".
- The official guides (`orca orchestration`, `orca-cli`) are confirmed present in the binary, and
  every pipeline skill is installed for this host (no missing skill, no ghost of a retired one).
- The **worker runtime** default is recorded and confirmed usable, chosen independently of
  whichever agent the orchestrator is running in.
- The tracker token is recorded verbatim in `docs/agents/setup.md` under `## Issue tracker`:
  **github** with a confirmed remote, **github-pr** with a confirmed remote, or **linear** with
  a concrete `workspace` id + `team` key chosen by the user from
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
