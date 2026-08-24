# Pressure pass (deep mode)

Curated from BMad's elicitation catalog (72 methods), filtered to the ones that reliably find
plan-killing defects before workers are paid to discover them. Run **2–3 per plan** — not all
of them, and rotate between runs so different blind spots get covered. Each entry: what it
protects against, the procedure, and what must exist afterward. The pass runs on the *draft
plan*, before approval; its findings become plan edits or explicit accepted risks.

| # | Method | Protects against | Procedure | Exit artifact |
| --- | --- | --- | --- | --- |
| 1 | **Pre-mortem** | Optimistic sequencing; missing failure paths nobody owns | "It is T+2 weeks and this run failed badly." Every participant lists the cause; cluster into: spec defects, sandbox/runtime limits, dependency surprises, human-gate stalls. Each cluster either changes a task, adds a decision, or is written down as an accepted risk with an owner | Failure-mode table → edits or logged risks |
| 2 | **Red team** | A plan that only its author has attacked | Argue *against* the plan as if paid to kill it: wrong seams, tasks sized over a context window, shared files, missing verification. The author may defend only with evidence already in the repo — not intentions | Top-3 attacks, each resolved (edit / gate / risk) |
| 3 | **Socratic assumption audit** | Hidden premises inherited from how the problem was phrased | For every load-bearing decision ask "why?", up to 4 levels. Any chain ending in "we assumed" becomes a verify-spec-facts probe or gets marked as an assumption in the spec | List of assumptions → probes or marked assumptions |
| 4 | **Green hat / alternative outcomes** | One implicitly-chosen solution shape | Force 3 genuinely different solution shapes for the same objective; explain why the chosen one beats each. If any rival survives cleanly, it goes to the user as a real option, not a footnote | Rival-shapes note + the user's pick on record |
| 5 | **Five whys on the objective** | Solving a symptom | Why is this objective wanted? ×5. If the root want is cheaper served another way, surface that before tasks are cut | Root-need statement in the plan's Objective section |
| 6 | **Anticipatable-objections sweep** | Review-stage rework | List the objections a skeptical reviewer of the *finished* work would raise (security, RGPD, perf, cost). Map each to a task or an explicit out-of-scope line | Objection→task/out-of-scope mapping |

Rules of engagement:

- Findings do not restart the interview; they edit the plan in place and re-run only the
  affected frontier questions.
- A pressure method that finds nothing records that in one line — a clean bill is also evidence.
- The pass ends when 2–3 methods have run AND every finding is either in the plan, a marked
  assumption, or a logged accepted risk.
