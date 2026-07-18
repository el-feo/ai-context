# Bad Smells in Code

Smells are surface symptoms suggesting a refactoring may pay off — not rule violations. There is no metric that says "too long" or "too many"; the smell is a prompt for judgment. When diagnosing code, name the smell, weigh whether the structure is actually raising the cost of change, then reach for the refactorings listed as cures.

## Quick reference

| Smell | Curing refactorings |
| --- | --- |
| Mysterious Name | Change Function Declaration, Rename Variable, Rename Field |
| Duplicated Code | Extract Function, Slide Statements, Pull Up Method |
| Long Function | Extract Function, Replace Temp with Query, Introduce Parameter Object, Preserve Whole Object, Replace Function with Command, Decompose Conditional, Replace Conditional with Polymorphism, Split Loop |
| Long Parameter List | Replace Parameter with Query, Preserve Whole Object, Introduce Parameter Object, Remove Flag Argument, Combine Functions into Class |
| Global Data | Encapsulate Variable |
| Mutable Data | Encapsulate Variable, Split Variable, Slide Statements, Extract Function, Separate Query from Modifier, Remove Setting Method, Replace Derived Variable with Query, Combine Functions into Class, Combine Functions into Transform, Change Reference to Value |
| Divergent Change | Split Phase, Move Function, Extract Function, Extract Class |
| Shotgun Surgery | Move Function, Move Field, Combine Functions into Class, Combine Functions into Transform, Split Phase, Inline Function, Inline Class |
| Feature Envy | Move Function, Extract Function |
| Data Clumps | Extract Class, Introduce Parameter Object, Preserve Whole Object |
| Primitive Obsession | Replace Primitive with Object, Replace Type Code with Subclasses, Replace Conditional with Polymorphism, Extract Class, Introduce Parameter Object |
| Repeated Switches | Replace Conditional with Polymorphism |
| Loops | Replace Loop with Pipeline |
| Lazy Element | Inline Function, Inline Class, Collapse Hierarchy |
| Speculative Generality | Collapse Hierarchy, Inline Function, Inline Class, Change Function Declaration, Remove Dead Code |
| Temporary Field | Extract Class, Move Function, Introduce Special Case |
| Message Chains | Hide Delegate, Extract Function, Move Function |
| Middle Man | Remove Middle Man, Inline Function, Replace Superclass with Delegate, Replace Subclass with Delegate |
| Insider Trading | Move Function, Move Field, Hide Delegate, Replace Subclass with Delegate, Replace Superclass with Delegate |
| Large Class | Extract Class, Extract Superclass, Replace Type Code with Subclasses |
| Alternative Classes with Different Interfaces | Change Function Declaration, Move Function, Extract Superclass |
| Data Class | Encapsulate Record, Remove Setting Method, Move Function, Extract Function |
| Refused Bequest | Push Down Method, Push Down Field, Replace Subclass with Delegate, Replace Superclass with Delegate |
| Comments | Extract Function, Change Function Declaration, Introduce Assertion |

## Mysterious Name

**Looks like:** You have to read a function's body, a variable's usages, or a field's assignments to figure out what it represents. Names like `data2`, `process`, `flag`, or abbreviations only the original author decodes.

**Why it hurts:** Every future reader pays a decoding tax; misleading names actively cause bugs.

**Cure:** Change Function Declaration to rename a function, Rename Variable, Rename Field. If no good name will come, treat that as evidence of a deeper design problem worth untangling first.

## Duplicated Code

**Looks like:** The same statement structure appears in two or more places — identical expressions in sibling methods, near-identical blocks that differ only in a value or two, parallel logic in subclasses of one parent.

**Why it hurts:** Each copy must be read to check whether it really is the same, and every change must be hunted down in all copies — miss one and you have a bug.

**Cure:** Extract Function when the copies are in the same class; Slide Statements first when the copies are similar-but-interleaved, to line them up for extraction; Pull Up Method when duplicates live in subclasses of a common parent.

## Long Function

**Looks like:** A function you must scroll through, with commented "sections", nests of conditionals and loops, and a crowd of temps and parameters. The reliable tell is semantic distance: the body explains *how* while nothing states *what*.

**Why it hurts:** Understanding requires simulating the whole body in your head; nothing inside can be reused or overridden independently.

**Cure:** Extract Function handles 99% of cases — pull out any block that deserves a comment and name it after its intent. When temps block extraction, use Replace Temp with Query; when parameters block it, Introduce Parameter Object or Preserve Whole Object; if it's still tangled, Replace Function with Command. For conditionals, Decompose Conditional; for the same switch repeated, Replace Conditional with Polymorphism; for a loop doing two jobs, Split Loop then extract each.

## Long Parameter List

**Looks like:** Signatures with many arguments, callers passing values one parameter could derive from another, or a boolean that changes which behavior runs.

**Why it hurts:** Callers must marshal and order many values; adding capability means threading yet another argument through every call site.

**Cure:** Replace Parameter with Query when one argument is derivable from another; Preserve Whole Object instead of unpacking a structure into pieces; Introduce Parameter Object for values that travel together; Remove Flag Argument for behavior-selecting booleans; Combine Functions into Class when several functions share the same parameters — the shared values become fields.

## Global Data

**Looks like:** Global variables, class-level (static) variables, or singletons that any code anywhere can read and write.

**Why it hurts:** Any part of the program can mutate it with no trace of who did, producing action-at-a-distance bugs that are brutal to localize. Immutable globals are far less dangerous; mutable ones scale in pain with quantity.

**Cure:** Encapsulate Variable — always the first move. Wrap access in functions so you can see and control every touch, then narrow the variable's scope into a class or module.

## Mutable Data

**Looks like:** Variables reassigned for different purposes, setters called from many places, functions that both answer questions and change state, fields storing values that could be computed on demand.

**Why it hurts:** An update in one place breaks an assumption elsewhere, often only under rare conditions — the classic hard-to-reproduce bug. Risk grows with the variable's scope.

**Cure:** Encapsulate Variable to funnel updates through narrow functions; Split Variable when one variable holds different things over time; Slide Statements and Extract Function to isolate side-effect-free logic from updating code; Separate Query from Modifier in APIs; Remove Setting Method early and often; Replace Derived Variable with Query for anything computable; Combine Functions into Class or Combine Functions into Transform to shrink the update surface; Change Reference to Value to swap whole structures instead of mutating in place.

## Divergent Change

**Looks like:** One module edited for unrelated reasons — "these functions change whenever we add a database, those change whenever we add a product type." Multiple change axes crossing one file.

**Why it hurts:** Every change forces you to understand contexts that have nothing to do with it, and edits for one concern risk breaking another.

**Cure:** Split Phase when the concerns form a natural sequence with a data structure handed between them; otherwise create separate modules and use Move Function to divide the work. Use Extract Function first if single functions mix both concerns, and Extract Class when the module is a class.

## Shotgun Surgery

**Looks like:** The inverse of Divergent Change: one conceptual change requires small edits scattered across many classes or files, and you find them by grepping.

**Why it hurts:** Scattered edits are easy to miss; a forgotten site ships as a bug.

**Cure:** Move Function and Move Field to gather the changing pieces into one module. Combine Functions into Class when the functions share data; Combine Functions into Transform when they enrich a data structure; Split Phase when they feed a downstream consumer. Don't fear Inline Function or Inline Class as a deliberate intermediate step — pull the scattered logic into one big lump, then re-extract along better lines.

## Feature Envy

**Looks like:** A function that talks to another module's data more than its own — for example, calling half-a-dozen getters on one foreign object to compute a value.

**Why it hurts:** Behavior and the data it depends on change together; keeping them apart means every change touches two modules.

**Cure:** Move Function to put the function with the data it envies. When only part of the function is envious, Extract Function on that fragment first, then Move Function. If it uses several modules' data, place it with the module owning most of the data. (Patterns like Strategy and Visitor deliberately violate this to fight divergent change — the rule is "put together what changes together.")

## Data Clumps

**Looks like:** The same three or four data items traveling together everywhere — as fields in several classes and as parameters through many signatures. Test: delete one of the values; if the rest stop making sense, an object wants to exist.

**Why it hurts:** Every signature and class carries the whole caravan, and the clump's meaning stays implicit.

**Cure:** Extract Class where the clump appears as fields (a class, not a bare record — it attracts behavior later); then Introduce Parameter Object or Preserve Whole Object to shrink the signatures. Worth it whenever the object replaces two or more values.

## Primitive Obsession

**Looks like:** Domain concepts represented as raw ints, floats, and strings — money as a plain number, phone numbers as strings ("stringly typed"), ranges as paired comparisons like `a > lower && a < upper`, unit-less physical quantities.

**Why it hurts:** Validation, formatting, and arithmetic rules get reimplemented (inconsistently) at every use site instead of living in one type.

**Cure:** Replace Primitive with Object for the concept itself. When the primitive is a type code steering conditionals, Replace Type Code with Subclasses then Replace Conditional with Polymorphism. When primitives clump together, Extract Class and Introduce Parameter Object.

## Repeated Switches

**Looks like:** The same switch/case or if/else cascade over the same discriminator appearing in multiple places.

**Why it hurts:** Adding one new case means finding and updating every copy of the switch.

**Cure:** Replace Conditional with Polymorphism. A single switch is fine these days — it's the *repetition* that earns the refactoring.

## Loops

**Looks like:** Index or iterator loops accumulating results, filtering, or transforming collections in languages with first-class functions available.

**Why it hurts:** The loop body hides what's included and what's done to it; a pipeline of filter/map/reduce states both directly.

**Cure:** Replace Loop with Pipeline.

## Lazy Element

**Looks like:** A function whose name says exactly what its one-line body says, or a class that amounts to a single simple function — structure that never grew into its planned role or shrank after refactoring.

**Why it hurts:** Indirection with no payoff; each layer is one more place to look for nothing.

**Cure:** Inline Function or Inline Class. Use Collapse Hierarchy when the empty element is a parent or child in an inheritance chain.

## Speculative Generality

**Looks like:** Hooks, abstract classes, delegation layers, and unused parameters added "because we'll need it someday" — often detectable because the only callers are tests.

**Why it hurts:** Machinery that isn't earning its keep still costs comprehension and maintenance on every read.

**Cure:** Collapse Hierarchy for do-little abstract classes; Inline Function and Inline Class for needless delegation; Change Function Declaration to drop unused parameters; Remove Dead Code (deleting the test first) when only tests exercise the element.

## Temporary Field

**Looks like:** A class with a field that only holds a meaningful value in certain circumstances or during certain operations, sitting null or stale the rest of the time.

**Why it hurts:** Readers expect an object to use all its fields; hunting for when and why a sometimes-field matters wastes real time.

**Cure:** Extract Class to give the field (and its friends) a home, Move Function to relocate the code that touches it, and Introduce Special Case to eliminate the conditionals that guard the "field isn't valid" situation.

## Message Chains

**Looks like:** A client navigating object to object to object — a run of getters like `a.getB().getC().getD()`, or the same chain spelled as a sequence of temps.

**Why it hurts:** The client is coupled to the whole navigation structure; changing any intermediate relationship breaks every chained caller.

**Cure:** Hide Delegate at some point in the chain — but applying it everywhere breeds middle men, so often the better move is to see what the final result is used for, Extract Function on that usage, and Move Function to push it down the chain closer to the data.

## Middle Man

**Looks like:** A class whose interface is mostly pass-through — half or more of its methods simply delegate to one other object.

**Why it hurts:** Delegation past the point of useful encapsulation adds a hop with no value; changes ripple through the forwarding layer.

**Cure:** Remove Middle Man so clients talk to the real object; Inline Function when only a few forwarding methods exist. If the middle man carries some genuine behavior of its own, fold it in with Replace Superclass with Delegate or Replace Subclass with Delegate.

## Insider Trading

**Looks like:** Two modules constantly exchanging each other's internal data, or a subclass exploiting knowledge of its parent's internals.

**Why it hurts:** Back-channel coupling means neither module can change without consulting the other.

**Cure:** Move Function and Move Field to cut the chatter; create a third module for genuinely shared interests, or Hide Delegate to route the traffic through an intermediary. For inheritance-based collusion, Replace Subclass with Delegate or Replace Superclass with Delegate.

## Large Class

**Looks like:** Too many fields — especially subsets sharing a prefix or suffix, or fields used only some of the time — plus long methods with overlapping code. Clients typically use only a slice of the class's features.

**Why it hurts:** Many-field classes breed duplicated code, and every change must navigate everything else the class does.

**Cure:** Extract Class around field groups that belong together (a common prefix like `deposit*` marks a component); Extract Superclass or Replace Type Code with Subclasses when the split follows an inheritance line. Let client usage patterns pick the seams — each distinct feature subset used by clients is a candidate class.

## Alternative Classes with Different Interfaces

**Looks like:** Two classes doing substitutable jobs but exposing different method names and signatures, so callers can't swap one for the other.

**Why it hurts:** Substitution — the point of having alternative classes — is impossible until the protocols match.

**Cure:** Change Function Declaration to align the signatures; Move Function to shift behavior until the protocols truly match; Extract Superclass if the alignment reveals duplication.

## Data Class

**Looks like:** A class holding fields plus getters and setters and nothing else, while other classes reach in and manipulate its data in detail.

**Why it hurts:** The behavior belongs with the data; scattered manipulation means the data's rules live everywhere except in the class.

**Cure:** Encapsulate Record if fields are public; Remove Setting Method for fields that shouldn't change; then find where clients use the getters and apply Move Function to bring that behavior home, with Extract Function first when only part of a client function belongs. Exception: immutable result records — such as the structure between the stages of a Split Phase — are legitimately behavior-free and need no encapsulation.

## Refused Bequest

**Looks like:** A subclass that uses only a fraction of what it inherits, ignoring the rest of the parent's methods and data.

**Why it hurts:** Usually only mildly — nine times out of ten it's too faint to act on. It turns serious when the subclass reuses implementation but refuses to support the superclass's *interface*.

**Cure:** When it's causing real confusion, Push Down Method and Push Down Field into a new sibling so the parent keeps only what's shared. When the interface itself is refused, don't rearrange the hierarchy — leave it via Replace Subclass with Delegate or Replace Superclass with Delegate.

## Comments

**Looks like:** Thick comment blankets over a section of code — comments used as deodorant for one of the other smells rather than as genuine documentation.

**Why it hurts:** The comment compensates for code that can't explain itself, and it rots as the code changes.

**Cure:** If a comment explains what a block does, Extract Function and name the function after the comment; if an already-extracted function still needs explaining, Change Function Declaration to rename it; if the comment states required system state, Introduce Assertion. Comments explaining *why*, or flagging uncertainty, are welcome — refactor first, and keep the ones that survive.
