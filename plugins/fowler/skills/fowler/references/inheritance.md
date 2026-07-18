# Dealing with Inheritance

Inheritance is powerful and easy to misuse — and misuse often only becomes visible in hindsight. This group covers three jobs: moving features up and down a hierarchy (Pull Up Method/Field/Constructor Body, Push Down Method/Field), adding and removing classes from a hierarchy (Replace Type Code with Subclasses, Remove Subclass, Extract Superclass, Collapse Hierarchy), and — when inheritance is in the wrong place or has become wrong over time — swapping it for delegation (Replace Subclass with Delegate, Replace Superclass with Delegate). The general stance: reach for inheritance first because it's simple, knowing the delegate refactorings are always available if it starts to rub.

## Table of contents

- [Pull Up Method](#pull-up-method)
- [Pull Up Field](#pull-up-field)
- [Pull Up Constructor Body](#pull-up-constructor-body)
- [Push Down Method](#push-down-method)
- [Push Down Field](#push-down-field)
- [Replace Type Code with Subclasses](#replace-type-code-with-subclasses)
- [Remove Subclass](#remove-subclass)
- [Extract Superclass](#extract-superclass)
- [Collapse Hierarchy](#collapse-hierarchy)
- [Replace Subclass with Delegate](#replace-subclass-with-delegate)
- [Replace Superclass with Delegate](#replace-superclass-with-delegate)

## Pull Up Method

*Inverse of: Push Down Method*

```js
// before
class PdfExport extends Export { get sizeLabel() { return `${this.bytes / 1024} KB`; } }
class CsvExport extends Export { get sizeLabel() { return `${this.bytes / 1024} KB`; } }
// after
class Export { get sizeLabel() { return `${this.bytes / 1024} KB`; } }
```

**Use when:** Two sibling classes carry methods that do the same thing — a change to one copy is easily missed in the other. If the bodies are similar but not identical, don't pull up yet: first study the differences (they often reveal untested behavior), then use Parameterize Function or renames to make the bodies match. If the methods share an overall flow but differ in details, consider Form Template Method instead.

**Mechanics:**
1. Inspect the methods; if they do the same thing but aren't textually identical, refactor until the bodies match.
2. Confirm everything the body calls or reads is reachable from the superclass. If it references subclass-only members, apply Pull Up Field / Pull Up Method to those first.
3. If signatures differ, use Change Function Declaration to unify them.
4. Create the method on the superclass by copying one body over. Run static checks.
5. Delete one subclass copy. Test.
6. Repeat deleting copies, testing each time, until none remain.

**Pitfalls:**
- The pulled-up body may call a method that exists only on subclasses. In a dynamic language, signal the contract with a stub that throws a "subclass responsibility" error; in a typed language, declare it abstract on the superclass. In Ruby, `raise NotImplementedError` in the parent plays the same role.

## Pull Up Field

*Inverse of: Push Down Field*

```js
// before
class EmailAlert extends Alert { /* declares recipient */ }
class SmsAlert   extends Alert { /* declares recipient */ }
// after
class Alert { /* declares recipient, accessible to subclasses */ }
```

**Use when:** Independently developed subclasses duplicate a field. The names may differ, so judge by how the fields are used, not what they're called. Pulling the field up removes the duplicate declaration and opens the door to pulling up the behavior that uses it. In dynamic languages where fields spring into existence on first assignment, this usually falls out of Pull Up Constructor Body instead.

**Mechanics:**
1. Inspect every use of the candidate fields to confirm they play the same role.
2. If names differ, use Rename Field to unify them.
3. Declare the field on the superclass, visible to subclasses (`protected` in typed languages).
4. Delete the subclass declarations. Test.

## Pull Up Constructor Body

```js
// before
class WireTransfer extends Payment {
  constructor(amount, iban) { super(); this._amount = amount; this._iban = iban; }
}
// after
class Payment { constructor(amount) { this._amount = amount; } }
class WireTransfer extends Payment {
  constructor(amount, iban) { super(amount); this._iban = iban; }
}
```

**Use when:** Sibling constructors repeat the same initialization. Constructors aren't ordinary methods — languages impose ordering rules (super call first, etc.) — so the plain Extract Function + Pull Up Method combo needs adapting. If it turns messy, switch to Replace Constructor with Factory Function instead.

**Mechanics:**
1. Give the superclass a constructor if it lacks one, and make sure subclass constructors call it.
2. Use Slide Statements to move the common statements immediately after the super call.
3. Delete the common code from each subclass and add it to the superclass constructor, passing any referenced constructor arguments through the super call.
4. Test.
5. Any common code that can't run at the start of construction (e.g., it depends on subclass-set state): Extract Function on it, then Pull Up Method, and call it at the end of each subclass constructor.

**Pitfalls:**
- Common code that reads fields assigned later in the subclass constructor cannot move before the super call — that's the case for step 5's extract-then-pull-up route.

## Push Down Method

*Inverse of: Pull Up Method*

```js
// before
class Report { get watermark() {...} }  // only DraftReport uses it
// after
class DraftReport extends Report { get watermark() {...} }
```

**Use when:** A superclass method matters only to one subclass (or a small minority). Moving it down states that clearly. Only safe when callers know they hold that specific subclass — if callers work through the superclass interface, use Replace Conditional with Polymorphism with a harmless default on the superclass instead.

**Mechanics:**
1. Copy the method down into each subclass that still uses it.
2. Remove it from the superclass. Test.
3. Remove it from each subclass that doesn't need it. Test.

## Push Down Field

*Inverse of: Pull Up Field*

```js
// before
class Sensor { /* declares calibrationOffset */ }  // only ThermalSensor uses it
// after
class ThermalSensor extends Sensor { /* declares calibrationOffset */ }
```

**Use when:** A field is used by only one subclass (or a few). Keeping it on the superclass makes every other subclass carry data it never touches.

**Mechanics:**
1. Declare the field in each subclass that needs it.
2. Remove it from the superclass. Test.
3. Remove it from any subclass that doesn't need it. Test.

## Replace Type Code with Subclasses

*Inverse of: Remove Subclass. Subsumes: Extract Subclass, Replace Type Code with State/Strategy*

```js
// before
function createShipment(dest, mode) { return new Shipment(dest, mode); }
// after
function createShipment(dest, mode) {
  switch (mode) {
    case "air":   return new AirShipment(dest);
    case "ground":return new GroundShipment(dest);
  }
}
```

**Use when:** A type code field (enum, string, symbol) drives conditional behavior in several functions, or some fields/methods are valid only for certain code values — subclasses let you apply Replace Conditional with Polymorphism and Push Down Field, and make the relationship explicit. Don't subclass the host directly if the type is mutable or if inheritance is already spent on another axis; instead apply Replace Primitive with Object to the type code and subclass that new type class (indirect inheritance). A plain type code that drives no behavior needs no subclasses at all.

**Mechanics:**
1. Self-encapsulate the type code field behind a getter.
2. Pick one code value. Create its subclass, overriding the getter to return that literal.
3. Add selector logic mapping code to subclass — in a factory function (via Replace Constructor with Factory Function) for direct inheritance; possibly in the constructor for indirect. Test.
4. Repeat per code value, testing after each.
5. Delete the now-unused type code field. Test.
6. Use Push Down Method and Replace Conditional with Polymorphism on methods that consult the type accessors; when nothing uses them, delete the accessors.

**Pitfalls:**
- After adding a subclass, deliberately break its override and confirm a test fails — otherwise you don't know the subclass is actually being constructed.
- The factory's switch replaces any hand-rolled type validation; keep a throwing default case so bad codes still fail loudly.
- Language adaptation: in Ruby, indirect inheritance often lands naturally as a family of type objects; in typed languages, a sealed hierarchy or sum type over the code value serves the same purpose.

## Remove Subclass

*Inverse of: Replace Type Code with Subclasses. Formerly: Replace Subclass with Fields*

```js
// before
class Coupon { get kind() { return "standard"; } }
class SeasonalCoupon extends Coupon { get kind() { return "seasonal"; } }
// after
class Coupon { get kind() { return this._kind; } }  // field set at creation
```

**Use when:** A subclass has withered to almost nothing — its variations moved elsewhere, or the anticipated features never arrived. A subclass that does too little costs more in comprehension than it earns; fold it into a superclass field. Before removing, check clients for subclass-dependent behavior worth moving into the hierarchy first — if there's real behavior, keep the subclass.

**Mechanics:**
1. Apply Replace Constructor with Factory Function to the subclass constructor; if clients pick the subclass from a data field, move that selection logic into the factory.
2. Wherever code type-tests against the subclass (`instanceof` etc.), Extract Function on the test and Move Function it to the superclass. Test after each change.
3. Add a field on the superclass representing the type.
4. Change methods that relied on the subclass to consult the new field.
5. Delete the subclass. Test.
6. For a group of subclasses, do the encapsulation steps (factory, type-test moves) for all of them first, then fold them in one at a time.

**Pitfalls:**
- `instanceof` checks scattered through clients are the main hazard — encapsulate every one before you start folding, or the removal breaks callers.

## Extract Superclass

```js
// before
class Invoice { get reference() {...} get total() {...} }
class Quote   { get reference() {...} get total() {...} }
// after
class Document { get reference() {...} get total() {...} }
class Invoice extends Document {...}
class Quote extends Document {...}
```

**Use when:** Two classes do similar things — pull the shared data and behavior into a common parent. Inheritance here doesn't need to be planned from a real-world taxonomy; it's something you notice during evolution. The alternative is Extract Class (delegation); Extract Superclass is usually simpler to do first, since Replace Superclass with Delegate remains available if it goes sour.

**Mechanics:**
1. Create an empty superclass and make both classes extend it (adjusting constructors with Change Function Declaration if needed). Test.
2. One element at a time, apply Pull Up Constructor Body, Pull Up Method, and Pull Up Field to move common pieces up.
3. Examine remaining subclass methods for common fragments; use Extract Function then Pull Up Method on those.
4. Review clients — consider pointing them at the superclass interface.

**Pitfalls:**
- Near-duplicate methods often hide behind different names; unify names and intent with Change Function Declaration before pulling up, and confirm the renamed methods really mean the same thing.

## Collapse Hierarchy

```js
// before
class Widget {...}
class BasicWidget extends Widget {...}
// after
class Widget {...}
```

**Use when:** After enough pushing and pulling of features, a class and its parent are no longer different enough to justify two classes. Merge them. Skip this if the split still carries meaning you expect to grow back.

**Mechanics:**
1. Choose which class to remove — keep the name that makes most sense going forward (pick arbitrarily if neither wins).
2. Use Pull Up Field, Push Down Field, Pull Up Method, and Push Down Method to gather everything into the survivor.
3. Repoint all references from the removed class to the survivor.
4. Delete the empty class. Test.

## Replace Subclass with Delegate

```js
// before
class Message { get retries() { return 1; } }
class UrgentMessage extends Message { get retries() { return 5; } }
// after
class Message {
  get retries() { return this._urgentDelegate ? this._urgentDelegate.retries : 1; }
}
class UrgentDelegate { get retries() { return 5; } }
```

**Use when:** Inheritance is a card you can play once — if a second axis of variation appears, or an object needs to change category at runtime (a plain message becoming urgent), the subclass has to go. Delegation supports multiple variations and looser coupling at the cost of dispatch logic and back-references. If inheritance is working fine and neither pressure exists, leave it alone — this refactoring alone rarely makes the code prettier. Gang of Four readers can view it as moving to the State or Strategy pattern.

**Mechanics:**
1. If constructors have many callers, apply Replace Constructor with Factory Function.
2. Create an empty delegate class; its constructor takes the subclass-specific data plus, usually, a back-reference to the host.
3. Add a delegate field to the superclass.
4. Initialize the delegate where the subclass is created (factory, or constructor if it can reliably decide).
5. Pick a subclass method; Move Function it to the delegate, routing superclass-data access through the back-reference. Keep the delegating stub for now.
6. If the method has outside callers, move the delegating code into the superclass guarded by a delegate-presence check; otherwise Remove Dead Code. Test.
7. Repeat until the subclass is empty.
8. Repoint subclass-constructor callers to the superclass constructor. Test.
9. Remove Dead Code on the subclass.

**Pitfalls:**
- Subclass methods that call `super` can't naively call back into the host (infinite recursion). Either Extract Function to separate the base calculation from the dispatch, or recast the delegate method as an extension taking the base result as a parameter.
- With several subclasses/delegates, guard clauses and back-reference wiring start duplicating — apply Extract Superclass to the delegates; with a default delegate always present, the host's guards disappear. Composition and inheritance work best mixed, not opposed.
- Never dispatch with an explicit class check on the delegate type; give every delegate the default behavior via the delegate superclass instead.

## Replace Superclass with Delegate

*Formerly: Replace Inheritance with Delegation*

```js
// before
class RecentFiles extends FileList {...}
// after
class RecentFiles {
  constructor() { this._files = new FileList(); }
  add(f) { this._files.add(f); }  // forwarders for what's actually used
}
```

**Use when:** The subclass inherited only to reuse the parent's implementation, and much of the parent's interface makes no sense on the child — or the child isn't truly a kind of the parent (e.g., confusing a type with an instance of it). Inheritance is legitimate only when every superclass method applies to the subclass and every subclass instance is a valid superclass instance. When either fails, hold the former parent as a field and forward the operations you need — the forwarders are dull to write but hard to get wrong. Don't avoid inheritance wholesale: use it first where the semantics hold, and apply this refactoring when it becomes a problem.

**Mechanics:**
1. Add a field in the subclass referencing a fresh instance of the superclass.
2. For each superclass element used, write a forwarding function to the delegate. Test after each consistent group (getter/setter pairs must move together before testing).
3. When every used element has a forwarder, remove the inheritance link. Test.

**Pitfalls:**
- If each instance of the host should share the delegate with other hosts (many physical copies of one record), follow up with Change Value to Reference — which may require splitting identity fields the child was borrowing from the parent.
- Language adaptation: in Ruby, the same smell appears with inherited or mixed-in modules whose methods don't fit; in typed languages, keep the shared contract by extracting an interface the host still implements.
