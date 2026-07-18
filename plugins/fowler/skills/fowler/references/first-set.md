# A First Set of Refactorings

These are the everyday workhorses of the catalog — the moves you reach for constantly. Extraction (of functions and variables) and its inverses handle the naming and shaping of small units of logic. Change Function Declaration, Rename Variable, and Encapsulate Variable let names and signatures evolve as understanding improves. Introduce Parameter Object shapes argument lists into real structures, and the last three — Combine Functions into Class, Combine Functions into Transform, Split Phase — group related functions into higher-level modules and separate distinct stages of processing.

## Table of contents

- [Extract Function](#extract-function)
- [Inline Function](#inline-function)
- [Extract Variable](#extract-variable)
- [Inline Variable](#inline-variable)
- [Change Function Declaration](#change-function-declaration)
- [Encapsulate Variable](#encapsulate-variable)
- [Rename Variable](#rename-variable)
- [Introduce Parameter Object](#introduce-parameter-object)
- [Combine Functions into Class](#combine-functions-into-class)
- [Combine Functions into Transform](#combine-functions-into-transform)
- [Split Phase](#split-phase)

## Extract Function

*Inverse of: Inline Function. Formerly: Extract Method.*

```js
// before
function renderProfile(user) {
  console.log(`user: ${user.handle}`);
  // show badge summary
  console.log(`badges: ${user.badges.map(b => b.name).join(", ")}`);
}
// after
function renderProfile(user) {
  console.log(`user: ${user.handle}`);
  printBadgeSummary(user);
}
```

**Use when:** A fragment of code requires effort to figure out *what* it does — pull it out and name it after that purpose, so intention and implementation separate cleanly. Length and reuse counts are weaker signals than this intention/implementation gap; a one-line extraction is fine if the name communicates better than the code. A leading comment describing a block is often the extracted function's name waiting to happen. Skip the extraction if you can't find a name that says more than the code itself — and don't fear function-call overhead; that concern is almost never justified today.

**Mechanics:**
1. Create a new function named for what the code does, not how. (If the language supports nested functions, nesting inside the source function sidesteps scope issues; you can move it out later.)
2. Copy the target fragment into the new function.
3. Handle variables local to the source function: pass used-but-unassigned ones as parameters; move declarations used only inside the fragment into it; if exactly one variable is assigned, return it as the result. If too many variables are assigned, abandon the extraction and first apply Split Variable or Replace Temp with Query.
4. Compile / run static checks if the language offers them.
5. Replace the original fragment with a call to the new function. Test.
6. Hunt for duplicates of the extracted code elsewhere and replace them with calls (Replace Inline Code with Function Call).

**Pitfalls:**
- Multiple assigned variables that must escape the fragment are the classic blocker — restructure the temps first rather than returning a grab-bag record.
- If you plan to move the function to another scope later, extracting to a sibling (not nested) level exposes variable problems immediately instead of deferring them.

## Inline Function

*Inverse of: Extract Function. Formerly: Inline Method.*

```js
// before
function shortQueue(line) { return waiting(line) < 3; }
function waiting(line)    { return line.members.length; }
// after
function shortQueue(line) { return line.members.length < 3; }
```

**Use when:** The function body communicates just as clearly as its name, so the indirection buys nothing — inline it and delete the noise. Also useful to collapse a badly factored group of functions into one lump so you can re-extract along better lines, or as the caller-migration step inside Change Function Declaration. Don't inline a method that subclasses override or that satisfies a polymorphic interface — callers depend on the dispatch, not just the body.

**Mechanics:**
1. Check the function isn't polymorphic (no overrides, no interface obligations).
2. Find all callers.
3. Replace each call with the function's body, adjusting variable names to fit the call site. Test after each replacement.
4. Remove the function definition. Test.

**Pitfalls:**
- If a call site is awkward to inline (recursion, multiple return points, the body needs accessors the caller lacks), that's a sign not to do this refactoring — inline only what stays simple.

## Extract Variable

*Inverse of: Inline Variable. Formerly: Introduce Explaining Variable.*

```js
// before
return seats * ratePerSeat + Math.max(0, seats - 10) * ratePerSeat * 0.2;
// after
const baseCost = seats * ratePerSeat;
const overflowSurcharge = Math.max(0, seats - 10) * ratePerSeat * 0.2;
return baseCost + overflowSurcharge;
```

**Use when:** An expression is dense enough that naming its sub-parts makes the logic legible; the named pieces also give a debugger something to hook onto. Ask where the name is meaningful: if only inside this function, a variable is right; if the concept matters to the wider context (especially inside a class), prefer extracting a function or method instead so other code can share it without duplicating the expression.

**Mechanics:**
1. Confirm the expression has no side effects.
2. Declare an immutable variable set to a copy of the expression.
3. Replace the original expression with the variable.
4. Test.
5. If the expression occurs elsewhere, replace each occurrence, testing after each.

## Inline Variable

*Inverse of: Extract Variable. Formerly: Inline Temp.*

```js
// before
const isStale = cacheEntry.age > 300;
return isStale;
// after
return cacheEntry.age > 300;
```

**Use when:** The variable's name says nothing beyond the expression it holds, or the variable is obstructing a neighboring refactoring (such as extracting or reordering code). If the name genuinely explains something, keep it — variables that clarify are worth their line.

**Mechanics:**
1. Check the right-hand side of the assignment has no side effects.
2. If the variable isn't declared immutable, make it so and test — this proves it's assigned only once.
3. Replace the first reference to the variable with the expression. Test.
4. Repeat for remaining references.
5. Remove the declaration and assignment. Test.

## Change Function Declaration

*Aka: Rename Function, Change Signature. Formerly: Rename Method, Add Parameter, Remove Parameter.*

```js
// before
function calc(r) { return 2 * Math.PI * r; }
// after
function perimeterOfCircle(radius) { return 2 * Math.PI * radius; }
```

**Use when:** Function declarations are the joints of a system — the name should say what a call does without reading the body, and the parameters decide what contexts can use it and how coupled callers become. Fix a misleading name the moment you understand a better one. Reshape parameters when it widens applicability or cuts coupling (e.g., take a value instead of the whole object it came from — or the reverse, when access to more of the object aids evolution). There is no permanently right signature; this refactoring is how signatures track your understanding.

**Mechanics (simple):** use when you can update the declaration and every caller in one pass.
1. If removing a parameter, verify the body doesn't reference it.
2. Change the declaration.
3. Update every reference to the old declaration. Test.
4. Do compound changes (rename + parameter change) as separate passes; if anything goes wrong, revert and switch to migration mechanics.

**Mechanics (migration):** use with many/awkward callers, polymorphic methods, published APIs, or complex signature changes.
1. If needed, first refactor the body so the next step is easy (e.g., Extract Variable on a value you want as a parameter).
2. Extract Function on the whole body into a function with the new signature (use a searchable temporary name if the final name collides with the old one).
3. Add any new parameters via the simple mechanics. Test.
4. Apply Inline Function to the old function, migrating callers one at a time, testing as you go.
5. If you used a temporary name, rename to the intended name. Test.

**Pitfalls:**
- Polymorphic methods need forwarding stubs on every implementation (or on the superclass if the hierarchy shares one).
- For a published API, stop after creating the new function: deprecate the old one and delete it only when all clients have migrated — possibly never.
- In dynamic languages, text search for callers yields false positives; lean on tests after each change.

## Encapsulate Variable

*Formerly: Self-Encapsulate Field, Encapsulate Field.*

```js
// before
let activeLocale = "en-US";
// after
let activeLocale = "en-US";
export function locale()       { return activeLocale; }
export function setLocale(arg) { activeLocale = arg; }
```

**Use when:** Widely shared mutable data is hard to move or change because every reference must update at once; routing all access through a getter/setter converts a data-reorganization problem into a much easier function-reorganization problem, and gives you a single point to add validation or change-monitoring. Encapsulate any mutable data whose scope exceeds a single function — the wider the scope, the more it matters. Immutable data needs far less of this: it can be copied freely and never needs update hooks.

**Mechanics:**
1. Write functions to read and to update the variable.
2. Run static checks.
3. Replace each direct reference with a call to the appropriate function. Test after each replacement.
4. Restrict the variable's visibility (e.g., module-private with only the accessors exported). If you can't, rename the variable and re-test to flush out stragglers.
5. Test.
6. If the value is a record, consider Encapsulate Record.

**Pitfalls:**
- The basic move controls reassignment of the variable, not mutation of its contents. To guard the value too, have the getter return a copy, or wrap the data in a class exposing read-only accessors — and remember either guard is only one level deep.
- Copying in the setter as well protects against the caller mutating the object it handed you — cheap insurance against painful debugging.

**Language adaptation:** the getter/setter pair maps to `attr_reader` plus a custom writer in Ruby, `@property` in Python, or making a field private behind accessor methods in Java/C#. The essence is identical: no direct references from outside.

## Rename Variable

```js
// before
let t = end - start;
// after
let elapsedMs = end - start;
```

**Use when:** A name no longer says what the variable is for — because the first name was hasty, your understanding deepened, or the program's purpose shifted. Care in proportion to scope: a one-letter variable in a tiny lambda is fine; a field that outlives a function invocation deserves a carefully chosen name.

**Mechanics:**
1. If the variable is referenced widely, apply Encapsulate Variable first, then rename the now-private variable behind the accessors.
2. Find every reference and change it. If the variable is read-only (a constant or exported read-only value), you can instead declare a new name assigned from the old one and migrate references gradually, testing along the way, then delete the alias.
3. Test.

**Pitfalls:**
- A variable referenced from code bases you don't control is published — you can't rename it, only wrap it.

## Introduce Parameter Object

```js
// before
function eventsBetween(events, startTime, endTime) { ... }
function countBetween(events, startTime, endTime) { ... }
// after
function eventsBetween(events, aTimeSpan) { ... }
function countBetween(events, aTimeSpan) { ... }
```

**Use when:** The same clump of data items travels together through function after function. Grouping them into one structure names the relationship, shrinks parameter lists, and enforces consistent naming. The deeper payoff: the new structure becomes a magnet for behavior (e.g., a span gaining a `contains(t)` method), often growing into an abstraction that reshapes how you see the domain. Prefer a class over a bare record so behavior has somewhere to live, and make it a value object.

**Mechanics:**
1. Create a suitable structure if none exists (prefer a value-object class). Test.
2. Use Change Function Declaration to add a parameter of the new type. Test.
3. Adjust each caller to pass an instance of the structure (unused as yet). Test after each.
4. Inside the function, replace uses of each original parameter with the structure's element, then remove that parameter. Test after each.

## Combine Functions into Class

```js
// before
function distanceKm(trip) { ... }
function fuelCost(trip) { ... }
// after
class Trip {
  get distanceKm() { ... }
  get fuelCost()   { ... }
}
```

**Use when:** A group of functions all operate on the same body of data, usually passed in as arguments — binding them into a class makes the shared environment explicit, strips those arguments from the calls, and gives you an object to hand around. A class also invites you to fold in other scattered fragments of related computation. Crucially, a class keeps derived values consistent even when clients mutate the core data — which is the main reason to pick it over Combine Functions into Transform. Prefer a class over nested functions: nested functions are hard to test and can expose only one entry point.

**Mechanics:**
1. Apply Encapsulate Record to the common data record the functions share (use Introduce Parameter Object first if the data isn't yet grouped).
2. Use Move Function to move each function into the class, dropping arguments that are now members. Test as you go.
3. Extract remaining inline snippets of logic on the data (Extract Function) and move them in too.

**Pitfalls:**
- In languages without classes, first-class functions can play the same role (Function As Object).

## Combine Functions into Transform

```js
// before
function distanceKm(trip) { ... }
function fuelCost(trip) { ... }
// after
function enrichTrip(argTrip) {
  const t = structuredClone(argTrip);
  t.distanceKm = distanceKm(t);
  t.fuelCost = fuelCost(t);
  return t;
}
```

**Use when:** Several derived values are computed from the same source data in scattered places, and you want a single home for all derivations. A transform takes the source record and returns an enriched copy carrying every derived field, so clients just read fields. Choose this over Combine Functions into Class only when the data is effectively read-only (e.g., preparing display data, or in a language with immutable structures) — if clients mutate the source after enrichment, the stored derivations go stale and inconsistent, and a class is the better home.

**Mechanics:**
1. Write a transform function that deep-copies its input and returns the copy unchanged. Write a test asserting the original record is not mutated.
2. Pick one derivation; move its logic into the transform as a new field on the copy (Extract Function first if the logic is tangled). Point client code at the new field. Test.
3. Repeat for each remaining derivation.

**Pitfalls:**
- A shallow copy silently shares nested structure with the source — deep-copy, and keep the "input unchanged" test.
- Name it "enrich…" when output is input-plus-extras; reserve "transform…" for output that's a genuinely different shape.

## Split Phase

```js
// before
const parts = tag.split(":");
const rate = rateTable[parts[0]];
const charge = Number(parts[1]) * rate;
// after
const parsed = parseTag(tag);              // phase 1: parse input
const charge = chargeFor(parsed, rateTable); // phase 2: compute
```

**Use when:** One block of code deals with two different concerns — commonly, massaging raw input into a usable shape, then running the real logic on it. Splitting into sequential phases that communicate through an intermediate data structure lets you change either phase without holding the other in your head (compilers — tokenize, parse, transform, generate — are the archetype). The telltale clue: different stretches of the code work with different sets of data and functions. Not worth it when the stages genuinely share everything; the split would just add plumbing.

**Mechanics:**
1. Apply Extract Function to the second-phase code. Test.
2. Add an intermediate data structure as an extra argument to that function. Test.
3. For each remaining parameter of the second phase: if the first phase produces or uses it, move it into the intermediate structure, removing the parameter. Test after each move. If a parameter shouldn't be seen by the second phase at all (e.g., raw input like an argv array), extract each usage's result into a field of the structure and move the populating line back to the caller (Move Statements to Callers).
4. Extract the first-phase code into a function that returns the intermediate structure. (A transformer object exposing query methods over the raw input is a fine alternative to a dumb record.)

**Pitfalls:**
- If testing is slow or awkward (e.g., logic buried in a CLI entry point), first extract the core into a directly callable function and move I/O to the caller — fast tests make the rest of the split far safer.
- A dumb record as the intermediate structure is fine; its scope is just the seam between two phases.
