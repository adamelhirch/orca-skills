---
name: forge-e2e-tests
description: >-
  Generate end-to-end automated tests for implemented features from user journeys:
  pick the critical flows, write runnable test skeletons, wire them to real
  selectors/routes. Use when the user says 'create e2e tests' or after shipping a
  feature set that needs regression cover. Invoke with /forge-e2e-tests.
disable-model-invocation: true
argument-hint: "Which feature/flows to cover?"
---

# E2E test generation

Generate end-to-end tests that survive longer than the sprint: journey-driven, selector-disciplined,
minimal in count. Gate: the feature exists and runs (locally or staging) — tests against intent
are fiction. If UX flows exist (`docs/ux/*/ux-plan.md`), they drive; otherwise derive journeys from
PRD stories or click through the app yourself first.

## Method

1. **Pick the few flows that pay rent.** The money paths: signup → core action → outcome; plus the
   top failure recoveries. Rule of thumb: one e2e per user-visible capability that would embarrass
   if broken; everything smaller is an integration/unit test and belongs there instead.
2. **Detect the harness** before writing anything: Playwright / Cypress / none. None → recommend
   Playwright and scaffold config; do not invent a bespoke runner.
3. **Selector discipline** — target stable identity only: `data-testid`, roles, labels. Never CSS
   position/classes. If the app lacks testids on critical nodes, output a list of exact attributes
   to add as part of the deliverable (a tiny PR-sized change, huge stability win).
4. **Write journeys as arrange-act-assert** with real waits (state-based, never sleeps), explicit
   fixtures for auth/data, and cleanup that survives re-runs. Each test names the story/FR it
   guards in a comment — traceability both directions.
5. **Run them.** Green or fixed here, not "should pass". A generated-but-red suite is negative
   work delivered.

## Output

- Test files in the repo's convention location (detect it; default `e2e/`).
- `docs/qa/e2e-coverage.md`: flow → test file mapping + explicitly uncovered risks (what e2e
  deliberately does not attempt).
- If app changes were needed (testids): list them separately so a human/worker applies them.

In an Orca run, this skill's work decomposes naturally into tasks (one per flow); run it directly
for small sets, or hand the coverage doc to `/orca-plan` for larger ones.
