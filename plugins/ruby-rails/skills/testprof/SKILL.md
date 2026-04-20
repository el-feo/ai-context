---
name: testprof
description: Diagnose and fix slow RSpec test suites using TestProf and proven optimization techniques. Use this skill whenever the user mentions slow tests, test suite performance, RSpec speed, profiling specs, TestProf, TagProf, let_it_be, TPS profiler, or complains that their test suite takes too long. Also use it when the user sees high GC time in tests, wants to parallelize with test-queue, or asks which profiler to run against an RSpec suite. Prefer this skill over generic performance advice whenever RSpec is in the picture.
---

# TestProf: RSpec Performance Optimization

Expert guidance for diagnosing and fixing slow RSpec test suites. Based on field-tested techniques from Evil Martians' work reducing a 30,000-spec Rails suite from 4m30s to 2m (and targeting 1m30s with parallelization).

The core idea: slow test suites are rarely slow for one reason. They're slow for **a handful of fixable reasons, stacked**. This skill walks you through diagnosing which reasons apply, then fixing each one — in an order that avoids wasted effort.

## How to use this skill

When a user brings a slow RSpec suite, **investigate their actual codebase before prescribing anything**. A skill full of generic advice is worse than useless — the value is in mapping the general patterns onto their specific code. Follow this order:

1. **Characterize the problem** — ask for total runtime, example count, and whether it's "slow everywhere" or "slow in specific files." This determines which profiler to run first.
2. **Investigate concretely, don't speculate.** Before giving advice, actually:
   - Read `spec/spec_helper.rb` and `spec/rails_helper.rb` for suspicious requires (`rubocop/rspec/support`, SimpleCov config, global hooks).
   - Grep the `Gemfile` for the suspects: SimpleCov, blind_index, any encryption gem, retry gems (`retriable`, Faraday retry middleware).
   - For slow individual specs, read the service file being tested — grep for `sleep`, `retry`, `ObjectSpace`, `create_list(:...,` with large numbers.
   - Look at the factory definitions for the types involved. Association fan-out is a common cause.
   This is the difference between a suggestion list and a diagnosis. Always do the investigation first.
3. **Run the right diagnostic next** — see "Diagnostic decision tree" below. If Claude can't run the profiler (no shell access to the user's env), write the exact commands the user should run and explain how to interpret the output.
4. **Apply fixes in order of payoff** — coverage and GC issues often give the biggest single wins and require the least invasive changes, so check them before rewriting specs.
5. **Measure after each change** — keep the before/after numbers so you can tell what worked.

The four findings in `references/bottlenecks.md` cover the most common heavy hitters. Read that file when you're ready to dig into a specific bottleneck.

### A worked investigation looks like this

Bad (generic suggestion list):
> "Your service might be sleeping in tests. You could inject a delay parameter, or stub sleep, or use Retriable with base_interval: 0..."

Good (grounded in the user's code):
> "I read `app/services/your_service.rb` — the retry is hand-rolled at line 42 (`sleep(2 ** attempt)`), not delegated to a gem. So injection is the right fix, not gem config. Here's the diff..."

The second version took one `Read` call and one `Grep` but produced a fix the user can apply immediately. Always aim for the second version.

## Diagnostic decision tree

Use the symptoms the user describes to pick the first profiler. Don't try to run all of them — start with the one most likely to surface signal, then pivot based on what you learn.

| Symptom | First thing to run | What it tells you |
|---|---|---|
| "Slow everywhere, no obvious hotspot" | `TEST_STACK_PROF=1 bin/rspec` (StackProf) or Vernier | Global issues: gems loading heavy hooks, coverage, autoloading |
| "Specific files/groups are slow" | `TPS_PROF=20 TPS_PROF_MIN_EXAMPLES=5 bin/rspec` | Tests-per-second for each file; surfaces low-TPS groups |
| "GC time looks high" | `TEST_MEM_PROF=gc bin/rspec` | Per-spec GC overhead. Healthy is ~5%; investigate at 15%+ |
| "Want to know which spec *types* cost the most" | `TAG_PROF=type bin/rspec` (TagProf) | Aggregate time by tag (model, request, system, etc.) |
| "Specific slow spec, want a line-level view" | `RUBY_PROF=1 bin/rspec path/to/spec.rb` | Method-level hotspots inside one example |

**Rule of thumb**: if the user hasn't profiled yet, start with StackProf *and* a TPS run. Global issues and slow-file issues are usually independent problems.

## Quick install

TestProf v1.6+ has all the profilers referenced here:

```ruby
# Gemfile
group :test do
  gem "test-prof", "~> 1.6"
end
```

Most profilers activate via environment variables — no code changes needed. For `let_it_be`, `before_all`, and FactoryProf, add the relevant requires to `spec/spec_helper.rb` (see `references/testprof_features.md`).

## The four big wins

From a real 30k-spec suite, these accounted for the majority of the speedup. Any of them could apply to the user's suite. See `references/bottlenecks.md` for the full diagnostic steps and code for each.

1. **RuboCop `rubocop/rspec/support` causing GC bloat** — global hooks keep memory allocated across every spec. Replace with narrower requires. (~1 minute saved on the reference suite.)
2. **Coverage tracking overhead (15-20%)** — switch SimpleCov to `oneshot_line` mode. (~1 minute saved.)
3. **Encryption/blind_index using production parameters in tests** — override to `pbkdf2_sha256` with `cost: 1` in the test environment. (~30s saved.)
4. **Individual slow specs found via TPS** — patterns include ObjectSpace iteration, production retry backoffs, excessive record creation for boundary tests. Each fix is local but compound.

## When to reach for `let_it_be` vs `let`

`let_it_be` (from TestProf) memoizes across an entire describe block instead of per-example. For read-only records used across many examples, this is a massive win:

```ruby
# Before: creates a user for every example
let(:user) { create(:user) }

# After: creates once for the whole describe block
let_it_be(:user) { create(:user) }
```

Use `let_it_be` when the record doesn't need to be fresh per-example. If examples mutate it, either keep `let` or use `let_it_be(:user, reload: true)` / `refind: true`.

See `references/testprof_features.md` for the full set of TestProf primitives (`before_all`, `AnyFixture`, FactoryProf, EventProf, sample modes).

## Tests-per-second (TPS): the metric that matters

Total runtime hides the real problem. A file with 1,080 examples that runs in 2m50s is 6 TPS — terrible. A file with 5 examples that runs in 10s is 0.5 TPS — worse per-example, but maybe unavoidable.

TPS prioritizes files where **high runtime meets high example count**. That's where refactoring pays off most:

```bash
# Show the 20 slowest files with at least 5 examples
TPS_PROF=20 TPS_PROF_MIN_EXAMPLES=5 bin/rspec
```

When a file shows up in TPS, read `references/slow_spec_patterns.md` for the common root causes (ObjectSpace walks, sleep/retry delays, oversized fixtures).

## Preventing regressions

After optimizing, the suite will grow. To keep gains:

- **Enforce in review**: code review (human or AI) should flag `let` that could be `let_it_be`, tests that create hundreds of records for pagination/boundary checks, and reintroduction of `require "rubocop/rspec/support"`.
- **Track TPS over time**: the `test-queue` parallelizer plus periodic TPS runs will surface regressions.
- **CI budget**: pick a target runtime and fail CI when it slips.

## References

Read these when you need more depth on a specific topic:

- `references/bottlenecks.md` — the four major bottlenecks with full diagnosis steps, code, and expected impact
- `references/testprof_features.md` — complete TestProf v1.6 feature reference (`let_it_be`, `before_all`, profilers, `AnyFixture`, FactoryProf, EventProf)
- `references/slow_spec_patterns.md` — common root causes inside individual slow specs, with before/after code
- `references/diagnostic_scripts.md` — drop-in snippets: GC tracker, timing decorator, suite summary hook
