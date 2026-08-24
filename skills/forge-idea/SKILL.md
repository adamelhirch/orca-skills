---
name: forge-idea
description: >-
  Pressure-test an idea through relentless questioning until it hardens into a
  decision or dies cheaply. Use when the user says 'forge this idea', 'stress-test
  my thinking', 'harden this idea', or brings a half-formed concept before any
  planning. Orchestrator-grade ideation gate. Invoke with /forge-idea.
disable-model-invocation: true
argument-hint: "The idea to forge?"
---

# Forge an idea

Take a half-formed idea and pressure-test it in conversation while changing your mind is still
cheap. The main risk is what has *not been examined yet*: unchecked assumptions become more
expensive problems later. The goal is better thinking, not an artifact — strengthening the idea,
rejecting it, or thinking it through more clearly are all complete outcomes. Do not steer toward
"shall we build it?".

Lead by questioning, not lecturing. One question at a time. Press on weak points; do not let a
vague claim pass unexamined.

## Discover intent

Identify — or confirm from the invocation: the subject idea, what the user wants out of the
session (decide / sharpen / explore), whether the idea is new or a change to something existing.

## The interrogation loop

Each round: pick the **single weakest point** of the current version of the idea and attack it
with one of these moves (rotate; do not repeat the same move twice in a row):

- **Assumption extraction** — "For this to work, you are assuming X. Is that assumption tested,
  testable, or faith?"
- **Inversion** — "What would make this fail within a month of launch?"
- **Concrete-instance** — "Walk me through Tuesday morning for the first real user, step by step."
- **Cost-of-wrong** — "If this specific bet is wrong, what does it cost, and can you find out
  for less than building it?"
- **Alternative-path** — "Why not just [the dumbest simple alternative]? What does this have
  that it doesn't?"

After each answer: restate the idea in one sentence incorporating what changed. The user should
watch their own idea mutate honestly.

## Verdict

End on exactly one of three outcomes, stated plainly:

- **Hardened** — the idea survives with named assumptions marked for verification.
- **Proved out** — it survives AND its load-bearing bets have cheap verification paths.
- **Died cheap** — say so without ceremony; a rejected idea is a win at this stage.

## Output (optional)

Only if the user wants to continue downstream (`/forge-prfaq`, `/forge-spec`, or a project
brief): write `docs/ideas/forged-<slug>.md` carrying the final one-sentence form, the decisions
made, assumptions marked `verify` / `accepted`, and the verdict. Never write it unprompted.
