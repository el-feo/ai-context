# Organizing Data

Data structures are where a program's meaning lives, so keeping them honest pays off everywhere else. These refactorings enforce a few disciplines: give each variable exactly one job (Split Variable), keep names aligned with your current understanding (Rename Field), delete stored data you could compute on demand (Replace Derived Variable with Query), be deliberate about whether a nested object is a shared reference or a disposable value (Change Reference to Value / Change Value to Reference), and never let a bare literal carry hidden meaning (Replace Magic Literal).

## Table of contents

- [Split Variable](#split-variable)
- [Rename Field](#rename-field)
- [Replace Derived Variable with Query](#replace-derived-variable-with-query)
- [Change Reference to Value](#change-reference-to-value)
- [Change Value to Reference](#change-value-to-reference)
- [Replace Magic Literal](#replace-magic-literal)

## Split Variable

*Formerly: Remove Assignments to Parameters; Split Temp*

```js
// before
let size = box.w * box.h;          // area
size = 2 * (box.w + box.h);        // now it's the border length!
// after
const area = box.w * box.h;
const borderLength = 2 * (box.w + box.h);
```

**Use when:** A variable is assigned more than once and each assignment means something different — that's one name doing two jobs, and readers will conflate them. Also applies to reassigned input parameters: introduce a separate result variable instead of mutating the argument. Do NOT split legitimate multi-assignment variables: loop indices and collecting variables (accumulators of the `total = total + x` shape used for sums, concatenation, or building collections) are supposed to be reassigned.

**Mechanics:**

1. Rename the variable at its declaration and first assignment; skip the whole refactoring if it's a collecting variable (`x = x + ...`).
2. Declare the new variable as immutable (`const` or the local equivalent) if you can.
3. Update every reference to the old name up to the second assignment.
4. Test.
5. Repeat stage by stage — rename at each subsequent assignment, fix references up to the next one — until the last assignment gets its own well-named variable.

**Pitfalls:**

- An immutable declaration is your safety net: the compiler/runtime flags any reassignment you missed. In languages without `const`-style locals, lean on tests and careful reference tracing instead.

## Rename Field

```js
// before
class Invoice { get client() { return this._client; } }
// after
class Invoice { get payer() { return this._payer; } }
```

**Use when:** A field's name no longer matches your best understanding of the data. Record structures are read all over a codebase — a stale or vague field name spreads confusion everywhere the record travels — so fold improved understanding back into the name. This applies equally to bare record keys and to getter/setter pairs, which act as a field from the caller's perspective. If the record is only used in a narrow scope, skip the ceremony and just rename directly.

**Mechanics:**

1. If the record has limited scope, rename every access in one pass, test, and stop here.
2. Otherwise, if the record isn't encapsulated, apply Encapsulate Record first so the internal field, accessors, and constructor can each change independently.
3. Rename the private field inside the object and adjust internal methods. Test.
4. If the constructor takes the old name, use Change Function Declaration to migrate it — temporarily accept both old and new names, move callers one by one, then drop the old name.
5. Apply Rename Function to the getter and setter.

**Pitfalls:**

- With mutable data, never leave the same information stored under two names longer than mid-refactoring — duplicated mutable state drifts out of sync. If the structure is immutable, a simpler route works: copy the data to the new name, migrate readers gradually, delete the old name.

## Replace Derived Variable with Query

```js
// before
addItem(item) { this._items.push(item); this._count += 1; }
get count() { return this._count; }
// after
addItem(item) { this._items.push(item); }
get count() { return this._items.length; }
```

**Use when:** A stored field is just a cached computation over other data you already hold — every update site must remember to keep it in sync, and one missed update silently corrupts it. Computing on demand states the meaning directly and cannot drift. A reasonable exception: keep a derived structure when its source data is immutable and the derived result is immutable too — a transformation producing a new data structure is fine in that case.

**Mechanics:**

1. Find every place the variable is updated. If it's fed from more than one source, apply Split Variable first so each source can be handled separately.
2. Write a function that computes the same value from the source data.
3. Use Introduce Assertion to check, wherever the variable is read, that the stored value equals the computed one (Encapsulate Variable gives the assertion a home if needed).
4. Test — running with the assertion live validates the hypothesis that the calculation matches.
5. Change readers to call the calculation instead of the variable.
6. Test.
7. Remove the now-dead variable declaration and all its update code.

**Pitfalls:**

- Multi-source accumulators (e.g., an initial value plus later increments) fail the naive assertion; split out the purely-derived portion first and replace only that part with a query.

## Change Reference to Value

*Inverse of: Change Value to Reference*

```js
// before
retag(label) { this._tag.text = label; }        // mutates shared inner object
// after
retag(label) { this._tag = new Tag(label, this._tag.color); }
```

**Use when:** An inner object is treated as mutable-in-place but nobody actually needs to share it. Making it an immutable value object simplifies reasoning: you can hand copies around, use them in concurrent or distributed code, and never worry about them changing behind your back. Do NOT do this when several holders must see each other's updates — shared, updateable state genuinely requires a reference.

**Mechanics:**

1. Confirm the candidate class is immutable or can be made so.
2. Apply Remove Setting Method to each setter — move the data into constructor parameters, then convert each external "set a property" call into a full replacement with a newly constructed object.
3. Add value-based equality over the object's fields.

**Pitfalls:**

- Value semantics require value equality. Most languages have a designated override point (Java `equals`/`hashCode`, Ruby `==`/`hash`, Python `__eq__`/`__hash__`); when you override equality you almost always must override the hash method too, or hashed collections break. JavaScript has no such hook — write an explicit `equals(other)` method and call it deliberately.
- Test equality with two independently constructed instances holding the same field values; also cover non-equal values, other types, and null.

## Change Value to Reference

*Inverse of: Change Reference to Value*

```js
// before
this._author = new Author(row.authorId);        // fresh copy per book
// after
this._author = authorRegistry.acquire(row.authorId);  // one shared instance
```

**Use when:** Many records point at the same logical entity and each holds its own copy — fine while the entity never changes, but once you need to update it you must chase down every copy, and missing one leaves your data inconsistent. Switching to a single shared instance makes any update visible to all holders. If the entity is genuinely read-only, copies are usually acceptable; memory pressure from duplication is rarely the real motivation.

**Mechanics:**

1. Create a repository (lookup registry) for instances of the entity, if none exists — often one already does.
2. Make sure the host object's constructor can determine which instance it needs (typically an ID present in the input data).
3. Change each host constructor to fetch the shared instance from the repository instead of building its own. Test after each change.

**Pitfalls:**

- Decide the creation policy: either register-on-first-use, or pre-populate the repository and treat an unknown ID during load as an error.
- Reaching for a global repository couples constructors to global state — a small dose is tolerable, but pass the repository in as a parameter if the coupling worries you.

## Replace Magic Literal

*Formerly: Replace Magic Number with Symbolic Constant*

```js
// before
if (elapsedMs > 86400000) expire(session);
// after
const MS_PER_DAY = 86_400_000;
if (elapsedMs > MS_PER_DAY) expire(session);
```

**Use when:** A raw literal carries meaning a reader can only supply from memory — a physics constant, a sentinel string, a status code — especially when it recurs across the codebase. Name it after what it means. When the literal mostly appears in comparisons (`status === "X"`), a predicate function like `isActive(status)` often beats a named constant. Do NOT bother when the name adds nothing (`const ONE = 1`) or when the literal appears once inside a function whose context already explains it.

**Mechanics:**

1. Declare a constant set to the literal's value.
2. Find all occurrences of the literal.
3. For each occurrence, check that it actually carries the constant's meaning — the same raw value can mean different things in different places. Replace only the matching ones, testing as you go.
4. As a final check, change the constant's value and confirm the tests notice; if they do, the substitution is complete. (Not always feasible, but useful when it is.)

**Pitfalls:**

- Identical literal, different meaning: replacing every `60` with `SECONDS_PER_MINUTE` when some of them are a retry limit introduces a subtle lie. Verify intent at each site.
