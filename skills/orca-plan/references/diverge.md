# Divergence techniques (deep mode)

Curated from BMad's brainstorming library, filtered for what an Orca-run plan needs: not raw
creativity, but *structured option generation before the design tree freezes*. Run 2–4 of these
in the Diverge phase — announce the batch before starting, capture output as candidate
decisions/options (not prose), and feed every survivor into the frontier interview. Never let
the whole session be one technique; contrast is where the value is.

| # | Technique | When it earns its tokens | Procedure | Capture |
| --- | --- | --- | --- | --- |
| 1 | **First-Principles Decomposition** | The objective arrives pre-framed as "build X" and X may be the wrong unit of work | Strip the objective to physical/practical constraints (data, latency, budget, people). Ask what the minimal system satisfying those constraints is. Rebuild upward; compare against the framing you were handed | List of constraints + 1–3 alternative framings of the objective |
| 2 | **Inversion** | Nobody has asked how the run could fail *by design* yet | Ask: "what plan guarantees failure?" — list 5–8 credible sabotage paths (wrong seam, shared file, missing gate). Negate each into a plan requirement | Inverted requirements (they become plan decisions) |
| 3 | **SCAMPER sweep** | An existing system/workflow is being modified, not built greenfield | Walk Substitute/Combine/Adapt/Modify/Put-other-use/Eliminate/Rearrange against the current state; keep only entries that change task decomposition | Candidate tasks eliminated/merged/added |
| 4 | **Constraint relaxation→tightening** | Scope feels bloated or frozen early | Round 1: drop each hard constraint hypothetically (no RGPD, no CI, unlimited budget) — see what collapses to trivial. Round 2: tighten one constraint brutally (half the budget) — see what survives | Which constraints actually shape the DAG vs. decorative ones |
| 5 | **Role storming** | Only the requester's perspective exists so far | Generate needs/complaints from: end user, worker executing t-n, code reviewer, on-call/ops, future maintainer. Each role gets 2 non-obvious needs | Missing requirements per stakeholder |
| 6 | **Analogy transfer** | The domain is unfamiliar or the team keeps reinventing | Name 2 mature systems that solved something structurally similar; steal their decomposition vocabulary and their known failure modes | Borrowed decomposition + borrowed pitfalls list |
| 7 | **Random/forced connection** | The obvious 3 options are all variants of each other | Pick an unrelated mechanism at random; force a mapping onto the problem for 3 minutes; keep only mappings that survive 2 questions | 0–2 genuinely novel candidates (most die — that is fine) |
| 8 | **Mind-map seeding** | The objective is fuzzy and the frontier interview hasn't started | Free-associate branches for 10 minutes, then cluster into: decisions, unknowns, deliverables. The clusters are literally the design tree's first draft | Clustered map → direct input to the frontier |

Rules of engagement:

- Timebox each technique; a stalemate after ~10 minutes is a result, not a failure.
- Divergence produces **candidates**, never commitments. Nothing enters the plan without
  surviving the Pressure pass (`pressure.md`) and the frontier interview.
- If a technique yields nothing, say so in one line and move on — do not pad.
