---
name: forge-context
description: >-
  Set up, refresh, or audit a repository's agent instructions (AGENTS.md /
  CLAUDE.md block) so any AI agent works well in this codebase from minute one.
  Use when the user says 'document this project for agents', 'generate project
  context', or 'audit the AGENTS.md'. Invoke with /forge-context.
disable-model-invocation: true
argument-hint: "Set up, refresh, or audit?"
---

# Project context

Give every AI agent landing in this repo the context that makes it useful immediately — and keep
that document honest over time. Three intents: **set up**, **refresh**, **audit**.

The file: `AGENTS.md` at repo root (the cross-tool convention most agents auto-load; a one-line
pointer to it may live in CLAUDE.md if the user wants Claude-specific visibility too).

## Set up

Investigate before writing — read-only sweep:

1. **Shape**: entry points, build/run/test commands (run them to verify, never copy from docs
   untested), directory map with one line per top-level dir.
2. **Conventions actually in force**: naming, error handling patterns, test layout — derived from
   reading several files per area, not from aspiration. What the code does, not what a CONTRIBUTING
   file wishes.
3. **Boundaries**: what must not be touched casually (generated dirs, lockfiles, migration order),
   where new modules go, which seams tests use.
4. **Verification contract** — the exact commands that prove a change is good (this is what an
   agent will be held to; make them copy-pasteable).

Write `AGENTS.md` ≤ ~80 lines. Facts over prose; every command verified by running it; nothing
that duplicates what `--help` says.

## Refresh

Re-run the sweep, diff against the existing AGENTS.md: stale commands (repo moved), conventions
that drifted, sections nobody reads. Apply changes with a dated changelog line at the bottom.
Refresh is also triggered by `/forge-retrospective` findings when process changes alter how agents
should work here.

## Audit

Attack the current file as a fresh agent would: follow its instructions literally on a small task
(can you build? test? find the right module?). Every instruction you had to interpret twice gets
rewritten. Flag anything the file asserts that the repo contradicts — stale context is worse than
none, because it comes with confidence.
