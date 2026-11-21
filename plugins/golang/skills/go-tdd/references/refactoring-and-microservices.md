# Refactoring Under Tests, and Testing Microservices

## Contents
- Refactoring with tests as a safety net
- Changing interfaces and dependencies
- Splitting a monolith
- Performance testing and profiling
- Contract testing with Pact
- Production resilience: circuit breakers

## Refactoring with tests as a safety net

- **Refactoring** changes how code works with no visible change to callers. **Redesign** changes behavior. Never mix them in one commit.
- Loop: make one small change → keep it compiling → run the suite → green: commit; red: revise or revert.
- Never share a change on red. Enforce with CI.
- Change tests as little as possible during a refactor. Large test edits weaken the safety net.
- Name tests after **behavior**, not types, so a rename does not touch them. Rename the `_test.go` file along with its source file.
- Pay technical debt "little and often" alongside feature work.

What each layer catches:

| Layer | Catches |
|---|---|
| Unit | Breakage inside the package |
| Integration | Broken seams and API contracts between components |
| E2E | User-facing regressions |
| Benchmarks | Performance regressions |

How each technique affects tests:

| Technique | Test impact |
|---|---|
| Extract function | Tests rarely change |
| Inline | Tests rarely change, unless the inlined function had its own tests |
| Simplify conditionals, parameters, signatures | Tests likely change |
| New abstraction (interface) | Tests and mocks change |

Tools for mechanical changes: IDE rename via gopls, `gopls rename -w file.go:#offset NewName`, `gofmt -r 'old -> new' -w .`.

## Changing interfaces and dependencies

"The compiler is your guide." Tests are the first consumer of your API, so they break first.

1. Change the implementation signature.
2. Update its tests.
3. Follow compiler errors to every consumer interface and caller.
4. Regenerate mocks (`mockery` or `mockgen`).
5. Fix the tests the compiler flags.
6. Run the full suite, including integration tests.

Replace message-string error checks with custom error types or sentinels while you refactor (see [mocking-and-assertions.md](mocking-and-assertions.md)).

## Splitting a monolith

1. **Define boundaries.** For each service: its domain and models, upstream dependencies, downstream dependencies and storage, and the API it exposes.
2. **Couple loosely.**
   - One data store per service. No shared database.
   - Asynchronous messaging (queues, event bus) where possible.
   - A circuit breaker with a fallback on every remote call.
   - Backward-compatible API changes only.
   - Request tracing and monitoring.
3. **Test the integration points.** After a split, the seams carry the most risk. Write one contract per consumer→provider edge.
4. **Design and test graceful degradation**: what each service does when each dependency is down.

## Performance testing and profiling

Non-functional test types: load, stress, volume, spike and scalability, failover, configuration.

Agree thresholds with stakeholders before writing tests. Reasonable starting defaults:

| Metric | Threshold |
|---|---|
| Average latency | < 500 ms |
| Peak latency | < 1 s |
| Error rate | < 5% |
| CPU and memory | < 70% |

Benchmark a running service:

```go
func BenchmarkListWidgets(b *testing.B) {
	url := os.Getenv("SHOP_BASE_URL") + "/widgets"
	for b.Loop() {
		res, err := http.Get(url)
		if err != nil {
			b.Fatal(err)
		}
		io.Copy(io.Discard, res.Body) // drain and close, or connections leak
		res.Body.Close()
	}
}
```

```bash
go test -run '^$' -bench ListWidgets -benchmem -cpuprofile cpu.out ./perf
go tool pprof -http=:8080 cpu.out        # or: top10, list Fn, web
```

- Profiling the benchmark process shows client overhead. To find hot spots in the app, profile the **server**.
- Expose pprof only behind a flag or on an internal port:

```go
import _ "net/http/pprof" // registers on http.DefaultServeMux

if os.Getenv("DEBUG") != "" {
	go http.ListenAndServe("localhost:6060", nil)
}
```

Capture under load: `go tool pprof "http://localhost:6060/debug/pprof/profile?seconds=10"`. Profiles: `cpu`, `heap`, `goroutine`, `block`, `mutex`, `threadcreate`.

Load tools: k6, `vegeta` (`github.com/tsenart/vegeta`), `hey`, JMeter, Gatling. Run small performance checks often in CI to see trends per commit.

## Contract testing with Pact

Why: integration tests against real services are slow and complex. Tests against mocks can pass while the real services disagree. Consumer-driven contracts let each side verify independently.

- **Consumer**: sends the request. **Provider**: answers it. **Pact**: the request plus the expected response.
- Flow:
  1. The consumer test runs real client code against the Pact mock server. Pact writes `pacts/<consumer>-<provider>.json`.
  2. The provider verifier replays the pact against the **real** provider.
  3. Both sides must pass.
- Generate contracts with tooling. Never write them by hand.
- Share pacts through a Pact Broker and gate deploys with `can-i-deploy`.
- Gate contract tests like integration tests (tag or env var).

Use **pact-go v2** (Rust core, needs CGO). v1 (`pact-go/dsl`, Ruby tools) is outdated.

```bash
go install github.com/pact-foundation/pact-go/v2@latest
pact-go -l DEBUG install
```

Consumer:

```go
mock, err := consumer.NewV2Pact(consumer.MockHTTPProviderConfig{
	Consumer: "OrderSvc",
	Provider: "InventorySvc",
})
require.NoError(t, err)

err = mock.AddInteraction().
	Given("widget w1 exists").
	UponReceiving("a request for widget w1").
	WithRequest(http.MethodGet, "/widgets/w1").
	WillRespondWith(http.StatusOK, func(b *consumer.V2ResponseBuilder) {
		b.JSONBody(matchers.Like(map[string]any{"id": "w1", "stock": 3}))
	}).
	ExecuteTest(t, func(cfg consumer.MockServerConfig) error {
		client := inventory.NewClient(fmt.Sprintf("http://%s:%d", cfg.Host, cfg.Port))
		_, err := client.Get("w1") // exercise the REAL client code
		return err
	})
require.NoError(t, err)
```

Provider:

```go
err := provider.NewVerifier().VerifyProvider(t, provider.VerifyRequest{
	ProviderBaseURL: "http://localhost:8080",
	PactFiles:       []string{"../pacts/OrderSvc-InventorySvc.json"},
	StateHandlers: models.StateHandlers{
		"widget w1 exists": seedWidget,
	},
})
require.NoError(t, err)
```

Pitfalls:

- `matchers.Like` matches type only. Use exact values or `matchers.Regex` where the value matters.
- A consumer test that calls `http.Do` directly instead of the real client protects nothing.

## Production resilience: circuit breakers

States: **closed** (calls pass) → too many failures → **open** (fail fast) → after a timeout → **half-open** (probe) → success → closed.

`github.com/afex/hystrix-go` is unmaintained. Use `github.com/sony/gobreaker/v2`:

```go
cb := gobreaker.NewCircuitBreaker[*Stock](gobreaker.Settings{
	Name:    "inventory",
	Timeout: 5 * time.Second,
	ReadyToTrip: func(c gobreaker.Counts) bool {
		return c.ConsecutiveFailures >= 3
	},
})

stock, err := cb.Execute(func() (*Stock, error) { return client.Get(ctx, sku) })
if errors.Is(err, gobreaker.ErrOpenState) {
	stock = defaultStock(sku) // every remote call needs a defined fallback
}
```

TDD the breaker: inject a fake dependency that fails N times. Assert that call N+1 fails fast with `gobreaker.ErrOpenState` without reaching the fake, and that the fallback value is returned.

Other production practices: structured logs with `log/slog`, metrics and tracing with OpenTelemetry, canary and blue-green deploys.
