# Simplifying Conditional Logic

Conditionals carry much of a program's power and most of its accidental complexity. The refactorings in this group attack that complexity from two directions: some clarify intent within the conditional structure itself (extract intention-revealing functions, combine checks, flatten nesting into guard clauses), while others remove the conditional entirely by moving variation into objects (polymorphism, special-case objects). One more — assertions — doesn't remove a conditional but documents the state the code assumes, turning implicit expectations into explicit, checkable statements.

## Table of contents

- [Decompose Conditional](#decompose-conditional)
- [Consolidate Conditional Expression](#consolidate-conditional-expression)
- [Replace Nested Conditional with Guard Clauses](#replace-nested-conditional-with-guard-clauses)
- [Replace Conditional with Polymorphism](#replace-conditional-with-polymorphism)
- [Introduce Special Case](#introduce-special-case)
- [Introduce Assertion](#introduce-assertion)
- [Replace Control Flag with Break](#replace-control-flag-with-break)

## Decompose Conditional

```js
// before
if (hours > contract.baseHours && employee.grade < 5)
  pay = hours * contract.rate * 1.5;
else
  pay = hours * contract.rate;

// after
pay = qualifiesForOvertime() ? overtimePay() : basePay();
```

**Use when:** A conditional's test and branches say *what* the code does but bury *why* it branches. Long condition expressions and multi-line legs are the trigger — name the condition and each leg after its intent so the branching logic reads as a sentence. This is really Extract Function applied specifically to a conditional, and it pays off unusually well there. Skip it when the condition and legs are already single, self-explanatory expressions.

**Mechanics:**

1. Apply Extract Function to the condition expression, naming it for what it decides.
2. Apply Extract Function to the then-leg, then the else-leg, naming each for its intent.
3. Once each piece is a named call, consider collapsing the whole thing to a ternary (or your language's expression form) for a one-line read.

## Consolidate Conditional Expression

```js
// before
if (order.total < 10) return 0;
if (order.destination === "local") return 0;

// after
if (qualifiesForFreeDelivery()) return 0;
```

**Use when:** Several different checks all produce the same outcome. Combining them with `and`/`or` shows the reader there is really one decision, not a coincidental pile of checks — and the combined expression is then a prime candidate for Extract Function, which converts *what* is checked into *why*. Do NOT consolidate checks that are genuinely independent decisions that merely happen to share a result; forcing them together obscures intent instead of revealing it.

**Mechanics:**

1. Verify none of the conditions has side effects; if any do, apply Separate Query from Modifier first.
2. Combine two of the conditions with a logical operator — sequential checks join with `or`, nested `if`s join with `and`. Test.
3. Repeat until a single condition remains.
4. Consider Extract Function on the combined condition to give it an intention-revealing name.

**Pitfalls:**

- Mixed `and`/`or` combinations get hard to read fast — extract named functions liberally as you fold them together.

## Replace Nested Conditional with Guard Clauses

```js
// before
function fee(member) {
  let result;
  if (member.suspended) result = 0;
  else {
    if (member.trial) result = 0;
    else result = baseFee(member);
  }
  return result;
}

// after
function fee(member) {
  if (member.suspended) return 0;
  if (member.trial) return 0;
  return baseFee(member);
}
```

**Use when:** One branch is the function's real work and the others are unusual pre-checks. An if/else gives both legs equal billing; a guard clause says "this case isn't the point — handle it and get out," letting the main logic sit unindented at the top level. Don't apply it when both legs genuinely are normal, equally weighted behavior — a plain if/else communicates that better. Ignore any "single exit point" rule; clarity is the only criterion for how many returns a function has.

**Mechanics:**

1. Take the outermost condition that should be a guard and convert it to a check-and-return (reversing the condition if the unusual case is the else-leg). Test.
2. Repeat for each remaining nested condition.
3. If the guards all return the same value, apply Consolidate Conditional Expression.
4. If a mutable result variable is left doing nothing useful, remove it.

**Pitfalls:**

- When reversing a compound condition, do it in two steps — wrap it in a `not` first, test, then simplify with De Morgan's laws — a hand-flipped compound condition is an easy place to introduce a bug.

## Replace Conditional with Polymorphism

```js
// before
function fee(account) {
  switch (account.kind) {
    case "savings":  return 0;
    case "checking": return account.overdrawn ? 15 : 5;
  }
}

// after
class Savings  { get fee() { return 0; } }
class Checking { get fee() { return this.overdrawn ? 15 : 5; } }
```

**Use when:** Several functions each switch on the same type code — classes per type remove that duplicated dispatch — or when logic is a base case plus variants, where a superclass holds the plain logic and each subclass expresses only its differences. Don't reach for it reflexively: most conditional logic is fine as plain if/else or switch, and polymorphism only earns its structural cost when the conditional is complex or the dispatch is repeated.

**Mechanics:**

1. If polymorphic classes don't exist, create them plus a factory function that returns the right instance for each case.
2. Route calling code through the factory.
3. Move the conditional-bearing function onto the superclass (Extract Function first if it isn't self-contained).
4. Pick one subclass; override the method there with that leg's logic. Optionally make the superclass leg throw so a missed call site fails loudly. Test.
5. Repeat for each remaining leg.
6. Leave the default case in the superclass method — or, if no default makes sense, declare it abstract or have it throw.

**Pitfalls:**

- For the base-and-variants shape, prefer subclass overrides expressed as deltas (e.g. call the super method and adjust) over copying the whole method down.
- Language adaptation: dynamic languages need no shared superclass — duck typing suffices (keep one anyway if it documents the domain). In Ruby/Elixir/Rust, pattern matching or case-specific modules can be a lighter-weight alternative when the dispatch appears only once; polymorphism wins when the same switch recurs across several functions.

## Introduce Special Case

*Formerly: Introduce Null Object*

```js
// before (repeated at many call sites)
const label = (post.author === null) ? "guest" : post.author.displayName;

// after
class MissingAuthor { get displayName() { return "guest"; } }
const label = post.author.displayName;
```

**Use when:** Many call sites check for the same special value (null, "unknown", a sentinel) and most react to it identically. Move that shared reaction into one special-case object so the checks collapse into plain calls. Null Object is just this pattern applied to null. If callers each do something *different* with the special value, there's little shared behavior to centralize — keep the checks (or expose an `isSpecial` probe for the outliers).

**Mechanics:**

1. Add a special-case check property (e.g. `isMissing`) to the normal class, returning false.
2. Create the special-case object with that property returning true.
3. Apply Extract Function to the comparison-with-sentinel code and point every client at it, so the definition of "special" lives in one place.
4. Make the container return the special-case object where the sentinel used to appear (via its accessor or a transform step over the data).
5. Change the extracted comparison function to use the check property instead of the sentinel. Test.
6. Move each shared client reaction (default name, default plan, zero counts...) onto the special-case object, deleting the conditional at each call site as you go. Test after each.
7. For clients that genuinely need different handling, apply Inline Function on the comparison so they probe the check property directly; remove the comparison function when it's dead.

**Pitfalls:**

- Special-case objects are values — keep them immutable even when the object they stand in for is mutable (writes should no-op or be rejected).
- If the special case must return related objects (e.g. a history), those are usually special cases too — build the chain of nulls.
- Read-only data doesn't need a class: a frozen literal record or a transform that enriches the raw data works fine.

## Introduce Assertion

```js
// before
return price * (1 - this.discountRate);

// after
assert(this.discountRate >= 0 && this.discountRate <= 1);
return price * (1 - this.discountRate);
```

**Use when:** A stretch of code silently assumes some condition holds and a reader could only deduce it by tracing the algorithm. An assertion states the assumption explicitly, doubles as documentation, and fails fast when a programmer error violates it. Do NOT use assertions to validate external input — that checking is real program logic — and don't assert everything you believe true, only what *must* be true for the code to work.

**Mechanics:**

1. Where a condition is assumed true, add an assertion stating it. (Since the program must behave identically with all assertions removed, adding one is always behavior-preserving.)

**Pitfalls:**

- Place the assertion where the bad state originates (e.g. the setter), not where it's consumed — a failure deep in a calculation leaves you asking how the value got there.
- Assertion conditions get tweaked over time; extract shared condition logic so duplicates can't drift apart.
- Other code must never depend on an assertion firing — failures signal bugs, not control flow.

## Replace Control Flag with Break

*Formerly: Remove Control Flag*

```js
// before
let expired = false;
for (const cert of certs) {
  if (!expired && cert.isExpired()) { notifyOwner(cert); expired = true; }
}

// after
for (const cert of certs) {
  if (cert.isExpired()) { notifyOwner(cert); break; }
}
```

**Use when:** A boolean variable is set in one place solely to steer control flow somewhere else — most often inside loops, written by someone avoiding `break`, `continue`, or multiple `return`s. Replace the flag with the direct control statement; once the work is done, say so plainly. The "one return per function" rule isn't worth the convolution it causes.

**Mechanics:**

1. Consider Extract Function on the flag-using code first, so the loop can be seen (and exited) in isolation.
2. Replace each assignment to the flag with the appropriate control statement — `return`, `break`, or `continue`. Test after each replacement.
3. When no updates remain, delete the flag and every test of it.

**Pitfalls:**

- Extracting to a function first often lets you use `return` instead of `break`, which reads even more directly.
- After removal, the loop frequently collapses into a pipeline (`some`/`find`/`any?`) — carry on and simplify.
- Language adaptation: in languages without `break` (e.g. Elixir, or Ruby blocks where it's awkward), extract the loop into a function and use early return, or switch to a find/detect-style pipeline.
