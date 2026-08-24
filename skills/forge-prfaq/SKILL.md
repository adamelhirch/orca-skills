---
name: forge-prfaq
description: >-
  Working Backwards PRFAQ challenge: stress-test a product concept customer-first
  by writing the press release before anything is built, then attacking it. Use
  when the user says 'create a PRFAQ', 'work backwards', or brings a product
  concept that needs hardening. Invoke with /forge-prfaq.
disable-model-invocation: true
argument-hint: "Product concept to work backwards from?"
---

# Working Backwards: the PRFAQ challenge

Forge product concepts through Amazon's Working Backwards methodology. Act as a relentless but
constructive product coach: stress-test every claim, challenge vague thinking, refuse to let weak
answers pass — but offer concrete reframings when the user is stuck. Tough love, not tough
silence. If a compelling press release cannot be written, the product is not ready; both outcomes
are wins.

## The three artifacts

Write them in order, in `docs/prfaq/<slug>/`. Each is drafted, then attacked, before the next.

### 1. The press release (~1 page, dated at future launch)

Fixed sections: headline; sub-headline (one sentence, who + what benefit); summary paragraph;
problem paragraph (customer words, not industry words); quote from an internal leader; how the
customer's life changes (concrete, no adjectives); a customer quote; call to action.

Rules: written for the **customer**, never for the company. No feature lists — outcomes. If a
sentence would embarrass you read aloud at launch, rewrite it now.

### 2. Customer FAQ (external)

The questions a skeptical prospective user actually asks: why would I switch? what happens to my
data? how much? why not [incumbent]? Every answer must be falsifiable — "faster" gets a number or
gets cut.

### 3. Internal FAQ (feasibility)

The questions engineering/finance/legal ask: why us, why now? what is the hardest technical risk?
what does this cannibalize? what must be true in 12 months? Name the risks nobody has budgeted.

## The challenge pass

After drafting, run one adversarial round against your own three artifacts:

1. Read only the press release. Would a busy journalist publish it? If not, why not — that reason
   is usually the real weakness of the concept.
2. For every claim in the customer FAQ, ask "how do we know?" Unverified claims get marked
   `assumption` — they become research probes (`/forge-research`) or die here.
3. Find the one internal FAQ answer that is hand-waving. That is where the concept actually
   breaks. Surface it explicitly instead of polishing over it.

## Output

`press-release.md`, `customer-faq.md`, `internal-faq.md` in `docs/prfq/<slug>/`, plus a short
`distillate.md`: the concept in five fields (why, capabilities, constraints, non-goals, success
signal) ready for `/forge-spec` or `/orca-plan` consumption. Research-grounded claims cite
sources; everything else stays marked as assumption.
