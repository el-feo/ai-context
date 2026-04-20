# Common Slow-Spec Patterns

When TPS_PROF surfaces a slow file, the root cause is usually one of these three patterns. Each includes how to recognize it, the fix, and the real-world impact from the reference suite.

## Pattern 1: ObjectSpace iteration on every example

### How to recognize

Runtime scales with the size of the app rather than the size of the test. Common fingerprints in a StackProf output: `ObjectSpace.each_object`, `Module#descendants`, or `Class#subclasses` showing up in hot frames. Often lives in mocking or stubbing helpers that try to "find all classes that respond to X."

### Root cause

Something like this runs in a `before(:each)`:

```ruby
before do
  ObjectSpace.each_object(Class) do |klass|
    next unless klass < SomeBase
    stub_method_on(klass)
  end
end
```

A mature Rails app has tens of thousands of loaded modules. Walking all of them on every example — 1,000 examples × 50,000 modules = 50M operations that produce nothing new after the first pass.

### Fix

Run the expensive work once per group using `before(:all)` with module prepending:

```ruby
# Before: per-example ObjectSpace walk
before do
  ObjectSpace.each_object(Class) { |k| stub_on(k) if k < Base }
end

# After: compute the target classes once, prepend a patch module once
before(:all) do
  target_classes = ObjectSpace.each_object(Class).select { |k| k < Base }
  patch = Module.new do
    def the_method(*)
      # test-mode behavior
    end
  end
  target_classes.each { |k| k.prepend(patch) }
end
```

### Reference impact

GraphQL REST controller spec: 1,080 examples, 2m49s → 40s. **6 TPS to 27 TPS.**

## Pattern 2: Production retry/backoff with real sleeps

### How to recognize

Run `RUBY_PROF=1 bin/rspec path/to/spec.rb` on the slow spec. If 15-20%+ of time is spent in `Kernel#sleep`, this is it.

Also show up as long wall-clock time but low CPU time — the process is sleeping, not computing.

### Root cause

Production code with retry logic calls `sleep(backoff)` between attempts. In production that's correct behavior. In tests, you either stub the remote call to fail (and then wait through multiple real backoffs), or you exercise the retry path deliberately:

```ruby
# lib/discovery_service.rb
def fetch_with_retries(url, attempts: 3)
  attempts.times do |i|
    return http.get(url)
  rescue TransientError
    sleep(2 ** i)  # 1s, 2s, 4s… in production
  end
end
```

### Fix

Make the retry delay injectable (default to production value, pass in a small value in tests):

```ruby
# lib/discovery_service.rb
def fetch_with_retries(url, attempts: 3, base_delay: 1.0)
  attempts.times do |i|
    return http.get(url)
  rescue TransientError
    sleep(base_delay * (2 ** i))
  end
end

# spec/services/discovery_service_spec.rb
subject { DiscoveryService.new(base_delay: 0.01) }
```

Don't stub `Kernel#sleep` globally — it has non-obvious effects. Injection is cleaner and makes the test self-documenting.

### Reference impact

Discovery service specs went from 0.28-0.51 TPS to acceptable ranges; ~20% of per-example time recovered.

## Pattern 3: Excessive record creation for boundary tests

### How to recognize

A file creates hundreds or thousands of records to verify behavior at a limit. Shared setup time dominates individual example time. Look for `create_list(:thing, 600)` or `500.times { create(:thing) }`.

### Root cause

The test is verifying behavior at a boundary (MAX_LIMIT = 500) by creating enough records to cross the boundary. But the production constant is hardcoded, forcing tests to match.

```ruby
# app/services/fraud_manager.rb
MAX_LIMIT = 500

def recent_transactions
  Transaction.order(created_at: :desc).limit(MAX_LIMIT)
end

# spec/services/fraud_manager_spec.rb
before { create_list(:transaction, 600) }  # 16s of setup per example

it "returns at most 500 records" do
  expect(subject.recent_transactions.size).to eq(500)
end
```

### Fix

Make the limit injectable or class-level configurable, then test with small numbers:

```ruby
# app/services/fraud_manager.rb
MAX_LIMIT = 500

def initialize(max_limit: MAX_LIMIT)
  @max_limit = max_limit
end

def recent_transactions
  Transaction.order(created_at: :desc).limit(@max_limit)
end

# spec
subject { FraudManager.new(max_limit: 2) }
before { create_list(:transaction, 3) }

it "returns at most the limit" do
  expect(subject.recent_transactions.size).to eq(2)
end
```

Now you're testing the same behavior (the limit is respected) with 3 records instead of 600. The constant still guards production; the behavior is verified independently.

### Reference impact

Fraud Manager spec: shared setup went from 16.34s to under a second. File TPS from 1.09 to well above 10.

## A quick mental check

When you look at a slow spec, ask:

1. Is there anything in setup (`before`, factory cascades, `ObjectSpace` walks) that runs per example but doesn't need to? → use `before_all` / `let_it_be` / move to a helper that runs once.
2. Is real time being spent waiting (sleep, network)? → make the wait injectable or stub the waiting call, not the side effects.
3. Is the test creating more data than needed to exercise the behavior? → refactor the code under test to accept configurable thresholds, then test with minimal data.

In that order. It's almost always one of the three.
