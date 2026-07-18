# Refactoring APIs

APIs are the joints between modules, and they deserve the same iterative improvement as the code behind them. A good API keeps reads and writes visibly separate (command-query separation), takes honest parameters that describe real points of variability, and never asks callers to pass a boolean to pick which of two functions they actually wanted. The refactorings here tune those joints: splitting side effects out of queries, merging near-duplicate functions, deciding what a function should be told versus what it should figure out, encouraging immutability, and choosing the right shape — function, command object, exception, or plain return value — for each job.

## Table of contents

- [Separate Query from Modifier](#separate-query-from-modifier)
- [Parameterize Function](#parameterize-function)
- [Remove Flag Argument](#remove-flag-argument)
- [Preserve Whole Object](#preserve-whole-object)
- [Replace Parameter with Query](#replace-parameter-with-query)
- [Replace Query with Parameter](#replace-query-with-parameter)
- [Remove Setting Method](#remove-setting-method)
- [Replace Constructor with Factory Function](#replace-constructor-with-factory-function)
- [Replace Function with Command](#replace-function-with-command)
- [Replace Command with Function](#replace-command-with-function)
- [Return Modified Value](#return-modified-value)
- [Replace Error Code with Exception](#replace-error-code-with-exception)
- [Replace Exception with Precheck](#replace-exception-with-precheck)

## Separate Query from Modifier

```js
// before
function lowStockCountAndNotify(items) {
  const low = items.filter(i => i.qty < i.min).length;
  warehouse.sendRestockAlert();
  return low;
}
// after
function lowStockCount(items) { return items.filter(i => i.qty < i.min).length; }
function notifyRestock(items) { if (lowStockCount(items) > 0) warehouse.sendRestockAlert(); }
```

**Use when:** A function both returns a value and has observable side effects. Splitting it gives you a pure query you can call freely, reorder, and test without worry, plus a clearly labeled modifier — the command-query separation rule: value-returning functions should have no observable side effects. Note "observable": an internal cache that doesn't change what any sequence of queries returns doesn't count, so don't split a function just because it memoizes.

**Mechanics:**

1. Copy the function and name the copy as a query (the variable it populates at call sites often suggests the name).
2. Strip all side effects from the new query. Run static checks.
3. At each call site that uses the return value, call the query first, then call the original function below it. Test after each change.
4. Remove the return value from the original (now pure modifier). Test.
5. Tidy the duplication — often the modifier can be rewritten to call the query (Substitute Algorithm).

## Parameterize Function

*Formerly: Parameterize Method*

```js
// before
function addSmallCredit(acct) { acct.balance += 5; }
function addLargeCredit(acct) { acct.balance += 25; }
// after
function addCredit(acct, amount) { acct.balance += amount; }
```

**Use when:** Two or more functions run nearly identical logic that differs only in embedded literal values. One parameterized function removes the duplication and is reusable for values you haven't needed yet. For range-style families (low/middle/high tiers), start from the middle case — it usually exposes both bounds as parameters; edge cases may need sentinel values like zero or infinity. Don't force it when the functions differ in behavior rather than in a value — that's flag-argument territory.

**Mechanics:**

1. Pick one of the similar functions (for ranges, prefer the middle one).
2. Use Change Function Declaration to add parameters for the literals that vary; rename the function if the parameterized version deserves a broader name.
3. Add the literal values at each existing call site. Test.
4. Replace each literal in the body with the corresponding parameter, one at a time. Test after each.
5. Replace each sibling function's call sites with calls to the parameterized function, adjusting it if a sibling doesn't quite fit. Test after each one.

## Remove Flag Argument

*Formerly: Replace Parameter with Explicit Methods*

```js
// before
exportReport(report, true);   // what does true mean?
function exportReport(report, isCsv) { if (isCsv) {...} else {...} }
// after
exportReportAsCsv(report);
exportReportAsPdf(report);
```

**Use when:** Callers pass a literal (boolean, enum, string) whose only job is to select which branch of logic the function runs. Explicit functions per behavior make the API browsable and the call sites self-documenting — `true` in an argument list tells the reader nothing. It's only a flag argument if callers pass a *literal* and the function uses it for *control flow*; if the value flows in as runtime data, leave the signature alone. With two or more flags, explicit functions for every combination explode — that's a sign the function does too much and should be split into composable pieces instead.

**Mechanics:**

1. Give each flag value its own explicitly named function. If the function dispatches on the flag at its top level, use Decompose Conditional to extract the branches; if the flag is tangled through the body, write thin wrapper functions that call the original with the literal filled in.
2. Replace each call site that passes a literal with a call to the matching explicit function.
3. If no callers pass the flag as data, delete (or hide/rename) the original; if some do, keep it for them.

**Pitfalls:**

- Mixed callers are fine: convert the literal-passing ones, keep the original signature for callers that pass computed data.
- With wrapper functions, restrict the original's visibility or rename it so new code doesn't call it directly.

## Preserve Whole Object

```js
// before
const start = trip.window.start;
const end = trip.window.end;
if (scheduler.canBook(start, end)) ...
// after
if (scheduler.canBook(trip.window)) ...
```

**Use when:** Code pulls several values out of one object just to pass them into a function. Passing the whole object shortens parameter lists, survives the function needing more of the object later, and removes duplicated unpacking logic across callers. Skip it when you don't want the callee coupled to the whole object — typically across module boundaries. If a function pulls values out of an object to compute on them, consider moving that logic into the object itself; and if several functions use only the same slice of an object, that hints at Extract Class. Also watch for an object passing several of its own fields to another object — replace them with `this`/`self`.

**Mechanics:**

1. Create an empty function with the desired whole-object signature, under an easily searchable temporary name.
2. Fill its body with a call to the old function, mapping the new parameter to the old ones. Run static checks.
3. Switch each caller to the new function, testing after each; delete now-unneeded derivation code (Remove Dead Code).
4. When all callers are converted, use Inline Function on the old function.
5. Rename the new function (and its call sites) to the original name.

## Replace Parameter with Query

*Inverse of: Replace Query with Parameter. Formerly: Replace Parameter with Method*

```js
// before
renewalFee(member, member.tier);
function renewalFee(member, tier) { ... }
// after
renewalFee(member);
function renewalFee(member) { const tier = member.tier; ... }
```

**Use when:** A caller passes a value the function could just as easily determine itself — most safely, when the value is derivable from another parameter already in the list. Removing it simplifies every call site and shrinks the parameter list. Don't do it if resolving the value inside the function would add a dependency you don't want the function to have, and never trade a parameter for a read of mutable global state — that destroys referential transparency.

**Mechanics:**

1. If needed, use Extract Function on the computation of the parameter's value so the body can call it.
2. Replace each reference to the parameter in the body with the expression/query that yields it. Test after each change.
3. Use Change Function Declaration to drop the parameter.

## Replace Query with Parameter

*Inverse of: Replace Parameter with Query*

```js
// before
function greeting(user) { return locale.hour() < 12 ? `Morning ${user}` : `Hello ${user}`; }
// after
function greeting(user, hour) { return hour < 12 ? `Morning ${user}` : `Hello ${user}`; }
```

**Use when:** A function body reaches out to something you'd rather it didn't know about — a global, a session object, a module element you plan to move. Hoisting the reference into a parameter breaks the dependency and can make the function referentially transparent (same inputs, same result), which is a big win for testing; a common architecture is a pure core wrapped by a thin I/O layer. The cost is real: every caller now has to supply the value, so call sites get clumsier. This decision is about allocating responsibility and you'll revisit it — which is why you need both this refactoring and its inverse.

**Mechanics:**

1. Use Extract Variable to pull the offending query out of the rest of the body.
2. Apply Extract Function to the body minus the query, under an easily searchable name — the extracted function takes the query result as a parameter.
3. Use Inline Variable to eliminate the temporary.
4. Apply Inline Function to the original function, pushing the query out to each caller.
5. Rename the new function to the original's name.

## Remove Setting Method

```js
// before
class Ticket { get code() {...}  set code(v) {...} }
const t = new Ticket(); t.code = "A-17";
// after
class Ticket { constructor(code) { this._code = code; }  get code() {...} }
const t = new Ticket("A-17");
```

**Use when:** A field should never change after construction, yet a setter exists — usually because construction happens via a create-then-assign script, or because a style rule forced all field access through accessors. Removing the setter and initializing through the constructor states the immutability intent and often enforces it. Abandon the refactoring if callers genuinely update the field on a shared, long-lived object — that field really is mutable.

**Mechanics:**

1. If the constructor doesn't receive the value, use Change Function Declaration to add it, and have the constructor set the field (batch all setters you're removing in one constructor change).
2. Replace each post-construction setter call by passing the value to the constructor instead. Test after each. If a setter call can't be replaced by creating a new object (shared reference being updated), stop — the refactoring doesn't apply.
3. Use Inline Function on the setter; make the field immutable if the language allows (`final`, `readonly`, `freeze`, etc.). Test.

## Replace Constructor with Factory Function

*Formerly: Replace Constructor with Factory Method*

```js
// before
const acct = new Account(owner, "SAVINGS");
// after
const acct = createSavingsAccount(owner);
function createSavingsAccount(owner) { return new Account(owner, "SAVINGS"); }
```

**Use when:** Constructors carry language-imposed limits — fixed name, must return an instance of exactly that class, often need a special invocation operator — that a plain function doesn't. A factory function can pick a better name, encode a variant (avoiding literal type codes at call sites), return a subclass or proxy, and be passed around like any function. In languages without these constructor constraints the payoff is smaller; use it when you need the flexibility or the clearer name. (Python `@classmethod` constructors and Ruby class-level factory methods are idiomatic equivalents.)

**Mechanics:**

1. Write a factory function whose body just calls the constructor.
2. Replace each constructor call with a call to the factory. Test after each change.
3. Restrict the constructor's visibility as far as the language allows.

## Replace Function with Command

*Inverse of: Replace Command with Function. Formerly: Replace Method with Method Object*

```js
// before
function reconcile(ledger, feed, rules) { /* long body, many locals */ }
// after
class Reconciler {
  constructor(ledger, feed, rules) { this._ledger = ledger; this._feed = feed; this._rules = rules; }
  execute() { /* long body; locals become fields, steps become methods */ }
}
```

**Use when:** You need more than a plain function offers: undo, a staged parameter-building lifecycle, customization via inheritance, or — most commonly — a way to decompose a long function whose tangled local variables defeat Extract Function. Converting locals to fields lets you extract sub-steps into methods that share state, and lets tests exercise those steps directly. This power costs complexity: prefer a plain function (or nested functions, where the language has them) about 95% of the time, and reach for a command only when the simpler tools can't do the job.

**Mechanics:**

1. Create an empty class named after the function.
2. Use Move Function to move the function body into the class as an execute-style method (follow the language's naming convention for commands); keep the original function as a forwarder until the end.
3. Consider giving each argument a field, moving them one at a time from the execute method to the constructor. Test as you go.
4. To decompose further: convert local variables to fields one at a time, then Extract Function on the now-untangled steps.

**Pitfalls:**

- Note the terminology clash: "command" here means an object encapsulating a request (the Command pattern), not the "command" of command-query separation.

## Replace Command with Function

*Inverse of: Replace Function with Command*

```js
// before
class TaxCalculator {
  constructor(amount, rate) { this._amount = amount; this._rate = rate; }
  execute() { return this._amount * this._rate; }
}
// after
function tax(amount, rate) { return amount * rate; }
```

**Use when:** A command object's ceremony (class, constructor, fields, execute call) outweighs its payoff because the computation is simple and callers only ever build-then-run it. Fold it back into a plain function. Keep the command if you actually use its richer lifecycle — staged setup, multiple entry points, undo.

**Mechanics:**

1. Apply Extract Function to the "construct + call execute" pair at a call site — this creates the replacement function.
2. Inline each supporting method into the execute method (Inline Function; for value-returning helpers, Extract Variable on the result first).
3. Use Change Function Declaration to move the constructor's parameters onto the execute method.
4. Switch each field reference in the execute body to the corresponding parameter, one at a time; also delete the constructor assignment so a missed reference fails a test. Test after each change.
5. Inline the constructor-plus-execute call into the replacement function. Test.
6. Remove the dead command class (Remove Dead Code).

## Return Modified Value

```js
// before
let cartWeight = 0;
sumWeights();
function sumWeights() { for (const item of cart) cartWeight += item.weight; }
// after
const cartWeight = sumWeights();
function sumWeights() { let result = 0; for (const item of cart) result += item.weight; return result; }
```

**Use when:** A function updates an outer-scope variable as a hidden side effect. Returning the value and assigning at the call site makes the data flow visible where it matters — the caller — and often lets the variable become single-assignment/const. Best for functions that compute one value; not effective for functions coordinating several updates. A handy preliminary to Move Function, since it severs the function's tie to its environment.

**Mechanics:**

1. Return the modified variable from the function; assign the result to the variable at the call site. Test.
2. Declare the variable locally inside the function (shadowing the outer one). Test.
3. Merge declaration and initialization at the call site; mark it non-modifiable (`const`, `final`) if the language supports it. Test.
4. Rename the local in the function to a generic result name per your convention. Test.

## Replace Error Code with Exception

```js
// before
function parseConfig(text) {
  if (!isValid(text)) return -1;
  return buildConfig(text);
}
// after
function parseConfig(text) {
  if (!isValid(text)) throw new ConfigError("invalid config");
  return buildConfig(text);
}
```

**Use when:** Error codes force every intermediate caller to remember to check and forward them; exceptions jump straight to a handler and keep the main flow readable. Reserve them for genuinely unexpected failures: a good litmus test is whether the program would still be essentially correct if the throw were replaced with program termination — if not, the condition is part of normal flow and should be handled as ordinary logic (see Replace Exception with Precheck). Language adaptation: in Rust/Go/Elm-style languages, typed `Result`/error returns are the idiomatic "separate channel" — apply the same spirit (stop hand-forwarding raw codes; use `?`/`if err != nil` propagation with a typed error) rather than literally introducing exceptions.

**Mechanics:**

1. Put an exception handler high in the call chain where the error is dealt with; initially it just rethrows everything (or extend an existing suitable handler). Test.
2. Choose a marker to identify the new exceptions — a subclass where the language catches by type, or a distinguishing property otherwise. Run static checks.
3. Make the handler perform the error action for the marked exception and rethrow anything else. Test.
4. Replace each error-code return with throwing the new exception. Test after each change.
5. Remove the code-forwarding checks in intermediate callers — replace each check with a "should be unreachable" trap first, test, then delete it and any dead error-code handling. Test after each change.

**Pitfalls:**

- Always rethrow exceptions you didn't intend to handle; a broad catch that swallows unrelated errors is worse than the error codes were.

## Replace Exception with Precheck

*Formerly: Replace Exception with Test*

```js
// before
function nextJob(queue) {
  try { return queue.pop(); }
  catch (e) { return Job.idle(); }
}
// after
function nextJob(queue) {
  return queue.isEmpty() ? Job.idle() : queue.pop();
}
```

**Use when:** A catch block handles a condition the caller could reasonably check up front — an empty collection, a missing key, exhausted capacity. That's expected behavior, not an error, and a plain conditional says so while keeping exceptions meaningful for real failures. Don't apply it when the check would race (e.g., filesystem or concurrent state can change between check and use) — there the try-based form may be correct.

**Mechanics:**

1. Add a conditional testing the case that raised the exception; move the catch-block code into that leg and leave the try block in the other.
2. Put an assertion (or "unreachable" throw) in the now-dead catch block. Test.
3. Delete the try/catch scaffolding, leaving the plain conditional. Test.
4. Often the result can be tidied further (hoist duplicated statements out of both legs, collapse to a ternary).
