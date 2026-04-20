# Four Major RSpec Bottlenecks

These are the four findings from optimizing a 30,000-spec Rails suite. Each includes how to detect it, the fix, and the expected impact. Check them in order — they're ordered roughly by how common they are and how little invasive surgery each fix requires.

## 1. `rubocop/rspec/support` causing GC bloat

### How to detect

Run the memory profiler with GC mode:

```bash
TEST_MEM_PROF=gc bin/rspec
```

Healthy suites show GC overhead around 5%. If you see 15% or higher — or total GC time like 89,000ms across the suite — this is the likely cause.

The fingerprint: memory climbing and never releasing across the suite, with GC running more frequently as the suite progresses.

### Root cause

`require "rubocop/rspec/support"` integrates the full RuboCop plugin infrastructure globally for every example group. The source description of the problem is that loading all the RuboCop plugins this way **keeps memory allocated permanently across the suite** — not that specific hooks fire on every example. Every spec file, regardless of whether it tests a cop, pays the memory tax of having the entire RuboCop plugin graph loaded, which is what drives GC thrashing as the heap keeps growing and collecting.

Even specs that have nothing to do with RuboCop are running inside a heap inflated by cop classes, AST machinery, and plugin registries that were loaded at boot and never released.

### Fix

Replace the catch-all require with only what you actually use:

```ruby
# spec/spec_helper.rb — BEFORE
require "rubocop/rspec/support"

# spec/spec_helper.rb — AFTER
require "rubocop/rspec/cop_helper"
require "rubocop/rspec/expect_offense"

RSpec.configure do |config|
  config.include CopHelper, type: :rubocop
  # or narrower: only include in the specs that need it
end
```

If some specs need the full support, scope the include to `type: :rubocop` (or a tag) so it only affects those files.

### Expected impact

On the reference suite: **~1 minute saved** (4m35s → 3m30s), GC time dropped from 89s to 67s.

## 2. Coverage tracking overhead

### How to detect

Run the suite with and without `COVERAGE=1` (or whatever variable gates your SimpleCov). If removing coverage cuts 15-20% off the runtime, this is real.

### Root cause

Default SimpleCov tracks every line hit, every time. Each example triggers hundreds or thousands of line-coverage updates. You rarely need per-hit counts — you only need to know whether each line was executed at all.

### Fix

Switch SimpleCov to `oneshot_line` mode. It only records the first time each line is hit, then stops tracking that line, which removes almost all of the overhead:

```ruby
# spec/spec_helper.rb (or wherever SimpleCov.start lives)
SimpleCov.start "rails" do
  enable_coverage :oneshot_line
  primary_coverage :oneshot_line
end
```

`oneshot_line` requires a recent SimpleCov. If you're pinned to an older version, temporarily pull from GitHub:

```ruby
# Gemfile
gem "simplecov", github: "simplecov-ruby/simplecov", require: false, group: :test
```

### Caveat

`oneshot_line` gives you line-coverage data but not execution counts. If your workflow depends on "which test hit this line most often," keep standard mode. Most teams don't need that.

### Expected impact

On the reference suite: **~1 minute saved** (3m30s → 2m30s).

## 3. Encryption & blind_index using production parameters

### How to detect

Look for tests that create or save records with encrypted/blind-indexed fields. Profile a slow `create(:user)` or similar factory with StackProf — if time is spent in Argon2 or key-derivation functions, you've found it.

### Root cause

Gems like `blind_index` default to production-strength parameters (Argon2id with 3 iterations and 4MB memory, for example). These are appropriate for real user data but catastrophic during test setup, where you may create thousands of records per suite. `blind_index` in particular lacks a built-in test mode.

### Fix

Override the defaults in the test environment with a cheap algorithm:

```ruby
# spec/spec_helper.rb or spec/rails_helper.rb
if Rails.env.test?
  BlindIndex.default_options = {
    algorithm: :pbkdf2_sha256,
    cost: { iterations: 1 }
  }
end
```

If you're using `attr_encrypted`, `lockbox`, or Active Record encryption, do the equivalent: lowest-cost algorithm, minimum iterations. Security doesn't matter in fixture data.

Check every encryption gem in your Gemfile — any that takes a "cost" or "iterations" parameter is a candidate.

### Expected impact

On the reference suite: **~30 seconds** saved on factory-heavy runs.

## 4. Individual slow specs (found via TPS)

### How to detect

```bash
TPS_PROF=20 TPS_PROF_MIN_EXAMPLES=5 bin/rspec
```

This lists the files with the worst tests-per-second ratio. Start from the top.

### Root cause

Varies, but three patterns account for most of what you'll see. See `slow_spec_patterns.md` for each pattern's diagnosis and fix:

- **ObjectSpace iteration on every example** (common in mocking/stubbing helpers that walk all loaded classes)
- **Production retry/backoff logic with real sleeps**
- **Excessive record creation for boundary tests** (creating 600 records to test a limit of 500)

### Expected impact

Varies by file, but on the reference suite a single GraphQL REST controller spec went from 6 TPS to 27 TPS (2m50s → 40s). Individual wins compound — three or four fixes at this level often matches the size of wins #1 or #2.

## Putting it together

A realistic optimization session:

1. Run `TEST_MEM_PROF=gc` → check GC overhead. If high, apply fix #1.
2. Run once with and without coverage → if a big gap, apply fix #2.
3. Grep the Gemfile for encryption gems → apply fix #3 if any are present.
4. Run `TPS_PROF=20` → apply #4 to the top 3-5 files.
5. Re-measure. Decide whether to keep going or parallelize with `test-queue`.

Stop when the suite hits whatever runtime target the team agreed on, not when you run out of ideas. Premature optimization of individual specs past the first few rarely pays off compared to parallelization.
