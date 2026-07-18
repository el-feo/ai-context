# Encapsulation

The strongest lever for keeping change cheap is deciding what each module keeps secret. Data structures are the most common secret worth hiding: wrap records and collections so every read and write flows through a narrow interface, and even wrap lone primitives once they start attracting behavior. Temporary variables can also leak calculation details across a long function — turning them into queries frees up further refactoring. Classes are the classic unit of information hiding, and they need the same maintenance as functions: split them when they bloat, fold them back in when they wither, hide their collaborators when clients know too much, and expose collaborators again when the forwarding layer becomes noise. When an implementation is safely fenced behind a function boundary, you can even swap the whole algorithm out.

## Table of contents

- [Encapsulate Record](#encapsulate-record)
- [Encapsulate Collection](#encapsulate-collection)
- [Replace Primitive with Object](#replace-primitive-with-object)
- [Replace Temp with Query](#replace-temp-with-query)
- [Extract Class](#extract-class)
- [Inline Class](#inline-class)
- [Hide Delegate](#hide-delegate)
- [Remove Middle Man](#remove-middle-man)
- [Substitute Algorithm](#substitute-algorithm)

## Encapsulate Record

*Formerly: Replace Record with Data Class*

```js
// before
const venue = {city: "Lisbon", capacity: 400};

// after
class Venue {
  constructor(data) { this._city = data.city; this._capacity = data.capacity; }
  get city() { return this._city; }
  get capacity() { return this._capacity; }
}
```

**Use when:** A bare record (object literal, hash, dict, struct) is read and written across a wide scope. A class hides whether each value is stored or computed, gives you one place to intercept updates, and supports gradual renames by serving old and new names at once. Records are fine for immutable values or for structures confined to a small area — reach for the class when the data is mutable and widely shared. Hashmap-style records with no declared fields are the worst offenders at wide scope, since nothing documents their shape.

**Mechanics:**

1. Apply Encapsulate Variable to the variable holding the record; give the accessor functions deliberately ugly, searchable names — they will not survive long.
2. Replace the variable's content with a small class wrapping the record. Give the class an accessor that returns the raw record, and route the encapsulating functions through it. Test.
3. Add new functions that return the wrapper object instead of the raw record.
4. For each client, switch from the raw-record function to the object function, reading and writing fields through accessors on the class (create them as needed). Test after each change. For complex nested data, convert the updaters first; consider handing readers a copy or a read-only view.
5. Delete the raw-data accessor and the searchable raw-record functions. Test.
6. If fields are themselves records or collections, apply Encapsulate Record / Encapsulate Collection recursively.

**Pitfalls:**

- If the constructor stores the incoming record itself rather than copying fields out, outside references to that record can still mutate state behind the class's back — copy the data or unpack it into fields.
- With deeply nested data, hunting down every updater is the hard part. Verify by returning a deep copy (a missed writer breaks a test) or a frozen/read-only view that fails loudly on mutation.
- Handing readers a copy of a large structure can cost real time — measure before assuming, and beware clients who expect mutations of the copy to stick.

## Encapsulate Collection

```js
// before
class Playlist {
  get tracks() { return this._tracks; }
  set tracks(list) { this._tracks = list; }
}
// after
class Playlist {
  get tracks() { return this._tracks.slice(); }
  addTrack(t) { this._tracks.push(t); }
  removeTrack(t) { /* find and splice, error if absent */ }
}
```

**Use when:** A getter hands back the live collection, so callers can add or remove elements without the owning class ever knowing — the reference is encapsulated but the contents are not. Add explicit add/remove methods and stop leaking the raw collection. Don't go so far as to hide the collection interface entirely behind bespoke methods (`itemCount()` instead of `.items.length`); that kills the composability of standard collection operations. Skip the copy-on-read step only if it's genuinely a local, single-module structure.

**Mechanics:**

1. Apply Encapsulate Variable if the collection field isn't already behind accessors.
2. Add add/remove methods on the owning class. Remove the collection setter if you can; if the API must keep one, make it store a copy of what it's given.
3. Run static checks.
4. Find every caller that mutates the collection directly and convert it to the add/remove methods. Test after each change.
5. Change the getter to return a protected view — a copy or a read-only proxy. Test.

**Pitfalls:**

- Decide what removal of a missing element means (ignore vs. raise) and make it explicit.
- Copies and proxies differ: later changes to the source show through a proxy but not a copy. Either is usually fine for short-lived reads — just pick one convention and use it codebase-wide.
- Watch for sneaky in-place mutations — e.g. JavaScript's `sort` mutates the array. In languages with immutable-by-default collections (Clojure, frozen Ruby arrays, Java's `List.copyOf`) the protected-view step may already be free; in others use the idiomatic guard (`.slice()`, `.dup`, `Collections.unmodifiableList`).

## Replace Primitive with Object

*Formerly: Replace Data Value with Object · Replace Type Code with Class*

```js
// before
tickets.filter(t => t.severity === "critical" || t.severity === "blocker");

// after
tickets.filter(t => t.severity.atLeast(new Severity("critical")));
```

**Use when:** A value began life as a string or number but has grown needs — validation, formatting, comparison, parsing — and that logic is being duplicated wherever the value is used. Wrap it in a small value class; the wrapper looks trivial at first but becomes the natural home for behavior, and the second-order payoff is consistently bigger than expected. Not needed while the value really is just printed or passed through untouched.

**Mechanics:**

1. Apply Encapsulate Variable on the field if it isn't already.
2. Create a simple value class: constructor takes the current primitive, plus a getter or conversion method (`toString`) returning it.
3. Run static checks.
4. Change the setter to wrap the incoming primitive in the new class; update the field's declared type if the language has one.
5. Change the getter to return the wrapped object's underlying value. Test.
6. Consider Rename Function on the accessors so names say what they now return (e.g. `severityString` vs `severity`).
7. Consider Change Reference to Value or Change Value to Reference to pin down the new object's semantics.

**Pitfalls:**

- After the wrap, a getter that still returns the raw string has a lying name — rename it, and consider exposing the object itself once clients would benefit.
- If you expose the object, make it a proper value: immutable, with an equality method. Accepting either a primitive or an existing instance in the constructor eases migration.

## Replace Temp with Query

```js
// before
const shipping = this._weightKg * this._ratePerKg;
return shipping > 50 ? 50 : shipping;

// after
get shipping() { return this._weightKg * this._ratePerKg; }
// ... return this.shipping > 50 ? 50 : this.shipping;
```

**Use when:** A temp holds a computed value that's only read afterwards. Promoting it to a function removes a variable you'd otherwise have to thread into extracted functions — a big enabler when decomposing a long function — and lets other methods share the same calculation instead of duplicating it. Works best inside a class, where methods share context without parameter bloat. Not applicable to variables that are reassigned as true state, or snapshot variables (`previousTotal`) whose whole point is capturing an earlier value the recomputation would no longer produce.

**Mechanics:**

1. Verify the variable is fully computed before first use and that recomputing it at each use site would give the same value.
2. Make the variable read-only (`const`, `final`, `val`) if you can — a compile error here exposes a reassignment you missed. Test.
3. Extract the assignment's right-hand side into a function. If the variable and function can't share a name, use a temporary function name. Make sure the function has no side effects — apply Separate Query from Modifier if it does. Test.
4. Apply Inline Variable to remove the temp.

**Pitfalls:**

- Multiple assignments to one temp aren't automatically disqualifying — but the whole cluster of assignments must move into the query together.
- In languages without cheap read-only locals, substitute a search for reassignments; the check matters more than the keyword.

## Extract Class

*Inverse of: Inline Class*

```js
// before
class Employee {
  get street() { return this._street; }
  get postcode() { return this._postcode; }
}
// after
class Employee { get address() { return this._address; } }
class Address {
  get street() { return this._street; }
  get postcode() { return this._postcode; }
}
```

**Use when:** A class has accreted responsibilities until it's hard to hold in your head. Look for a subset of data and methods that hang together, change together, or depend on each other — a good probe is asking what else would turn to nonsense if you deleted one field. Subtyping pressure is another tell: when different features want to vary along different axes, they belong in different classes. Don't split just to satisfy a size rule; split along a genuine responsibility seam.

**Mechanics:**

1. Decide where the responsibility seam lies.
2. Create a new empty class for the split-off responsibility; rename the original if its remaining role no longer matches its name.
3. Construct an instance of the new class inside the parent's constructor and keep a field linking to it.
4. Apply Move Field for each field that belongs in the new class. Test after each move.
5. Apply Move Function for the methods, starting with the lowest-level ones (callees before callers). Test after each move.
6. Review both interfaces: drop what's unneeded, rename methods to fit their new home (a name like `officeAreaCode` sheds its `office` prefix once it lives in a phone-number class).
7. Decide whether to expose the new class to clients; if so, consider Change Reference to Value to make it a value object.

**Pitfalls:**

- The parent temporarily delegates everything, which looks like churn — that's the safe path; resist moving several members per step.

## Inline Class

*Inverse of: Extract Class*

```js
// before
class Shipment { get label() { return this._routing.label; } }
class Routing { get label() { return `${this._carrier}-${this._code}`; } }

// after
class Shipment { get label() { return `${this._carrier}-${this._code}`; } }
```

**Use when:** A class no longer pays for itself — usually after other refactorings drained its responsibilities — so fold the remnant into its heaviest user. Also useful as a staging move: to reallocate features between two awkwardly split classes, inline them into one, then Extract Class along the better seam. Don't inline a class that still owns a coherent responsibility just because it's small.

**Mechanics:**

1. In the absorbing class, create delegating methods for every public method of the doomed class.
2. Repoint all callers at the absorbing class's delegators. Test after each change.
3. Move each function and field across to the target — test after every move — until the source is hollow.
4. Delete the empty class.

**Pitfalls:**

- Because the target is the only remaining referrer during the moves, you can use lighter-weight field moves than the full Move Field mechanics — but only once step 2 is truly complete.

## Hide Delegate

*Inverse of: Remove Middle Man*

```js
// before
const dueDate = invoice.account.plan.renewalDate;

// after
const dueDate = invoice.renewalDate;
// class Invoice { get renewalDate() { return this._account.plan.renewalDate; } }
```

**Use when:** Clients reach through a server object into one of its collaborators (`a.b.c`), which welds them to the collaborator's interface — any change there ripples to every client. Add a forwarding method on the server so clients only know about the server, and changes to the delegate stop at one place. Skip it when the delegate's interface is stable and widely understood, or you'll drown the server in forwarding methods (see Remove Middle Man).

**Mechanics:**

1. For each delegate method clients use, add a simple forwarding method on the server.
2. Point each client at the server's method instead of the chain. Test after each change.
3. If no client still needs the delegate itself, remove the server's accessor for it. Test.

## Remove Middle Man

*Inverse of: Hide Delegate*

```js
// before
const dueDate = invoice.renewalDate;   // Invoice just forwards to account.plan

// after
const dueDate = invoice.account.plan.renewalDate;
```

**Use when:** A class has become mostly a switchboard — every new delegate feature forces another forwarding method, and the wrapping adds nothing. Let clients talk to the delegate directly. There is no fixed right amount of hiding: a boundary that was good encapsulation six months ago may be dead weight now, and since this refactoring and Hide Delegate invert each other, you can rebalance at any time. A mixed outcome is fine — keep the few delegations clients use constantly, remove the rest. (Over-zealous Law of Demeter compliance is the classic way codebases end up needing this.)

**Mechanics:**

1. Add a getter for the delegate on the server if one doesn't exist.
2. For each client call to a forwarding method, replace it with a chain through the delegate accessor. Test after each replacement. When a forwarding method has no callers left, delete it.
3. With automated tooling: Encapsulate Variable on the delegate field, then Inline Function on each forwarding method to update all callers in one shot.

## Substitute Algorithm

```js
// before
function pickWinner(entries) {
  for (let i = 0; i < entries.length; i++) {
    if (entries[i].score >= 90) return entries[i];
  }
  return null;
}
// after
const pickWinner = entries => entries.find(e => e.score >= 90) ?? null;
```

**Use when:** You've found a plainly clearer way to do the whole job — you understand the problem better now, a library call replaces your hand-rolled code, or a coming behavior change would be far easier against a simpler base. This is wholesale replacement, not incremental cleanup, so use it only after decomposing the function as far as it will go: swapping a big tangled algorithm is hard; swapping a small one is tractable.

**Mechanics:**

1. Arrange the code to be replaced so it occupies exactly one function.
2. Write tests against that function alone, pinning its current behavior.
3. Write the replacement algorithm.
4. Run static checks.
5. Run the tests comparing old and new outputs. If they match, you're done; if not, keep the old algorithm around as a testing/debugging oracle while you converge.

**Pitfalls:**

- Don't attempt the swap on a function that still does several jobs — extract until the algorithm stands alone, or the substitution becomes a rewrite with no safety net.
