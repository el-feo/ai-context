# AUDIT Mode — Surveying a Whole Codebase's OO Health

The user wants a read on the design health of an **entire codebase** (or a large subsystem), not
feedback on one class or diff. Your job: survey the system, find where the design debt actually
lives, and rank it by **changeability leverage** — so the user knows which single fix buys the most
future flexibility, and where to start.

AUDIT is REVIEW at the scale of a system. REVIEW goes deep on one artifact, in conversation. AUDIT
triages across many: *where is this codebase hard to change, and why?* The two compose — once an
audit surfaces a hotspot, drop into REVIEW (`references/review.md`) to go deep on it, and into
REFACTOR (`references/refactoring.md`) to fix it.

## Stance

The same respect that governs REVIEW governs AUDIT, just at scale. The people who built this made
choices for reasons, often under deadline. **Lead with what's structurally healthy** — it tells the
team what to protect. Then **rank, don't dump**: a flat list of every smell in a large codebase is
noise. Isolate the few hotspots where bad design is also load-bearing, because those are the only
ones worth touching first. Every finding names a principle and a *changeability cost*, never a bare
verdict.

## Procedure

### 1. Get the lay of the land
Before judging, build a quick mental map: the top-level structure, the core domain objects, the
entry points, and the boundaries (framework, ORM, external services). State the system's shape back
in a sentence or two. You're auditing whether the *design* is easy to change, not whether it's
"correct."

### 2. Sweep for the high-leverage smells
You can't read everything, so hunt where design debt clusters. Practical sweep:
- **God classes / SRP violations** — the largest, most-central classes. Use the Sandi 100-line
  provocation as a *prompt to look closer*, not a verdict. A class many things depend on that also
  does many things is the classic high-leverage target.
- **Type/kind conditionals repeated across files** — `case`/`switch`/`if` chains switching on a
  type, kind, or status, especially the *same* switch appearing in several places. These are duck
  types / polymorphism wishing they existed.
- **Message chains across boundaries** — `a.b.c.d` reaching through object graphs (Law of Demeter),
  and modules that reach deep into each other's internals (Inappropriate Intimacy).
- **Feature Envy, Primitive Obsession, Data Clumps** — methods more interested in another object's
  data than their own; bare strings/hashes/ints standing in for concepts that deserve an object;
  the same cluster of parameters traveling together everywhere.
- **Divergent Change / Shotgun Surgery** — if git churn is available, the files that change most
  often are your highest-leverage targets: either one file changes for many unrelated reasons
  (Divergent Change) or one change forces edits across many files (Shotgun Surgery). When churn
  isn't available, infer it from breadth of responsibility.
- **The wrong abstraction** — speculative interfaces, factories, and configuration layers with a
  single implementation or a single caller. Premature abstraction is design debt too: "prefer
  duplication over the wrong abstraction." An `AbstractThing` with one concrete subclass is a
  candidate to inline until a second variant actually exists.

### 3. Rank by leverage, not by severity alone
**Leverage = centrality × severity.** A messy script nothing depends on is low leverage; a moderately
messy class at the heart of the domain that everything routes through is high leverage. Rank so the
top of the list is "fix this and the whole system gets easier to change," not "this is the ugliest
code." A clean, well-isolated wart can be left alone.

## Output format

```
## Design health
[An honest, specific read on the system's overall OO shape, and what's working — the structural
choices that serve changeability and should be protected. This is calibration, not flattery.]

## Highest-leverage concerns
[The top 1–3, each given REVIEW-grade texture: named principle/smell, precise location
(`path/to/file.rb:42`), the changeability cost in concrete terms, and a direction framed as a
question. Note that fixing it is REFACTOR mode, not something to do inline here.]

## Ranked findings
[The rest, biggest-leverage first, one line each:]
- **[Smell / principle]** — `path/to/file:line` — [the one-line direction].
- ...

## Suggested sequence
[The order to tackle the hotspots: lowest-risk and highest-leverage first. Reminder to keep each
refactoring separate from feature work — make the change easy, then make the easy change.]
```

Close with the single most useful pointer, e.g. *Healthiest leverage point: extracting the pricing
rules out of `Order`. Start there.*

## When the codebase is healthy

If the design is genuinely sound, **say so plainly and stop.** Don't manufacture a ranked list to
look thorough. "This is well-factored for its size — responsibilities are clear, dependencies point
inward, and I don't see a type conditional or god class worth restructuring. Keep doing what you're
doing." A clean audit is a real outcome.

## Boundaries

AUDIT is about **design and changeability only.** Correctness bugs, security holes, and performance
are out of scope — route them to the reviewer built for them (e.g. the ruby-rails `review-ruby-code`
skill, a `/security-review`, a performance pass). Flagging a god class is in scope; flagging a SQL
injection is not.

AUDIT is **one-shot and lists findings — it does not apply fixes.** To actually change code, flow
into REFACTOR (`references/refactoring.md`); to go deep on a single hotspot, flow into REVIEW
(`references/review.md`). Keep the audit a survey the user can act on at their own pace.
