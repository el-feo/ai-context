# Moving Features

These refactorings relocate program elements between contexts rather than creating or renaming them. Move Function and Move Field shift behavior and data between classes and modules as your understanding of the right grouping improves. The statement-level moves (Move Statements into Function, Move Statements to Callers, Slide Statements, Replace Inline Code with Function Call) adjust function boundaries and line ordering in small, safe steps. Split Loop and Replace Loop with Pipeline restructure iteration so each pass does one understandable thing, and Remove Dead Code clears out anything no longer earning its place.

## Table of contents

- [Move Function](#move-function)
- [Move Field](#move-field)
- [Move Statements into Function](#move-statements-into-function)
- [Move Statements to Callers](#move-statements-to-callers)
- [Replace Inline Code with Function Call](#replace-inline-code-with-function-call)
- [Slide Statements](#slide-statements)
- [Split Loop](#split-loop)
- [Replace Loop with Pipeline](#replace-loop-with-pipeline)
- [Remove Dead Code](#remove-dead-code)

## Move Function

*Formerly: Move Method*

```js
// before
class Cart { get shippingCost() { /* uses this.region data */ } }
// after
class Region { shippingCost(weight) { /* lives with the data it uses */ } }
```

**Use when:** A function talks to another context's data or functions more than its own, when its callers live elsewhere, or when a helper nested inside another function deserves standalone visibility. Judge by examining what the function calls, who calls it, and what data it touches — if a whole cluster of functions wants a new home, reach for Extract Class or Combine Functions into Class instead. When the choice of destination is genuinely hard, it usually matters less than it feels; pick one, and move again later if it doesn't fit.

**Mechanics:**

1. Examine everything the function uses in its current context; decide whether any of it should move too. Move the least-dependent function of a cluster first. If subfunctions have only this one caller, consider inlining them, moving, and re-extracting at the destination.
2. Check whether the function is a polymorphic method — in a class hierarchy, account for super- and subclass declarations.
3. Copy the function into the target context and adapt it: pass source-context elements as parameters or pass a reference to the source object. A rename often suits the new home; a throwaway name is fine at first.
4. Run static analysis (linter/compiler) on the copy.
5. Work out how the source context will reference the target function.
6. Turn the source function into a thin delegation to the target.
7. Test.
8. Consider Inline Function on the delegating stub — keep it if callers benefit from the old entry point, delete it if they can just as easily call the target.

**Pitfalls:**

- Deciding what travels with the function is the real work: data that varies per source object (not per target) must stay behind and be passed in.
- When many values would need passing, consider passing the whole source object instead of individual fields.

## Move Field

```js
// before
class Subscription { get taxRate() { return this._taxRate; } }
// after — rate belongs to the plan, not each subscription
class Subscription { get taxRate() { return this._plan.taxRate; } }
```

**Use when:** A field lives in the wrong record — telltale signs are always passing one record's field alongside another record, a change in one record forcing an update to a field elsewhere, or the same fact being updated in several structures. Fix data placement as soon as you spot the problem; a bad structure compounds into messy behavior code. Often part of a broader sequence: some usage patterns may need refactoring before the move is even possible, and follow-up refactorings redirect clients to the new home afterward.

**Mechanics:**

1. Ensure the source field is encapsulated behind accessors (Encapsulate Variable / Encapsulate Record if not).
2. Test.
3. Add the field, with its accessors, to the target class.
4. Run static checks.
5. Ensure the source object can reach the target object — an existing field or method, or a new (possibly temporary) reference field.
6. Change the source accessors to read and write the target's field. If the target is shared among several source objects, first have the setter update both copies and use Introduce Assertion to catch divergence before switching fully.
7. Test.
8. Remove the source field.
9. Test.

**Pitfalls:**

- Moving a per-object field onto a shared object (e.g., per-item setting moved to a shared category) changes behavior unless every object already agrees with the shared value — verify stored data and/or assert before committing.
- Watch initialization order: the target object must exist before the source constructor writes through it.
- Bare records without encapsulation make this much trickier — wrap the record in a class first if you can. (In languages with public structs or plain dicts/hashes, introduce accessor functions before moving.)

## Move Statements into Function

*Inverse of: Move Statements to Callers*

```js
// before — every caller repeats the header line
log.push(`== ${job.name} ==`);
log.push(...jobDetails(job));
// after
log.push(...jobDetails(job)); // jobDetails now emits the header too
```

**Use when:** The same statements execute before or after every call to a function — fold them in so future edits happen in one place. Only do this if the statements make sense as part of the called function's responsibility; if they merely travel together, use Extract Function to wrap both instead. Don't fold in code that some callers will need to vary — that's what the inverse refactoring is for.

**Mechanics:**

1. If the repeated code isn't adjacent to the call, use Slide Statements to bring it next to the call.
2. If the target function has only one caller: cut, paste into the target, test, done.
3. Otherwise, at one call site use Extract Function on the repeated statements plus the call itself; give the new function a temporary, greppable name.
4. Convert every other call site to the new function. Test after each conversion.
5. Use Inline Function to fold the original function's body into the new one and delete the original.
6. Rename the new function to the original name (or a better one).

## Move Statements to Callers

*Inverse of: Move Statements into Function*

```js
// before
function printReceipt(out, order) { printItems(out, order); printFooter(out); }
// after — footer now varies per caller
function printReceipt(out, order) { printItems(out, order); }
printReceipt(out, order); printFooter(out);
```

**Use when:** Behavior that was once uniform now needs to differ at some call sites — push the varying part out to the callers so each can adapt it. Use Slide Statements first if the varying code isn't already at the function's start or end. When the boundary is wrong in a bigger way than a line or two, inline the whole function and re-extract fresh boundaries instead.

**Mechanics:**

1. With only one or two callers and a simple function: cut the fragment from the callee, paste it into each caller, adjust, test, done.
2. Otherwise, apply Extract Function to the statements that should *stay*, under a temporary greppable name. If subclasses override the method, extract in each so the remainder is identical everywhere, then delete the subclass copies.
3. Use Inline Function on the original function, one call site at a time, testing after each — this deposits the moved statements at each caller.
4. Rename the extracted function to the original name (or a better one).

## Replace Inline Code with Function Call

```js
// before
let hasAdmin = false;
for (const r of roles) { if (r === "admin") hasAdmin = true; }
// after
const hasAdmin = roles.includes("admin");
```

**Use when:** Inline code does the same job as an existing function — especially a library or standard-library function, where you get the deletion for free. The function's name is the test: if it reads correctly in place of the inline code, call it. Skip this when the resemblance is coincidental — if a future change to the function's body shouldn't change this call site's behavior, they aren't really the same thing.

**Mechanics:**

1. Swap the duplicated statements for a call to the function.
2. Test.

## Slide Statements

*Formerly: Consolidate Duplicate Conditional Fragments*

```js
// before
const plan = loadPlan(); const user = loadUser(); const rate = plan.rate;
// after — related lines together
const plan = loadPlan(); const rate = plan.rate; const user = loadUser();
```

**Use when:** Related statements are scattered — declarations far from first use, or code touching one structure interleaved with code touching another. Usually a preparatory step: you can't Extract Function until the fragment is contiguous. Abandon the slide when statements in between interfere with the fragment.

**Mechanics:**

1. Identify the target position. Check every statement between source and target for interference; abandon if any exists. A fragment cannot slide: earlier than the declaration of anything it references; past any statement that references it; over a statement that modifies something it references; or (if it modifies something) over a statement that references what it modifies.
2. Cut the fragment and paste it at the target position.
3. Test.
4. On failure, retry with smaller slides — a shorter distance or a smaller fragment.

**Pitfalls:**

- Side effects are the hazard: a value-returning call is only safely slidable if you know it's side-effect-free, which depends on trusting the codebase (e.g., command–query separation). In unfamiliar code, be cautious and lean on tests.
- The "no shared modified data" rule is conservative, not exact — commuting operations (two independent increments) can swap even though they touch the same variable. When in doubt, don't.
- Sliding identical statements out of both branches of a conditional merges them into one; sliding into a conditional duplicates the fragment into every branch.

## Split Loop

```js
// before
for (const o of orders) { revenue += o.total; count += o.items.length; }
// after
for (const o of orders) revenue += o.total;
for (const o of orders) count += o.items.length;
```

**Use when:** One loop computes two or more unrelated things, forcing every future editor to understand all of them at once. Splitting also unlocks Extract Function — a loop computing one value can become a function returning that value. Don't refuse on performance instinct: iterate-twice is rarely a bottleneck, and clarity first, optimize later (recombining is easy if profiling ever demands it).

**Mechanics:**

1. Copy the loop.
2. Delete the duplicated side effects so each copy performs only one of the jobs.
3. Test.
4. Consider Extract Function on each resulting loop (often after Slide Statements to group each loop with its setup variables).

**Pitfalls:**

- Between copying and de-duplicating, the code briefly double-executes side effects — remove the duplication before running anything that matters.
- The split is often just the setup: the payoff comes from the follow-on extractions and from turning each single-purpose loop into a pipeline.

## Replace Loop with Pipeline

```js
// before
const emails = [];
for (const u of users) { if (u.active) emails.push(u.email); }
// after
const emails = users.filter(u => u.active).map(u => u.email);
```

**Use when:** A loop's body is a sequence of filtering, transforming, and accumulating steps — a collection pipeline expresses the same logic as a top-to-bottom flow of operations (map, filter, reduce, slice), which is easier to read than interleaved conditionals and control variables. Language mapping: JS array methods here correspond to Ruby Enumerable (`select`/`map`/`sum`), Python comprehensions or itertools, Java Streams, C# LINQ, Rust iterator adapters. Less compelling when the loop has early exits, cross-iteration state, or side effects that don't decompose into pipeline stages.

**Mechanics:**

1. Introduce a new variable for the collection the loop iterates over (may start as a plain alias).
2. Working top-down through the loop body, move each bit of behavior out of the loop and into a pipeline operation appended to that variable's derivation (skip-first-line becomes a slice/drop, a guard becomes a filter, a transformation becomes a map). Test after each operation.
3. When the loop body is empty (or only assigns to an accumulator), delete the loop and assign the pipeline result directly.

**Pitfalls:**

- Control variables (first-iteration flags, `continue` guards) usually dissolve into slice/filter stages — deleting them is a sign you're doing it right.
- Keep intermediate variable names stable during the conversion; rename lambda parameters as cleanup afterward.

## Remove Dead Code

```js
// before
if (false) { legacyReconcile(); } // unreachable since v2 migration
// after
// (gone)
```

**Use when:** Code is never executed or never referenced. It costs nothing at runtime, but it taxes every reader who must figure out why changing it does nothing. Don't keep it "just in case" and don't comment it out — version control is the archive; at most, leave a note naming the revision where it was removed. If the resemblance to future needs is strong, that's still what history is for.

**Mechanics:**

1. If the dead code is externally referenceable (e.g., a whole function), search for callers first to confirm it's truly unused.
2. Delete it.
3. Test.
