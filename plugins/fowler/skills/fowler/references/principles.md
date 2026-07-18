# Principles in Refactoring

The discipline behind every catalog entry. These principles come from Martin
Fowler's *Refactoring* (2nd edition) and govern when, why, and how to refactor.
Apply them before reaching for any specific technique: the catalog tells you
what moves exist; this file tells you when a move is legitimate.

## What refactoring is (and isn't)

Refactoring has a precise meaning, and the precision matters:

- **As a noun**: a specific, named change to a program's internal structure
  that makes it easier to understand and cheaper to modify, without altering
  its observable behavior (e.g., Extract Function, Rename Variable).
- **As a verb**: restructuring a codebase by chaining many such
  behavior-preserving changes together.

The defining property is the sequence of small steps. Each step is tiny and
keeps the program working, so a large structural change is achieved as a chain
of safe transformations — and you can stop at any point with working code.
The code never spends more than a few minutes in a broken state.

Two tests for whether an activity qualifies:

- If the code is broken for hours or days mid-change, it is not refactoring —
  it is restructuring (a broader, riskier activity that includes rewrites and
  big-bang reorganizations).
- If observable behavior changes — features added, bugs fixed, output altered
  in ways a user would notice — it is not refactoring. (Fixing a latent bug no
  one has ever observed is acceptable; changing behavior someone depends on
  is not.)

"Observable behavior" is deliberately loose: internal details like the call
stack or module-internal interfaces may change, but nothing a user of the
system cares about should.

The many-tiny-steps style looks slow to newcomers. It is faster in practice
because the steps compose cleanly and eliminate debugging time.

## The two hats

At any moment during development you wear exactly one of two hats:

- **Adding function**: introduce new capability. Add tests for the new
  behavior; do not restructure existing code.
- **Refactoring**: restructure existing code. Do not add capability; do not
  add tests (except to fill a gap you just noticed); change tests only when
  an interface change forces it.

You will swap hats often — sometimes every few minutes. That is healthy. What
is not healthy is wearing both at once: a diff that simultaneously
restructures and changes behavior cannot be verified as either a safe
refactoring or a correct feature. Swap deliberately, and know which hat you
have on at all times.

## Why refactor

Refactoring is not a moral exercise in "clean code." The justification is
economic — every benefit below cashes out as speed:

- **It improves design.** Codebases decay as short-term changes accumulate;
  structure erodes and duplication creeps in. Regular refactoring reverses
  the decay, and eliminating duplication ensures each fact lives in one place.
- **It makes code easier to understand.** Code has two audiences: the machine
  and the next programmer (usually future you). Refactoring moves your
  hard-won understanding out of your head and into the code, where it lasts.
- **It helps find bugs.** Clarifying structure forces you to nail down
  assumptions, and nailed-down assumptions expose defects that were hiding in
  the confusion.
- **It makes programming faster.** This is the point the others feed into.
  Teams on poorly structured code slow down over time; teams on well-factored
  code speed up, because existing parts compose into new features. Good
  internal structure exists to make future change cheaper — that is the whole
  argument, and the one to lead with when justifying the work.

## When to refactor

- **The rule of three.** First time, just write the code. Second time you do
  something similar, wince but duplicate it. Third time, refactor to remove
  the duplication.
- **Preparatory refactoring.** The best moment is right before adding a
  feature or fixing a bug. If the change is awkward in the current structure,
  first reshape the code so the change becomes simple — in Kent Beck's words,
  "make the change easy (warning: this may be hard), then make the easy change."
- **Comprehension refactoring.** Whenever you have to puzzle out what code
  does, capture the understanding by renaming, extracting, or restructuring
  so the next reader doesn't repeat the effort. Clarifying small things often
  reveals design insights you could not have seen otherwise.
- **Litter-pickup refactoring.** When you pass through code and notice it
  doing its job badly, improve it a little. If the fix is quick, do it now;
  if not, note it and come back. Leave the code a bit better than you found
  it — over many passes the mess disappears without ever breaking the build.
- **Everyday work, not scheduled cleanup.** All of the above are
  opportunistic: refactoring belongs inside feature work and bug fixing, not
  in a separate "refactoring sprint." Dedicated cleanup phases are an
  occasional corrective for neglect, not the normal mode. Good code needs
  refactoring too — yesterday's correct tradeoffs stop fitting today's
  requirements.
- **Long-term refactoring.** Large efforts (swapping a library, untangling a
  dependency mess) should still be done gradually. Agree on a direction, and
  have everyone nudge code toward it whenever they touch the affected area.
  Introducing an abstraction that can front both the old and new
  implementation (branch by abstraction) lets the system keep working
  throughout.

## When NOT to refactor

- **Ugly code you never touch.** If a messy module works and you neither need
  to modify it nor understand it, leave it alone. Treat it as an opaque API.
  Refactoring pays off only when the code is in your path.
- **When a rewrite is genuinely cheaper.** Sometimes code is easier to replace
  than to reshape. This is a judgment call, often only resolvable by
  attempting a bit of refactoring to gauge the difficulty — but rewrite is a
  legitimate answer.
- **When the feature at hand is tiny and the refactoring is huge.** It can be
  right to make a small change in awkward code and defer the large
  restructuring. That said, under-refactoring is far more common than
  over-refactoring.

## The safety net

- **Self-testing code is the precondition.** A refactoring session needs a
  test suite that runs quickly and fails loudly on mistakes. Without it, you
  cannot distinguish "restructured" from "broken."
- **Untested code: build the net first.** Before refactoring code with no
  coverage, write characterization tests that pin down the current behavior
  (including behavior at boundaries — empty collections, zeros, negatives,
  blanks). Make each new test fail at least once — temporarily inject a fault
  — to prove it actually exercises the code. Focus tests on risky, complex
  areas rather than trivial accessors.
- **Run the tests after every step.** Each catalog step is followed by a test
  run. When a test fails, the fault lies in the few lines you just changed —
  find it there, or revert to the last green state. Never refactor on a red
  bar.
- **Scale the step size to the risk.** When tests are slow, coverage is thin,
  or the code is tricky, take smaller steps. Comfortable and green? Larger
  strides are fine — but back out and go smaller the moment something breaks.

## Refactoring and performance

Write clear, well-factored code first; make it fast later, and only where
measurement says it matters. Most programs spend most of their time in a
small fraction of the code, so scattering micro-optimizations everywhere
wastes effort and wrecks clarity. Instead: build for clarity, then run a
profiler, find the actual hot spots, and tune those — in small steps, testing
and re-profiling after each, backing out changes that don't help.

Well-factored code makes this easier twice over: development goes faster
(buying time for tuning), and small, well-named units give the profiler finer
granularity and give you clearer options. A refactoring may slow the code
momentarily; the tunable structure it produces wins overall. And never guess
at hot spots — measurement almost always contradicts intuition.

## Practical guidance for Claude

Applying this discipline in an agentic session:

- **Declare your hat.** Before touching code, state whether you are adding
  behavior or refactoring. If a task needs both, sequence them: refactor
  first (tests stay green), then add the feature — or vice versa — as
  separate phases, ideally separate commits.
- **One catalog step per edit.** Make each mechanical step (extract this
  function, rename that variable, inline this temp) its own edit rather than
  batching a whole redesign into one sweeping change.
- **Test between steps.** Run the suite after each step. If it fails, stop —
  fix or revert that step before proceeding. Do not stack changes on a red
  bar.
- **Prefer many small diffs over one big one.** A chain of tiny, individually
  verified changes is easier to review, easier to bisect, and safe to abandon
  midway. If asked for a "big cleanup," decompose it into a sequence of named
  refactorings and execute them one at a time.
- **No tests? Say so first.** If the target code lacks coverage, tell the
  user plainly that refactoring without tests is unsafe, and offer to write
  characterization tests before restructuring. Only proceed untested if the
  user explicitly accepts the risk — and then restrict yourself to the
  smallest, most mechanical transformations available.
- **Keep the economics in view.** Recommend refactoring where it makes the
  next change cheaper; skip it for code no one needs to touch. When
  explaining the work, justify it in terms of speed of future change, not
  code aesthetics.
