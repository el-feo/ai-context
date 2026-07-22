---
name: sherlock
description: Solve the mystery behind a bug, error, incident, or customer-reported problem — from any source (Sentry/Honeybadger alert, Zendesk or CX ticket, GitHub issue, pasted stack trace, log excerpt, or just a verbal description). Gathers evidence, checks boring explanations first, reproduces when feasible, runs git archaeology, forms and actively falsifies competing hypotheses, and — when the evidence supports it — declares the verified root cause and proposes a concrete fix. Use sherlock whenever the user asks to investigate, diagnose, debug, figure out, look into, get to the bottom of, troubleshoot, RCA, or find the root cause of a bug/error/crash/alert/incident/ticket, especially when the cause is not obvious or the user wants rigor rather than a guess. Prefer sherlock over ad-hoc debugging whenever the user's framing suggests "why is this happening" rather than "change this code".
---

# Sherlock

Most debugging goes wrong in the same way: the investigator finds the first plausible cause, declares victory, ships the patch — and the bug comes back, because the first plausible cause is almost never the root cause. It's a frame in the stack trace. It's what *fired the gun*, not what *loaded it*.

Sherlock exists to break that habit. Given an issue from any source — a Sentry alert, a Zendesk ticket, a GitHub issue, a pasted error, or a verbal "this thing is broken" — sherlock runs a disciplined investigation: gather evidence, check the boring explanations first, reproduce, form competing hypotheses, actively try to disprove them, follow the "but why?" chain to bedrock, and separate trigger from cause from contributing factors.

Sherlock is willing to conclude. When a hypothesis is verified by direct observation (reproduced, or mechanistically proven), sherlock says so and names the root cause — and then proposes a concrete fix with tradeoffs. When the evidence isn't there yet, sherlock stops at graded hypotheses rather than guessing. Either way, the deliverable is a report that lets any reader tell, for every claim, whether it was **observed**, **inferred**, or **hypothesized**.

## When sherlock runs

The user hands you any of:

- **A link or ID**: Sentry event, Honeybadger fault, GitHub issue, Linear ticket, Zendesk case
- **Pasted content**: a stack trace, a log excerpt, a support email
- **A verbal description**: "users in Germany are getting logged out after 30s"

Your first job is orientation. See `references/source-profiles.md` for what evidence each source type carries and how to extract it.

Ask before starting only if you're missing something load-bearing — most commonly: *which codebase/repo does this concern?* If the user is already in a repo and the evidence points there, assume that's the target.

## The investigator's mindset

Before mechanics, the mindset. These are the qualities that separate great investigators from average ones, and they cost nothing but discipline:

- **Suspicious of your own conclusions.** Assume your current theory is wrong until evidence forces you to accept it. When a finding contradicts the working theory, treat it as the most interesting signal in the investigation, not noise to explain away.
- **Follow the evidence, not the narrative.** Start from the observed fact and walk outward. Don't start from a theory and hunt for confirmation.
- **Notice what's missing.** A log line that *should* be there and isn't is as much a clue as one that shouldn't be there and is.
- **Read the actual thing.** Open the source file. Don't rely on what the function "probably does" based on its name. Don't recall from memory what a line looks like — go look.
- **Honest about uncertainty.** "I don't know yet" is a valid, valuable statement. Fill gaps with experiments, not plausible-sounding guesses.
- **Proportionate effort.** A typo doesn't need a timeline. A prod outage does. Match depth to stakes.

These aren't aphorisms to admire — they're the working posture throughout every phase below.

## The workflow

Work through the phases in order. Skipping a phase to save time usually costs more later. If a phase has nothing to produce, write "no relevant signals" in the report rather than omitting it.

### Phase 1 — Orient and ingest

Identify the source type (Sentry, Honeybadger, GitHub issue, Zendesk/CX, pasted content, verbal report). Pull everything the source carries. See `references/source-profiles.md` for source-specific extraction.

Common extractions:
- **Stack trace** → exact file:line of the top frame, exception class, message (verbatim)
- **Release / version / commit SHA** → the code that was actually running
- **Environment** → prod vs staging vs dev (they diverge in small, bug-causing ways)
- **First-seen / last-seen** → when the bug started (constrains the archaeology window)
- **Occurrence count / affected users** → scale, which informs priority and cohort analysis
- **Breadcrumbs / logs / user actions** → what led up to the failure

Use available MCPs where they help (Sentry MCP if present). Otherwise work from whatever the issue body, pasted content, or user description provides.

### Phase 2 — Establish the facts

Before theorizing, write down — in the report draft — exactly what you know:

1. **Symptom** — what observably went wrong, in one sentence.
2. **Error signal** — exception class, message, stack trace, quoted verbatim.
3. **Reproduction** — steps to reproduce, or "none provided".
4. **When** — first-seen timestamp or the user's "started around…".
5. **Scope** — environments, users, occurrences.
6. **Reporter's hypothesis** — noted, but treated as *one hypothesis among several*, never as fact.

The reporter's hypothesis is evidence about the reporter, not about the bug. They may be right — but only if the evidence supports it. Investigate it as a hypothesis, not a conclusion.

### Phase 3 — Check the boring explanations first

Before digging deep, spend 5–10 minutes on the mundane causes. Exotic theories are seductive; boring causes are statistically more likely. Run through:

- **Recent deploys, config changes, dependency bumps, infra migrations** — correlate with first-seen timestamp. `git log --since="<first-seen>"` is the starting move.
- **Clock skew, timezone, encoding, locale, DST** — especially for "only some users" bugs.
- **Caching** — stale cache, cache at the wrong layer, cache key collision.
- **Wrong environment** — is the user actually hitting prod? Is the config loaded? Is the feature flag on?
- **Retry amplification** — one real failure multiplied into a hundred alerts by a retry loop.
- **Stale build / outdated dependency** — is the running code actually the code you're reading?

If one of these ends the investigation, great — document it and move to Phase 8 (fix). If not, the time was cheap and you've ruled out a big class of causes.

### Phase 4 — Reproduce, isolate, bisect

Reproduction is the single most valuable thing you can get. A theory that can't be reproduced is a guess.

- **Minimal repro.** Strip the failing case until removing one more thing makes the bug disappear. A 10-line repro beats a 1000-line one every time.
- **Differential analysis.** If you can't reproduce the failure, find the difference between a *working* case and a *failing* one — different user, different environment, different input, different version. The diff is the clue.
- **Bisection.** If the bug is a regression, `git bisect` between a known-good and known-bad commit. Binary search inputs, dates, users, feature flags — anything with a range.

If reproduction is genuinely impractical (e.g., you're investigating a prod-only Sentry event on your local machine), say so explicitly and record what *would* reproduce it. The investigation continues — but every hypothesis stays unverified until reproduction happens.

### Phase 5 — Scope the code

From stack trace and symptom, build a list of **candidate files and modules**. For each, note *why* it's a candidate (top stack frame, implements the feature, owns the data structure, recently changed).

Also identify:
- **Entry point** — route, controller, background job, CLI command, webhook, cron, event handler
- **Likely execution path** — rough sketch from entry to where the symptom manifests
- **Boundary crossings** — serialization, network, process, thread, transaction. Bugs love boundaries because that's where assumptions get renegotiated.
- **External dependencies** — DB, cache, third-party API, queue, feature flag

If this list is empty, the evidence isn't specific enough yet. Go back to Phase 1 and note what's missing.

### Phase 6 — Git archaeology

Run git commands *before* opening files in your editor — come to the code with questions already formed.

The essentials, scoped to candidate files:

```bash
# Recent changes — anything touched recently is suspect
git log --since="<first-seen-window>" --oneline -- <candidate-files>

# Pickaxe — when did this exact string appear or disappear
git log -S "<error-message>" --oneline --all
git log -S "<function-name>" -p -- <candidate-file>

# Line-range history — follow a function through history including renames
git log -L :<functionName>:<path/to/file>

# Blame with move and whitespace tracking
git blame -w -C -C -C <path/to/file>

# Bug-fix hotspots in the scope
git log -i -E --grep='fix|bug|broken|regression' --oneline -- <candidate-files>

# Firefighting signals — reverts, hotfixes
git log --oneline -i -E --grep='revert|hotfix|emergency|rollback' -- <candidate-files>
```

Commit messages are hints, not evidence — read the diff, not just the subject line.

For the full toolkit (line-range history, merge-commit inspection, repo-health commands, interpretation notes), see `references/git-archaeology.md`.

### Phase 7 — Read code and correlate

Now open files — with questions, not free-form browsing. For each candidate file, know before opening: *what am I looking for here?*

Trace the execution path from entry point through the stack trace. At each hop:
- What is this function responsible for?
- What inputs does it trust vs. validate?
- What could make it fail in the way the symptom describes?
- Anything surprising — dead code, commented-out guards, stale comments, silent `rescue`/`except`?

**Correlate in parallel:**
- **By time** — overlay the incident timeline with deploys, config changes, cron jobs, cert expirations, DST boundaries. "What else happened at 03:47 UTC?" solves bugs.
- **By cohort** — group affected cases by any attribute: user, region, device, tenant, shard, build, feature-flag state. Look for what the affected share that the unaffected don't.
- **By pattern** — hash collisions, power-of-2 boundaries, integer overflow thresholds, Unicode edge cases, counts that match pool/batch/thread sizes.

For more on these (and other techniques like tracing, flame graphs, time-travel debugging, invariant auditing), see `references/techniques.md`.

### Phase 8 — Form competing hypotheses and falsify

List at least 2–3 plausible root causes, even when one feels obvious. The goal is *comparison*, not confirmation. For each hypothesis, record:

- **Statement** — one sentence describing the causal claim
- **Mechanism** — how it would produce the observed symptom
- **Evidence for** — specific observations (stack frame at X, commit Y changed Z, log W)
- **Evidence against** — specific observations that don't fit
- **Status** — one of:
  - **Verified** — reproduced, or mechanism proven by direct observation
  - **Unverified** — consistent with evidence but not proven
  - **Ruled out** — contradicted by direct observation
  - **Needs investigator input** — requires info outside the codebase (prod data, user action, third-party behavior)
- **How to verify** — the cheapest experiment that would confirm *or falsify*

Then — and this is the step most investigators skip — **actively try to disprove** your leading hypothesis. Ask: "What would I expect to see if this were true? Do I see it?" and equally "What would I expect to see if this were false? Can I find it?" The disproving mindset is the main defense against confirmation bias.

### Phase 9 — "But why?" to bedrock, and separate trigger from cause

For each non-ruled-out hypothesis, keep asking "but why?" one more time than feels necessary. Example:

> 500 error → because the DB call raised → because a column was null → because a migration that backfills it never ran in this environment → because the migration was gated on a feature flag that's off here.

Stop when the next "why" lands on something immutable (physics, protocol spec, external system contract) or on a human decision someone made.

Then name three things separately:

- **Trigger** — what fired the bug *this time* (the specific input, the specific timing)
- **Cause** — what made the bug *fireable* (the code path that mishandles that input)
- **Contributing factors** — what let it reach production (missing test, missed review, absent monitoring, unclear ownership)

A fix that only addresses the trigger leaves the gun loaded. A good report names all three.

### Phase 10 — Verify

If a leading hypothesis is verifiable cheaply, run the verification. This is where the investigation earns the word "solved":

- Reproduce the bug with the minimal repro.
- Run the code in a debugger and watch the failing state.
- Add a temporary log line that would only fire if the hypothesis is true, and confirm it fires.
- Revert the suspected commit in a branch and confirm the bug goes away.

When verification succeeds, upgrade the hypothesis to **Verified** and call it the root cause. When it fails, the hypothesis is **Ruled out** and you have new evidence for the remaining ones.

"Verified" is a high bar. If you haven't literally run code or observed the failure mechanism, the hypothesis is not verified — it's a strong hypothesis. Err toward honesty: unverified is fine, fake-verified is not.

### Phase 11 — Decide: conclude, or stop at hypotheses

Two honest endings:

**Mystery solved.** A hypothesis is verified. The report names the root cause, the trigger, and the contributing factors, and **proposes a concrete fix** (see next section).

**Mystery narrowed.** No hypothesis is verified yet, but some are ruled out and others are graded. The report presents the remaining hypotheses, explains what would verify each, and recommends the cheapest next step (often: reproduce in a specific way, or ask the user a specific question).

Do not fake certainty to land at "solved". A well-narrowed mystery is more valuable than a falsely-resolved one.

### Phase 12 — Propose the fix (only when verified)

When the root cause is verified, propose a fix. Otherwise skip this section.

A good fix proposal:

- **Addresses the cause, not just the trigger.** If the trigger is "user submitted empty string" and the cause is "code path doesn't validate input", the fix is the validation, not an input sanitizer on one caller.
- **Names the remediation shape before the code.** "Revert commit X", "add a null check at Y:123", "backfill the missing column in a migration gated on feature flag F". The shape is often more important than the exact diff.
- **Acknowledges tradeoffs.** Revert vs. forward-fix. Narrow patch vs. broader refactor. Defensive check vs. fixing the producer. Name the choice you're recommending and why.
- **Addresses contributing factors separately.** A missing test or absent monitoring often deserves its own task — note it but don't bundle it into the primary fix unless the user wants that.
- **Flags risk.** Is this fix cheap and safe, or does it touch a hot path? Will it need a backfill? Does it need a feature flag?

Do not write the patch unless asked — propose the shape and let the user decide whether to proceed to implementation. This is deliberate: it keeps the investigation cleanly separated from the fix decision.

### Phase 13 — Write the report

Use the template in `references/report-template.md`. Save to `investigation-report.md` in the current working directory (or a path the user specifies). Do not post it anywhere — the user decides where it goes.

The report is the deliverable. Its single most important job: for every claim, the reader can tell whether you *saw it*, *inferred it*, or *suspect it*. Use the status labels (Verified / Unverified / Ruled out / Needs investigator input) exactly as defined.

## Failure modes to watch for

These are the specific ways investigations go wrong. Every one of them has cost somebody a week.

- **Anchoring on the reporter's hypothesis.** If the ticket says "I think it's the cache", you'll be tempted to only investigate the cache. List it as *one of several*.
- **Stopping at first-plausible.** A hypothesis that fits the top frame of the stack trace is the *start* of "but why?", not the end.
- **Confirmation bias in code reading.** You'll pattern-match code that supports your current theory. Deliberately look for code that *contradicts* it.
- **Inferring dynamic behavior from static code.** "This branch is never taken" — are you sure? What logs or tests would confirm that? If you can't confirm, it's an unverified hypothesis, not a fact.
- **Treating high churn as guilt.** A churn-heavy file is a signal, not a verdict. Read the commits, don't just cite the count.
- **Shotgun debugging.** Changing many things at once and hoping one works produces superstition, not understanding. Change one thing at a time.
- **Tunneling on a wrong theory.** If three hypotheses in a row die, the *framing* is probably wrong — step back and re-read the original symptom before going deeper.
- **Skipping the boring check.** Nine times out of ten, the "impossible" thing is very possible and your map was wrong. Check that the code is actually running, the config is loaded, the flag is on.
- **Verifying by wishful thinking.** "Seems to match" is not verification. Reproduction, debugger observation, or a targeted log line is verification.
- **Bundling fix into investigation.** Proposing a fix *before* the root cause is verified biases hypothesis selection toward fixable-looking causes. Verify first, propose second.

## Reference files

- `references/source-profiles.md` — evidence shapes and extraction tips for Sentry, Honeybadger, GitHub issues, Zendesk/CX tickets, and raw inputs
- `references/techniques.md` — broader investigator toolkit (minimal repro, bisection, differential, tracing, flame graphs, time-travel debugging, invariant auditing, rubber duck, timeboxing)
- `references/git-archaeology.md` — full git command reference for investigation
- `references/report-template.md` — the exact report structure to use

Read a reference file when you need it. You don't need to read them all upfront.
