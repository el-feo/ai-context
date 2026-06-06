# Investigator Techniques

A toolkit — not a checklist. Great investigators have a toolkit and match the technique to the shape of the bug. Reach for what fits the evidence you have; ignore what doesn't. The phases in SKILL.md tell you *when* to use these; this file tells you *how*.

## Table of contents

1. [Reproduction and isolation](#reproduction-and-isolation)
2. [Bisection](#bisection)
3. [Differential analysis](#differential-analysis)
4. [Correlation](#correlation)
5. [Observation (logs, tracing, debugger)](#observation)
6. [System-level inspection](#system-level-inspection)
7. [Hypothesis discipline](#hypothesis-discipline)
8. [Meta-techniques](#meta-techniques)

---

## Reproduction and isolation

### Minimal reproduction

Strip the failing case until removing one more thing makes the bug disappear. Every variable you remove without breaking the repro is a hypothesis you don't have to investigate.

- A 10-line repro beats a 1000-line one every time.
- Start from the full failing case; halve it repeatedly.
- Each removed input or line that *didn't* change the outcome is a dead end ruled out.

### Isolation

Separate the bug from its environment. Does it reproduce:

- Locally vs only in prod?
- With this user's data vs a clean account?
- On this branch vs main?
- On this machine vs a colleague's?

Each isolation dimension that the bug *doesn't* survive tells you where it lives.

---

## Bisection

Binary search turns an O(n) hunt into O(log n). Use it whenever you have a range.

### Git bisect

When a bug is a regression — it worked, now it doesn't — bisect the commit range.

```bash
git bisect start
git bisect bad <known-bad-commit>      # often HEAD
git bisect good <known-good-commit>    # last known-working
# For each checkout, reproduce manually or run:
git bisect good   # or: git bisect bad
git bisect reset  # when done
```

With a scriptable reproducer, `git bisect run <script>` automates the whole thing: exit 0 for good, non-zero for bad, 125 to skip.

Writing the reproducer is usually the hard part. If reproduction is expensive, bisect manually on a coarser grid (every 10th commit, every merge to main) and narrow from there.

### Non-git bisection

The same technique applies to any range:

- **Inputs** — halve the input file, the request body, the dataset
- **Config** — flip flags in a binary search over configuration space
- **Users / tenants** — if only some are affected, split the cohort
- **Time** — if it started "sometime last week", binary-search across hours of logs
- **Releases** — for versioned artifacts, bisect by version

---

## Differential analysis

When you have both a failing case and a working case, **the diff is the clue**. "What's different?" is often a faster question than "What's wrong?".

Axes to compare:

- **Environment** — staging vs prod. Diff the config, the data, the versions.
- **User** — affected vs unaffected. What do affected users share that unaffected ones don't?
- **Time** — before vs after. What changed at the boundary?
- **Version** — v1.2 vs v1.3. `git diff v1.2..v1.3 -- <candidate-files>`
- **Request** — a failing request vs a similar-looking passing one. Diff headers, body, user context.

If the cohort of affected users is 100% or 0% along some dimension (region, device, plan tier), that dimension is almost always load-bearing.

---

## Correlation

### Correlation by time

Overlay the incident timeline with everything else that happened around the same time:

- Deploys
- Config / feature-flag changes
- Dependency bumps / infra migrations
- Cron jobs
- Scheduled tasks / batch jobs
- Certificate expirations
- DST transitions / timezone boundaries
- Traffic spikes / load shifts

"What else happened at 03:47 UTC?" has solved countless mysteries. Check dashboards side-by-side at the same time range.

### Correlation by cohort

Group failing cases by any attribute:

- User, account, tenant
- Region, IP range, CDN PoP
- Device, browser, OS version
- App version, build, deploy region
- Feature flag state
- Plan tier, role
- Data shape (row count, payload size)

A cohort that's 100% affected or 0% affected is a strong signal. A roughly even split often means timing or load.

### Correlation by pattern

Some bugs have numeric fingerprints:

- **Hash collisions** — if affected IDs share a modulo, suspect routing or sharding
- **Power-of-2 boundaries** — 256, 512, 1024, 65536, ... → integer limits, buffer sizes
- **Integer overflow thresholds** — 2^31 - 1, 2^63 - 1
- **Unicode edge cases** — emoji, surrogate pairs, RTL text, combining characters, BOM
- **Pool / batch / thread size matches** — failure count matching connection pool size, thread count, or batch size tells you the scaling axis
- **Periodicity** — every 60s, every 1000 requests, every hour — points at scheduled work, caching intervals, or token refresh

---

## Observation

### Strategic logging

Logs work when they're placed at decision points, not entry/exit alone. Good logs record:

- Which branch was taken (and why — the values that drove the decision)
- What the code thinks it's about to do, right before doing it
- What it actually observed from dependencies (DB row count, API status code, cache hit/miss)

Remove noisy logs before adding new ones — signal dies in noise.

### Tracing

- **Distributed tracing** (OpenTelemetry, Datadog, Jaeger) — for request-path bugs. A span missing from a trace *is* the finding.
- **strace / dtrace** — syscall-level, for "what is this process actually doing?"
- **tcpdump / Wireshark** — network level, for "client or server?" bugs

Sampling traces lie about rare events — use head-based or tail-based sampling deliberately.

### Debugger

Prefer a debugger to print statements when the state you care about is structured.

- Set a breakpoint where you expect the state to diverge from expectation; walk up the stack.
- **Conditional breakpoints** for intermittent bugs (`when i == 4732`, `when user_id == "abc"`).
- **Post-mortem** on core dumps when you can't reproduce live.

### Time-travel debugging

Tools like `rr` (Linux), Pernosco, UndoDB: record once, replay deterministically, step backward from the failure. Invaluable for Heisenbugs and state-corruption bugs. Underused because it requires setup; pays for itself on the first hard bug.

---

## System-level inspection

For bugs that aren't obviously in app code:

### Process and resource inspection

- `ps`, `top`, `htop`, `iostat`, `vmstat` — what's running, using what
- `netstat` / `ss` — open sockets, listening ports, connection states
- `/proc/<pid>/` on Linux — fds, memory maps, status, limits
- `lsof` — what a process has open when it's stuck

### Stack dumps and flame graphs

- **Thread dumps** for deadlocks and stuck threads — take three, 10 seconds apart, compare
- **CPU flame graphs** (`perf`, `async-profiler`, `py-spy`) for "why is this slow?"
- **Off-CPU flame graphs** for "why is this *waiting*?" — often the more important question

### Network-layer inspection

- `curl -v` — see headers, redirects, TLS handshake
- `openssl s_client -connect host:443` — TLS issues, cert expiration
- `dig +trace` — DNS resolution path
- `mtr` — combined traceroute + ping
- Packet capture when "is it the client or the server?" matters

---

## Hypothesis discipline

### The disproving mindset

For every hypothesis, design the cheapest experiment that would **falsify** it. If you can't design a falsifying test, the hypothesis isn't specific enough.

Confirmation bias is the investigator's main enemy. Hunt for your theory's counterexample *first*. If you can't find one despite trying, your confidence in the theory goes up honestly.

### One change at a time

When multiple fixes land together and it works, you don't know which one fixed it. Discipline:

- Revert to baseline
- Apply one change
- Test
- If still broken, revert and try the next
- Only combine changes after each is individually understood

Shotgun debugging produces superstition, not understanding.

### Invariant auditing

List what *must* be true for the system to behave correctly:

- Ordering invariants ("X always happens before Y")
- Uniqueness invariants ("there is exactly one of Z per user")
- Bounds invariants ("N stays between 0 and 1000")
- Reachability ("every state can reach terminal")

Check each invariant against the failing state. The violated one is the bug's fingerprint. Property-based testing (Hypothesis, QuickCheck, fast-check) encodes this formally — generate inputs, assert invariants, let the tool find the counterexample.

---

## Meta-techniques

### Check the boring explanations first

Exotic theories are seductive; mundane causes are statistically more likely. Before anything exotic, check:

- Clock skew, timezone, DST
- Caching at any layer
- Stale build, outdated dependency, wrong environment
- Retry amplification
- Off-by-one
- Encoding (UTF-8, latin-1, BOM)
- Feature flag state

Only escalate to "compiler bug" or "kernel issue" after eliminating everything above.

### Ask "but why?" one more time than feels necessary

Each answer is a new question. Stop only when the next "why" lands on something immutable (physics, protocol spec, external system contract) or a human decision. "A caused B" is rarely the root — "the system allowed A to cause B" usually is.

Separate:

- **Trigger** — what fired it this time
- **Cause** — what made it fireable
- **Contributing factors** — what let it reach production

A fix that only addresses the trigger leaves the gun loaded.

### Rubber duck / explain it

State the problem out loud, or in writing, as if teaching it. The gap in your explanation is usually the gap in your understanding. Writing a clear bug report frequently produces the answer before you hit send. Works because it forces sequential articulation of things the brain was holding as a fuzzy cloud.

### Timeboxing

Commit to investigating theory X for N minutes. If no progress, force a step back. Prevents sunk-cost tunneling on a wrong theory. The step back — re-reading the original symptom — is where many investigations restart correctly.

### The "impossible" check

When something "can't" be happening, verify the assumptions you haven't questioned:

- Is the code you're reading actually running?
- Is the config loaded in this environment?
- Is the feature flag on for this user?
- Is the deploy actually the version you think?

Nine times out of ten, the "impossible" thing is very possible and your map was wrong.

### Know when to stop digging the current hole

If three hypotheses in a row die, the **framing** is probably wrong. Step back before going deeper. Re-read the original symptom. Explain the problem fresh to someone (human or rubber duck).

Fresh eyes beat another hour alone.

### Write it down as you go

Keep a running log of hypotheses, evidence, and what's been ruled out. Future-you (two hours from now) will thank present-you. Investigators who don't write lose track and re-test things. The act of writing often surfaces the flaw in the current theory before anyone else has to read it.
