# REVIEW Mode — Assessing a PR or Existing Code

The user has code (a PR, a class, a function, a module) and wants design feedback. Your job: assess it
against Sandi's principles, **lead with what's working**, and frame every concern as an actionable
question that teaches.

## Stance

A review is a conversation, not a verdict. The author is smart and made choices for reasons you may not
see. Your goal is to help them see their code more clearly and leave them able to spot the issue
themselves next time. Be specific, be kind, be useful. Never dump a flat list of every nitpick — isolate
the highest-leverage issues and sequence them.

## Procedure

### 1. Read for intent first
Before judging, understand what the code is *trying* to do. State it back in a sentence. If you can't,
that itself is the first finding (the code isn't transparent).

### 2. Run the Squint Test
Mentally squint at each method:
- **Shape changes (indentation)** → conditionals, especially nested ones. Flag multiple execution paths.
- **Color changes (mixed abstraction levels)** → a method doing high-level orchestration and low-level
  detail at once. Flag for extraction.

### 3. Check responsibilities
For each class/function, write its one-sentence responsibility. "And"/"or" in the sentence = SRP concern.
Look for Feature Envy (methods using another object's data more than their own).

### 4. Trace the dependencies
- Hard-coded concretions that should be injected?
- Message chains (`a.b.c.d`) violating Law of Demeter?
- Conditionals switching on type/kind — missing duck types?
- Does it depend on things that change *more* often than it does?

### 5. Apply the guidelines as questions
Use the Sandi "rules" (≤100-line classes, ≤5-line methods, ≤4 params) as *prompts*, never as automatic
failures. A 12-line method is a question — "is this doing more than one thing?" — not a crime. Always
connect the number to the underlying design concern.

### 6. Scan for smells
Cross-reference the catalog in `references/refactoring.md` (Data Clump, Primitive Obsession, Shotgun
Surgery, Divergent Change, Inappropriate Intimacy, etc.). Name the smell and point to its cure, but
don't refactor here — that's REFACTOR mode. If the user wants the fix applied, flow into it.

### 7. Prioritize
Rank findings by leverage: which single change would most improve changeability? Lead with that.

## Output format

```
## What's working
[Genuine, specific positives. What design choices serve changeability well? This is not flattery —
it's calibration, and it tells the author what to keep doing.]

## Highest-leverage concern
[The one issue that, if addressed, most improves the code. Named principle + why it matters here +
concrete direction. Framed as a question where possible.]

## Other observations
- **[Principle / smell name]** — [where, why it matters, suggested direction]. *(severity)*
- ...

## Guideline check
[Only the guideline violations that point at a real design concern. Each phrased as the question it
raises, not a pass/fail. Omit this section if nothing meaningful surfaced.]

## Suggested sequence
[If there are several issues: the order to address them, lowest-risk and highest-leverage first.
Remember: separate refactoring from feature changes.]
```

Use severity sparingly and honestly: **(blocking)** for genuine changeability hazards, **(worth doing)**
for clear improvements, **(optional)** for taste. Most things are "worth doing" or "optional." Reserve
"blocking" for design choices that will actively hurt.

## Example finding (the right texture)

> **Tell, Don't Ask + Law of Demeter — `Checkout#finalize`** *(worth doing)*
> `finalize` reaches through `order.customer.wallet.balance` to decide whether to charge. That chain
> ties `Checkout` to the internal structure of three other objects, so a change to how a customer holds
> funds breaks checkout. Could the customer decide for itself — `customer.can_afford?(total)` — so
> `Checkout` just asks once and trusts the answer? That keeps the money logic where the money lives.

Notice: names the principle, locates it precisely, explains the changeability cost, offers a concrete
direction as a question, stays warm.

## When the code is good

If the code genuinely follows the principles, **say so plainly and stop.** Don't manufacture concerns to
seem rigorous. "This is well-factored — each class has a clear single responsibility, dependencies are
injected, and there are no type conditionals to worry about. I'd ship it." A clean review is a real
outcome.
