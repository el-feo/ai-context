# TestProf v1.6 Feature Reference

TestProf is a collection of profilers and optimization primitives for RSpec (and Minitest) suites. Most features activate via environment variables — you rarely need to touch code to run a profile.

## Profilers

### TPS_PROF — Tests-per-second profiler (v1.6+)

The most useful starting point for suites with clear hotspots.

```bash
# Show 20 slowest files with at least 5 examples each
TPS_PROF=20 TPS_PROF_MIN_EXAMPLES=5 bin/rspec
```

TPS = total examples in the group / total runtime. Low TPS + many examples = high payoff target.

### StackProf / Vernier — sampling profilers

Best for "slow everywhere" situations where no single file dominates.

```bash
TEST_STACK_PROF=1 bin/rspec           # sampling across the whole suite
TEST_STACK_PROF=boot bin/rspec        # profile only the boot phase
```

Output is a `.dump` file you view with `stackprof --text tmp/test_stack_prof.dump` or load in Speedscope.

Vernier is a newer alternative, often more accurate for short-lived methods:

```bash
TEST_VERNIER=1 bin/rspec
```

### TEST_MEM_PROF — Memory / GC profiler

```bash
TEST_MEM_PROF=1 bin/rspec             # allocations
TEST_MEM_PROF=gc bin/rspec            # GC timing per-example
```

Healthy GC overhead is ~5% of total runtime. 15% or higher is a red flag — usually means something is allocating heavily and not releasing (see `bottlenecks.md` #1).

### TAG_PROF — Aggregate by tag

Groups time by metadata tag. Useful for "are my system specs eating all the time?"

```bash
TAG_PROF=type bin/rspec
```

### FACTORY_PROF — Factory usage profiler

```bash
FPROF=1 bin/rspec                     # shows which factories are called most
FPROF=flamegraph bin/rspec            # factory call flamegraph
```

If you see the same factory called thousands of times with slight variations, it's a candidate for `let_it_be` or `AnyFixture`.

### EVENT_PROF — Profile a specific event

Profiles SQL queries, template rendering, or any `ActiveSupport::Notifications` event:

```bash
EVENT_PROF=sql.active_record bin/rspec
EVENT_PROF=factory.create bin/rspec
```

### RUBY_PROF — Per-example deep profile

Heavy but detailed. Use when you have one specific slow spec:

```bash
RUBY_PROF=1 bin/rspec spec/models/slow_thing_spec.rb
```

### Sample mode

Run a random fraction of the suite for quick iteration:

```bash
SAMPLE=100 bin/rspec                  # random sample of 100 examples
SAMPLE_GROUPS=10 bin/rspec            # random sample of 10 describe blocks
```

## Optimization primitives

### `let_it_be` — per-describe-block memoization

The highest-leverage TestProf primitive. Memoizes a record across all examples in a describe block instead of re-creating per-example.

```ruby
# spec/rails_helper.rb
require "test_prof/recipes/rspec/let_it_be"

# in a spec
RSpec.describe Post do
  let_it_be(:author) { create(:user) }  # created once
  let_it_be(:post)   { create(:post, author: author) }

  it "has an author" do
    expect(post.author).to eq(author)
  end
end
```

**Options for mutation:**
- `let_it_be(:user, reload: true)` — reload from DB before each example
- `let_it_be(:user, refind: true)` — re-fetch from DB before each example (gives a fresh instance)
- `let_it_be(:user, freeze: true)` — freeze the record to catch accidental mutation

**When NOT to use**: when each example genuinely needs a fresh, unfrozen record (rare for read-only paths). If in doubt, start with `let_it_be` + `reload: true` and drop the reload once you're sure nothing mutates.

### `before_all` — shared setup block

Like `before(:all)` but transaction-wrapped, so changes roll back after the describe block:

```ruby
require "test_prof/recipes/rspec/before_all"

RSpec.describe Organization do
  before_all do
    @org = create(:organization)
    create_list(:user, 5, organization: @org)
  end
end
```

Use this when the setup involves multiple records that aren't naturally expressed as `let_it_be` bindings.

### `AnyFixture` — cached fixture-like setup

For expensive, reusable setup (seeding lookup tables, creating tenants) that should run once per test run rather than per describe:

```ruby
require "test_prof/recipes/rspec/any_fixture"

RSpec.configure do |config|
  config.before(:suite) do
    TestProf::AnyFixture.register(:default_plans) do
      create_list(:plan, 3)
    end
  end
end
```

### FactoryDefault

Eliminates redundant factory calls by making "default" associations:

```ruby
require "test_prof/recipes/rspec/factory_default"

RSpec.describe Post do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:post) { create(:post) }  # automatically uses the default user
end
```

## Preventing regressions

TestProf v1.6 ships recommendations for AI/human PR review. Reviewers should flag:

- `let(:x) { create(:y) }` where `x` isn't mutated → should be `let_it_be`
- Creating > 100 records when testing a limit or pagination → make the limit configurable
- `require "rubocop/rspec/support"` reappearing in `spec_helper.rb`
- New specs with loops that call `create` inside the loop body
