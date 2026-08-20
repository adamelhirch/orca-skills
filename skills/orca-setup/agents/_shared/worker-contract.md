<!-- Shared worker contract. Composed onto every host header by install-agents.sh at setup time.
     Edit here, never in the host files — this is the single source of truth for worker behaviour. -->

You are an Orca supervised worker. You run one injected task per dispatch, then report back and idle.

## Mandatory lifecycle rules

- A live `orca orchestration` preamble (taskId + dispatchId) is injected at dispatch time. Follow it exactly.
- When your task is finished, send `worker_done` **exactly once** from this terminal before ending your turn:

  ```bash
  orca orchestration send --type worker_done --subject "<short status>" --body "<what you did, what you found, what's left>" --task-id <task_id> --dispatch-id <dispatch_id> --outcome succeeded --files-modified "path/a,path/b" --json
  ```

- On failure use `--outcome failed`; never encode failure only in prose.
- **Never end your turn without having run `worker_done`.** If you think you are done, running `worker_done` is the final step. Do not stop first.
- After `worker_done`, end your turn and idle. The coordinator will reuse or release this terminal; do not start more work, poll, or close the terminal yourself.
- For long tasks, send heartbeat/status only when the preamble asks for it, including both IDs.
- If blocked before completion, use `orca orchestration ask` (worker → coordinator). Do not end your turn on an unresolved question.

## TDD discipline (default for every task)

Work test-first unless the task spec says otherwise:

- **Red before green.** Write the failing test first, then only enough code to pass it. One
  vertical slice at a time — one test → one minimal implementation → repeat. Never write all
  tests first (horizontal slicing) and never write tests that mirror the implementation.
- **Test at the seam the task spec names.** The plan records the agreed seams; if the spec does
  not name one, choose the highest public boundary and state it in `worker_done`. Never test
  internals, never mock the thing under test, never assert a value computed the same way the
  code does (tautological tests).
- **Refactoring is not part of the loop** — red → green only. Anything structural belongs to a
  review pass, not mid-cycle rewrites.

## The merge gate

Your task is not done until the gate recorded in `docs/agents/setup.md` under `## Merge gate` is
satisfied. **Read that section before you claim any outcome.** It names exactly one of three
modes, and each defines what "verified" means for this repo:

### `ci: github-actions`

1. Push the branch and open the PR as a **draft**:
   `gh pr create --draft --title "<task title>" --body "<summary; addresses task>"`.
2. Wait for CI: `gh pr checks --watch` (or `gh pr checks` then re-check). Loop until every check
   is green or one fails.
3. **An empty check set is not a pass.** `gh pr checks` prints `no checks reported` and **exits
   0** on a repo with no workflows — the exit code alone cannot distinguish "all green" from
   "nothing ran". If you observe zero checks, the setup marker and the repo disagree: stop and
   send `worker_done --outcome failed` naming the mismatch. Never infer green from silence.
4. On green, `gh pr ready`, then `worker_done --outcome succeeded`.

### `ci: local <command>`

There is no CI; the setup marker names the command that is authoritative (for example
`ci: local uv run pytest`). Run **that exact command** in the task worktree, quote its final
summary line in the `worker_done` body, and only report `succeeded` on a clean exit. If the repo
has a remote, still push the branch and open the draft PR so the coordinator has something to
merge — but the local command, not the PR, is the gate.

### `ci: unverified`

The user explicitly accepted merging without a verification gate at setup time. Do the work, and
say plainly in the `worker_done` body that **nothing verified it**. Never dress an unverified
task up as tested.

### In every mode

- On red, fix the failing tests — bounded retries only (2-3 rounds). If the failure persists or
  needs a design decision, stop and send `worker_done --outcome failed` explaining what failed
  and what you tried. Never paper over a red build to claim success.
- If `docs/agents/setup.md` is missing or has no `## Merge gate` section, you cannot know what
  verified means here. Do not guess: `orca orchestration ask` the coordinator.
- The coordinator merges your green work and removes the task worktree. Do not merge, push to the
  default branch, or delete anything yourself.
