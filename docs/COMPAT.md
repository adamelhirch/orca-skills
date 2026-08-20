# Compatibility matrix

The skills in this suite encode workarounds for concrete tool limitations. Those workarounds are
only correct against the versions they were verified on — and prose buried in a runbook gives no
way to tell what is still true. This table is the single place that records **what was checked,
when, and what would make it stale**.

Update a row when you verify it; add the date. A stale row is a bug report waiting to happen.

| Tool | Verified version | Date | Constraint encoded in the suite | Retest when |
| --- | --- | --- | --- | --- |
| Orca CLI / app | `1.4.184` | 2026-08-20 | The command surface is loaded from the binary at run time (`orca skills get orchestration`, `orca skills get orca-cli`) and never copied into this repo. | Never pinned on purpose — but if a skill starts naming a flag that `orca <cmd> --help` does not list, that flag leaked out of the binary and into prose. |
| `gh` | `2.83.1` (2025-11-13) | 2026-08-20 | `gh issue create` has **no `--depends-on`** flag and the REST dependencies endpoint 404s, so `/orca-tasks` carries dependency edges in the Orca DAG (`--deps`) and documents them in the issue body. `gh issue create` also has **no `--json`** — the issue number is parsed from the URL on stdout. | A `gh` upgrade. Re-probe with `gh issue create --help \| grep depends-on`; if it appears, the real blocking link becomes available and the body mirror becomes redundant. |
| `gh` (checks) | `2.83.1` | 2026-08-20 | `gh pr checks` on a repo with **no** workflows prints `no checks reported` and **exits 0**. An empty check set is therefore indistinguishable from a green one by exit code alone — which is why the merge gate is a capability recorded at setup, not something inferred at merge time. See [`skills/orca-setup/SKILL.md`](../skills/orca-setup/SKILL.md). | A `gh` upgrade changing the exit code, or GitHub changing the empty-checks response. |
| opencode | `1.18.15` | 2026-08-20 | `-a <agent>` is **broken in TUI mode** (prints help and exits), so the `worker` profile is selected with `OPENCODE_CONFIG_CONTENT='{"default_agent":"worker"}'` plus `--auto`. Also defaults to prompting for `external_directory` and `doom_loop`, which the worker profile auto-allows. | An opencode upgrade. Re-probe with `opencode -a worker` in a TUI terminal; if it launches instead of printing help, the env-var workaround can be dropped from `/orca-orchestrate`. |
| Claude Code | `2.1.227` | 2026-08-20 | Agent pairs install to `~/.claude/agents/`; the permissive worker uses `permissionMode: bypassPermissions`. A pre-existing root-owned `~/.claude/agents/` blocks the copy. | A change to the agent frontmatter schema or the agents directory location. |
| freebuff | `0.0.149` | 2026-08-18 | **No headless mode** — `--print`, `-p`, `--json`, `--non-interactive`, `--batch`, `--exec`, `--auto`, `--script`, `--prompt` all rejected as `unknown option`. `@codebuff/sdk` needs a paid key. Hence the terminal-driven TUI pattern in [`skills/orca-freebuff/SKILL.md`](../skills/orca-freebuff/SKILL.md): marker polling + impersonated `worker_done`. | **Now — drift detected: `freebuff --version` reports `0.0.150` on this host.** Re-probe the headless flags; if any is accepted, the whole TUI-driving pattern collapses into a normal dispatch and the skill should be rewritten, not patched. |

## How the suite is meant to degrade

Every workaround above is a *fallback from a missing capability*. When a tool gains the
capability, the correct move is to delete the workaround, not to keep both paths — two paths mean
two behaviours to reason about and only one of them gets tested.
