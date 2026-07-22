# Report Template

Save investigations as `investigation-report.md` in the current working directory (or a path the user specifies). Use this exact structure — the labeled sections are part of the contract. They set reader expectations about what kind of claim each section contains.

---

```markdown
# Investigation: <issue title or one-line symptom>

## Summary
Two or three sentences stating the known facts and the current state of the
investigation. If a root cause is verified, state it here explicitly. If not,
state the leading hypothesis *as a hypothesis*, not as "the cause".

## What was reported
- **Source**: <Sentry / Honeybadger / GitHub issue / Zendesk / pasted / verbal>
- **Symptom**: <one line>
- **Error signal**: <exception / stack trace / log, quoted verbatim in a code block>
- **Reproduction**: <steps, or "none provided">
- **First seen / scope**: <timestamp, environment, user/occurrence count if known>
- **Reporter's hypothesis**: <noted separately; one hypothesis among others>

## Boring-explanations check
Which mundane causes were considered and what was ruled out. Examples: recent
deploys, config changes, caching, clock/timezone/encoding, retry amplification,
feature-flag state. If one of these *was* the cause, say so here and proceed
directly to Root cause.

## Scope of investigation
Files, modules, and execution paths examined, each with a one-line *why it's in scope*.

## Reproduction
Steps that reliably reproduce the bug, or an explanation of why reproduction
was not attainable (and what would be needed to reproduce).

## Git archaeology findings
Recent changes, churn, blame observations, pickaxe results, prior bug-fix
commits, firefighting patterns. Quote commit SHAs. If a signal was looked for
and not found, say so — absence is information.

## Code-reading observations
Facts about the code, with file:line references. Keep this descriptive and
evidence-grounded. Flag anything that looked odd but wasn't conclusive.

## Correlation findings
Time-based, cohort-based, or pattern-based observations. "All affected users
are on v1.8.3", "incident started 12 minutes after deploy of X", "failure
count matches the connection pool size of 20".

## Hypotheses

### H1: <short name>
- **Status**: Verified | Unverified | Ruled out | Needs investigator input
- **Mechanism**: how this would produce the symptom
- **Evidence for**: …
- **Evidence against**: …
- **How to verify further**: concrete next step (omit if already Verified/Ruled out)

### H2: …
### H3: …

## Ruled out
Hypotheses that looked plausible but were contradicted by evidence, each with
the specific observation that ruled it out.

## Root cause
[Include this section ONLY if a hypothesis was verified by direct observation.
Otherwise omit.]

- **Cause**: what makes the bug fireable (the code path, the missing check,
  the mishandled case)
- **Trigger**: what fired it *this time* (the specific input, timing, user action)
- **Contributing factors**: what let it reach production (missing test,
  missed review, absent monitoring, unclear ownership)
- **Verification**: how this was confirmed — the reproduction, the debugger
  observation, the targeted log line, the reverted commit

## Proposed fix
[Include this section ONLY if Root cause is verified. Otherwise omit.]

- **Shape**: the remediation in one or two sentences before any code
  ("revert commit X", "add null check at Y:123 and backfill missing data")
- **Tradeoffs**: revert vs forward-fix, narrow patch vs broader refactor,
  defensive check vs fixing the producer — name the choice and why
- **Risk**: is this cheap and safe, or does it touch a hot path? Will it
  need a backfill, feature flag, coordinated deploy?
- **Separate follow-ups**: contributing factors that deserve their own tasks
  (a missing test, an absent alert), listed but not bundled in

## Open questions for the investigator
Specific things that could not be answered from code + git + available logs
alone. Phrased as questions, not tasks.

## Evidence quality note
Explicitly call out which claims in this report are direct observation vs.
inference vs. hypothesis. Flag anything the next reader should *not* treat as
established.

## Not included
- <If Root cause is not verified: "No fix is proposed — see graded hypotheses above.">
- <If Root cause is verified: "Patch not written — fix shape proposed, implementation is a separate task.">
- <Any areas intentionally not explored, and why.>
```

---

## Writing guidelines

- **Verbatim quoting.** Error messages, log lines, and SQL queries go in fenced code blocks, quoted exactly. Do not paraphrase error messages — the exact wording is often the searchable key.
- **Concrete references.** Every code claim gets a `path/to/file.ext:123` reference. Every historical claim gets a commit SHA.
- **Status labels are sacred.** Do not use "probably", "likely", "seems to be" as a substitute for a status label. If a claim is causal, it gets Verified / Unverified / Ruled out / Needs investigator input — full stop.
- **Absence is information.** If you checked for something and didn't find it, write "no firefighting commits in the last year" or "no related Sentry events for this user". A silent omission reads as "not checked".
- **Two endings only.** Either a verified root cause (with a fix proposal) or a set of graded hypotheses (without). Do not smuggle a half-confident conclusion in between.
