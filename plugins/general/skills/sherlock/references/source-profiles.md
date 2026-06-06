# Source Profiles — What Evidence Each Input Carries

Issue reports arrive from many sources, and each source has a different *evidence profile* — what it reliably gives you and what you have to extract, translate, or go ask for. Name the profile before you start investigating; it tells you what you already have and what you're missing.

---

## Sentry

**Evidence profile**: exception-oriented, technical, often high-signal.

**Reliably provided**:

- Exception class, exception message
- Stack trace with file:line (may be minified for frontend — check for source maps)
- Release / version (the deployed artifact that threw)
- Environment (production / staging / etc.)
- Runtime / SDK info, user agent, OS
- First-seen, last-seen timestamps
- Event count, affected user count
- Breadcrumbs — the sequence of events leading up to the exception (clicks, navigations, log lines, HTTP calls)
- Tags (custom — varies by project)

**Extraction tips**:

- The **top frame** of the stack trace is usually the file to read first, but not always the cause. The cause is often a few frames deeper in the app code.
- **Breadcrumbs** are the closest thing to a free reproduction: the sequence of user actions and side effects right before the crash.
- **Release** is crucial — it tells you which commit was actually running. `git log <release>` for the real code.
- **Occurrence rate over time** distinguishes a spike (new regression) from a chronic issue (long-standing bug).

**Common pitfalls**:

- Minified JS stack traces are useless without source maps. Check whether source maps are uploaded.
- "Affected users: 1, Events: 5000" usually means one user in a retry loop — don't treat event count as severity.
- First-seen is when Sentry first saw it, which may be after the bug was introduced. Correlate with deploys.

**If a Sentry MCP is available**, use it to pull full event details, breadcrumbs, and related events.

---

## Honeybadger

**Evidence profile**: similar to Sentry — exception-oriented.

**Reliably provided**:

- Exception class + message
- Stack trace
- Request context (URL, method, params, headers — often richer than Sentry for Rails apps)
- Environment
- First-seen, occurrence count
- User/session context if the app instruments it
- Similar-faults grouping

**Extraction tips**:

- Honeybadger's **request params** are often the missing piece — they give you the exact input that triggered the error. Check for sensitive-data filtering, though.
- **Similar faults** — Honeybadger groups by fingerprint. Check whether this is one of a cluster or a singleton.

---

## GitHub Issue

**Evidence profile**: highly variable — depends entirely on the reporter.

**Reliably provided**:

- Title, body, labels
- Comments (often where the real discussion lives)
- Linked PRs, commits, other issues
- Author, reactions, assignees

**Extraction tips**:

- Use `gh issue view <num> --comments` to get everything in one pull.
- **Linked PRs closing the issue** — if the issue is closed, the linking PR is ground truth for the fix. Don't read it first (it biases your hypotheses), but do check your conclusions against it at the end.
- **"Same as #123" / "Duplicate of"** — related issues may have richer evidence than the one in front of you.
- Developer-authored issues often contain a hypothesis already. Note it as **one** hypothesis, not as fact.

**Common pitfalls**:

- Issue bodies often contain a *translation* of the real error (paraphrase, partial screenshot) rather than the verbatim error. Push back if the stack trace or exact message is missing.
- "It started happening around Tuesday" usually means *noticed* on Tuesday. Cross-reference with error-tracker first-seen.

---

## Zendesk / CX ticket / Support email

**Evidence profile**: user-facing, low-signal for code, high-signal for symptom.

**Reliably provided**:

- User-facing symptom in natural language ("can't upload", "got a weird email")
- Partial reproduction steps (maybe)
- Screenshots (maybe)
- User metadata (account, plan, region)
- Back-and-forth with support agent (sometimes hides clarifying details in later messages)

**Usually missing**:

- Stack trace
- Exact timestamps precise enough to correlate with deploys
- Precise reproduction steps
- Server-side logs

**Extraction tips**:

- **Translate the symptom into a code region.** "Can't upload" → what upload flow? File type? Size? Endpoint? This is the investigator's main job for CX-sourced issues: go from user-language to a candidate file list.
- **Ask for the missing evidence** before going deep. Often a 5-minute ask to the CX team for "exact timestamp, exact error message they saw, which button they clicked" saves hours.
- **Cross-reference** with Sentry/Honeybadger by user ID and time window — a CX report without an error-tracker hit means either silent failure (important!) or the error was caught and handled incorrectly.
- **Screenshots** sometimes show URLs, request IDs, or console errors — zoom in.
- Re-read the *full* ticket thread. The useful detail is often in message #4, not the initial report.

**Common pitfalls**:

- Users report workarounds as symptoms. "I have to refresh three times" — the bug is whatever makes the first two attempts fail, not the refresh.
- Users conflate effects. "The dashboard is broken" might mean: a chart renders empty, a filter doesn't apply, a tooltip is garbled. Pin down *which* observable thing is wrong.

---

## Pasted content (stack trace, log excerpt, email thread)

**Evidence profile**: whatever the user decided to paste — often incomplete.

**Extraction tips**:

- Ask: *is this the whole thing, or an excerpt?* Excerpts often omit the line that would have told you the answer.
- Look for **release/version/environment markers** — log prefixes, build IDs, host names.
- Look for **timestamps** — multi-line logs often have them; they let you correlate with deploys.
- If you see a **stack trace**, treat it like a Sentry stack trace (top frame → candidate file, etc.).
- If you see **request IDs or trace IDs**, note them — the user may be able to pull the full trace from their observability tool.

---

## Verbal / prompt-only ("users in Germany get logged out after 30s")

**Evidence profile**: pure symptom description, no artifacts.

**Extraction tips**:

- Translate into hypothesis-generating questions: *only Germany* → geo/locale/CDN/region split. *After 30s* → timeout at some layer (LB, app, DB, session). *Logged out* → session invalidation (which code path?).
- **Ask early.** "Do you have a Sentry link, a timestamp, a user who reproduced it, an exact error they saw?" A 2-minute ask beats an hour of speculation.
- **Name what's missing explicitly** in the report. "No error signal available" is itself a finding — it either means it's being caught silently or it's a non-exception failure (wrong data, wrong UI state, etc.).

---

## Cross-source patterns

Some patterns hold across all sources:

- **Two reports, same root cause, different surfaces.** A Sentry spike at 14:00 and a CX ticket at 14:05 mentioning the same user flow are almost certainly the same incident. Check.
- **Missing evidence is evidence.** A CX ticket with no matching Sentry hit means either silent failure or the error is in a path that isn't instrumented. Both are worth flagging.
- **Reporter's hypothesis ≠ root cause.** The reporter may be right. They're more often not, even when they're technical. Treat any hypothesis as one to verify, not one to confirm.
