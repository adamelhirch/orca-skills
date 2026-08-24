---
name: forge-research
description: >-
  Decision-grade research on a market, domain, or technical question: draft a
  deep-research prompt, run web fan-out with cited digests, or process an external
  report. Every claim carries a source; conclusions never come from training data
  alone. Use when a decision needs evidence ('research X before we decide').
  Invoke with /forge-research.
disable-model-invocation: true
argument-hint: "What decision does this research serve?"
---

# Deep recon

A research director, not a search engine: frame research worth running, then turn whatever comes
back into a decision-grade artifact consumed without reprocessing. Every engagement serves a
**decision** — enter a market, pick a stack, price a product, commit to a domain.

## Standing epistemics (inherited by any subagent spawned)

1. **Never conclude from training data alone.** Prior knowledge proposes hypotheses and queries;
   conclusions require evidence retrieved *this run*. A claim you cannot evidence is stated as an
   unverified belief or not at all.
2. **Research firewall.** Project context shapes *what to ask*, never *what is true*. Briefs and
   plans are inadmissible as evidence: every claim in the artifact traces to a digest with a
   source.
3. **A claim is a sentence with a source** — publisher, date. No naked numbers. Absence of
   evidence is reported as thin data, honestly. Freshness windows per claim class: market sizes
   older than ~18 months are history, pricing older than a quarter is suspect.
4. **Extract, don't ingest.** Raw pages are filtered into digests; the parent reads digests, never
   raw dumps. When spawning subagents for parallel search fan-out, each gets only its brief.

## Three services (freely combined)

### Draft

Write a deep-research prompt for the user's own heavy tool (their ChatGPT/Gemini deep-research):
the decision context, the exact questions, the output shape that will feed Process. For when the
user wants maximum firepower outside this session.

### Run

Frame 3–6 research questions from the decision. Fan out searches (parallel subagents where
available), write each digest to disk as it lands, then synthesize. Web access required; if
unavailable, fall back to Draft — never fabricate.

### Process

Take a finished external report (path/paste), extract the claims relevant to the decision with
their citations into the digest format, flag anything unverifiable.

## Artifact

`docs/research/<slug>/findings.md`: verdict-first (what this means for the decision), then
evidence per question with sources inline, then open gaps. One page of verdict, details behind.
Ends with the recommendation the evidence supports — or "insufficient evidence" with what would
settle it.
