# Core Principles — Deep Reference

Read this when a principle is central to your response. Each section gives the principle, *why* it
serves changeability, how to spot violations, and language-agnostic examples (Ruby-leading, with the
idea transferred to JS/TS where the mechanism differs).

## Table of contents
1. Single Responsibility
2. Dependency management & injection
3. Message-centric design
4. Tell, Don't Ask
5. Law of Demeter
6. Duck typing (polymorphism without inheritance)
7. Conditionals → polymorphism
8. SOLID in plain language
9. The wrong abstraction

---

## 1. Single Responsibility

**Principle:** A class does the smallest possible useful thing. The test: state its responsibility in
one sentence. If the sentence needs "and" or "or", you have more than one responsibility.

**Why it serves changeability:** A class with one reason to change is touched by one kind of
requirement. Many responsibilities = many reasons to change = every edit risks breaking unrelated behavior.

**How to spot violations:** Methods that don't use the object's own data (Feature Envy). Instance
variables that cluster into groups used by different methods. A name with "Manager", "Processor", "Handler",
"Util" — vague names that absorb anything.

**Example — a Gear that knows too much:**
```ruby
# Mixing gear math with the idea of a wheel/tire
class Gear
  def initialize(chainring, cog, rim, tire); ...; end
  def ratio;        chainring / cog.to_f; end
  def gear_inches;  ratio * (rim + (tire * 2)); end   # <- wheel knowledge leaking in
end
```
The `gear_inches` calculation depends on wheel structure. Extract a `Wheel`:
```ruby
class Gear
  def initialize(chainring, cog, wheel)
    @chainring, @cog, @wheel = chainring, cog, wheel
  end
  def ratio;       chainring / cog.to_f; end
  def gear_inches; ratio * wheel.diameter; end        # tell the wheel to compute its own
end

class Wheel
  def initialize(rim, tire); @rim, @tire = rim, tire; end
  def diameter; rim + (tire * 2); end
end
```
Now each class has one reason to change.

---

## 2. Dependency management & injection

**Principle:** Inject dependencies rather than hard-coding them. Isolate every point where your code
names a concrete external thing.

**Why:** Each hard-coded dependency is a place that breaks when the other thing changes. "Depend on
things that change less often than you do."

**Three escalating techniques:**
1. **Inject the dependency** — pass the collaborator in instead of constructing it inside.
2. **Isolate the instantiation** — if you must construct it, do so in one obvious place (a single method), not scattered.
3. **Isolate vulnerable messages** — wrap an external call you depend on behind your own method, so a change to their API touches one line of yours.

```ruby
# Hard-coded dependency: Gear is welded to Wheel
class Gear
  def gear_inches; ratio * Wheel.new(rim, tire).diameter; end  # knows Wheel's name AND its constructor
end

# Injected: Gear depends only on "something that responds to .diameter" (a duck type)
class Gear
  def initialize(chainring, cog, wheel); @wheel = wheel; ...; end
  def gear_inches; ratio * wheel.diameter; end
end
```
**JS/TS:** same idea — constructor injection or passing collaborators as arguments; depend on an
interface/shape, not a concrete `import`ed class.

---

## 3. Message-centric design

**Principle:** Design the *conversation* between objects before the objects. Ask "what message does the
sender want to send?" and let that define the receiver's interface.

**Why:** Object-centric design ("what attributes does a User have?") produces data bags with behavior
bolted on. Message-centric design ("what does the checkout *ask* of things?") produces objects defined
by what they *do* — which is what makes them swappable.

**Technique:** Sketch the sequence of messages first (even literally, as a sequence diagram in prose).
The public methods that fall out of "what callers need to say" become the interface. Everything else is private.

A useful reframing question: instead of "I need a `TripCoordinator` that has these attributes," ask
"I want to send `prepare` to something — what's the smallest interface that satisfies that?"

---

## 4. Tell, Don't Ask

**Principle:** Tell an object what you want done; don't ask about its state and then decide for it.

```ruby
# Ask: the caller pokes at internals and makes the decision
if user.subscription.status == :active && user.subscription.tier == :pro
  grant_access
end

# Tell: the object decides about its own data
user.grant_access_if_entitled  # or: if user.entitled? then ... (query is fine; deciding-for-it is the smell)
```
The deep version: queries are fine, but reaching *through* an object to interrogate its internals and
then act on its behalf both violates encapsulation and creates a Law of Demeter chain.

---

## 5. Law of Demeter

**Principle:** Only send messages to: yourself, your own parameters, objects you create, and your direct
collaborators. Avoid chains like `customer.address.street.zip`.

**Why:** A chain hard-codes knowledge of a whole object graph's structure. Any change to the shape of
that graph breaks the chain. The chain is a dependency on *everything along it*.

**Cures:**
- **Delegate:** add `customer.zip` that internally does `address.zip`.
- **Better — ask the right object:** often the chain signals you're talking to the wrong object entirely. Push the behavior to where the data lives ("tell, don't ask").

Note the nuance Sandi draws: `a.b.c.d` is only a smell when the dots traverse *structure*. A fluent
interface that returns the same conceptual object (`query.where(...).limit(...)`) is not a Demeter violation.

---

## 6. Duck typing — polymorphism without inheritance

**Principle:** An object's type is defined by what it *does*, not what class it *is*. If it responds to
the messages a role requires, it can play that role.

**Why it's the heart of OO flexibility:** Duck types let unrelated objects be interchangeable based on
shared behavior. This is how you eliminate type-checking conditionals and make code open to new variants.

**Spotting a missing duck type:** code that checks `class`/`kind_of?`/`instanceof`/`typeof` and branches,
or a `case` on a category. Each branch is a duck quacking to get out.

```ruby
# Missing duck type — Trip interrogates classes
def prepare(preparers)
  preparers.each do |p|
    case p
    when Mechanic        then p.prepare_bicycles(bikes)
    when TripCoordinator then p.buy_food(customers)
    when Driver          then p.gas_up(vehicle)
    end
  end
end

# Duck type: everyone who prepares a trip responds to `prepare_trip`
def prepare(preparers)
  preparers.each { |p| p.prepare_trip(self) }
end
```
**JS/TS:** structural typing *is* duck typing made explicit — define an interface for the role and let
any conforming object satisfy it. TypeScript rewards this: type the role, not the class.

---

## 7. Conditionals on type → polymorphism

When a conditional switches on *what something is* (its type, kind, status-as-category), the branches
are usually objects waiting to be born. Replace the conditional by sending a message to an object that
knows its own behavior. The full worked trajectory (99 Bottles: `case` statement → `BottleNumber`
subclasses → factory) lives in `references/refactoring.md`. The principle: **the sender shouldn't know
the receiver's type; it should just send the message and trust the receiver to do the right thing.**

Caveat consistent with "the wrong abstraction": don't reach for polymorphism on the *first* conditional.
Wait until the shape is clear and the duplication is real.

---

## 8. SOLID in plain language

- **S — Single Responsibility:** one reason to change. (§1)
- **O — Open/Closed:** open to new behavior by *adding* code, closed to *editing* existing code. The
  practical move (99 Bottles): when a new requirement doesn't fit, first refactor until the code is
  *open* to it (adding code suffices), then add the code. Never refactor and add behavior in one step.
- **L — Liskov Substitution:** subtypes must be honestly substitutable for their supertypes — they must
  "be what they promise." A subtype that returns a different shape, or forces callers to test its type,
  violates Liskov. Generalizes to duck types: every object playing a role must return trustworthy,
  role-conformant objects.
- **I — Interface Segregation:** don't force an object to depend on methods it doesn't use. Small,
  role-specific interfaces beat fat general ones.
- **D — Dependency Inversion:** depend on abstractions, not concretions. (§2)

---

## 9. The wrong abstraction (the most important meta-principle)

Sandi's central warning. The lifecycle of the wrong abstraction:
1. A programmer sees duplication and abstracts it, building a parameterized abstraction.
2. Requirements change; the abstraction is *almost* right, so the next programmer passes a flag/param to
   bend it to the new case.
3. Repeat. The abstraction accretes parameters and conditionals until it's an unmaintainable knot that
   no one understands and everyone fears.

**The cure runs backward:** when an abstraction is fighting you, *re-introduce duplication* — inline the
abstraction back into its callers, then let the *right* abstraction re-emerge from the now-visible
concrete cases. "Prefer duplication over the wrong abstraction." Duplication is far cheaper to fix than
a bad abstraction.

This is *why* every other principle here is applied patiently: design is the art of waiting for the
right abstraction to reveal itself, then capturing it — and being willing to undo it when it proves wrong.
