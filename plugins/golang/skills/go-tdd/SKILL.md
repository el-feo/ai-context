---
name: go-tdd
description: Test-driven development in Go with the standard testing package, testify, and mockery. Covers the red-green-refactor loop, table-driven tests and subtests, mocking via consumer-side interfaces, integration and end-to-end tests (httptest, Docker, Godog, Ginkgo), refactoring under tests, contract testing with Pact, concurrency and the race detector, fuzzing, property-based testing, and testing generic code. Use when writing or fixing Go tests, doing TDD in Go, designing testable Go code, choosing between unit/integration/E2E tests, or asked about go test flags, coverage, benchmarks, mocks, t.Run, t.Parallel, -race, or fuzz tests.
---

# Go Test-Driven Development

Guidance for writing Go code test-first. Based on *Test-Driven Development in Go* by Adelina Simion (Packt, 2023), updated for current Go (1.22+) and current tooling. The book targets Go 1.19, so this skill corrects outdated or wrong advice where it matters.

## Before you write any test

1. **Read `go.mod`.** The `go` directive changes what is idiomatic:
   - `go 1.22`+: loop variables are per-iteration. Do **not** add `tc := tc` copies. Range-over-int (`for i := range n`) works.
   - `go 1.21` or lower: you **must** copy the loop variable before a `t.Parallel()` subtest closure.
   - `go 1.24`+: use `for b.Loop()` in benchmarks and `t.Context()` for test-scoped contexts.
   - `go 1.25`+: `testing/synctest` is available for time- and goroutine-dependent code.
2. **Match the project's existing test style.** Look for testify, gomock (`go.uber.org/mock`), Ginkgo, or plain `testing` before adding a new library.
3. **Find the existing mock generator** (`.mockery.yml`, `//go:generate` lines). Regenerate mocks the same way after you change an interface.

## The TDD loop

Red, green, refactor. Write no production code without a failing test that needs it.

1. Create `foo_test.go` next to `foo.go`, in package `foo_test` (external test package).
2. Stub the unit under test so it compiles. Return zero values (`return nil, nil`) so no case passes by accident.
3. Write the simplest Arrange–Act–Assert scenario.
4. Run it. **See it fail** for the expected reason. A test you never saw fail may pass falsely.
5. Write just enough code to pass.
6. Run it. See it pass.
7. Refactor test and code. Optimize only here, once behavior is green.
8. Re-run the suite. Add the next case (edge, boundary, error). Repeat.

Add one case at a time. Run the full package suite after every step: `go test ./pkg/...`.

## Default rules

- **Test behavior, not implementation.** Assert on outputs and observable effects through the exported API. Internal assertions break on every refactor.
- **Keep tests independent.** Each test builds its own unit under test from a known state. No shared mutable fixtures. No order dependence.
- **Prefer `package foo_test`.** Use an internal `package foo` test only when you must reach unexported code, and treat that as a design smell.
- **Name tests after the unit**: `TestParsePort`, with scenarios as subtests: `t.Run("above max", ...)`. Failure messages use Go wording: `got %v, want %v`.
- **Use table-driven tests** for one unit with many inputs. Use separate subtests when cases need different setup or different mock behavior.
- **Depend on small interfaces declared by the consumer.** Inject them through a constructor (`NewService(dep)`). Mock only direct dependencies.
- **Check errors by identity or type, not by message**: `require.ErrorIs(t, err, ErrNotFound)`, `require.ErrorAs(t, err, &target)`.
- **`require` for preconditions, `assert` for the rest.** Argument order is `(t, want, got)`.
- **Mark helpers with `t.Helper()`.** Use `t.Cleanup`, `t.TempDir`, `t.Setenv` instead of hand-rolled teardown.
- **Never `time.Sleep` to wait for a goroutine.** Synchronize on a channel or `WaitGroup`, and bound waits with `select` + timeout.
- **Run `go test -race ./...` in CI.**
- **Aim for about 80% coverage.** Do not write tests only to raise the number.

## Canonical test shape

```go
package netcfg_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"example.com/app/netcfg"
)

func TestParsePort(t *testing.T) {
	tests := map[string]struct {
		in      string
		want    int
		wantErr error
	}{
		"typical":   {in: "8080", want: 8080},
		"min":       {in: "1", want: 1},
		"max":       {in: "65535", want: 65535},
		"zero":      {in: "0", wantErr: netcfg.ErrOutOfRange},
		"above max": {in: "65536", wantErr: netcfg.ErrOutOfRange},
		"empty":     {in: "", wantErr: netcfg.ErrEmpty},
	}
	for name, tc := range tests { // go 1.22+: no tc := tc
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			got, err := netcfg.ParsePort(tc.in)

			if tc.wantErr != nil {
				require.ErrorIs(t, err, tc.wantErr)
				return
			}
			require.NoError(t, err)
			assert.Equal(t, tc.want, got)
		})
	}
}
```

A `map` table runs cases in random order, which exposes hidden order dependence. Use a slice with a `name` field when order matters for readability.

## Choose the right test type

| Need | Test type | Reference |
|---|---|---|
| One function or type, in memory, fast | Unit test, table-driven | [unit-testing.md](references/unit-testing.md) |
| Isolate a dependency | Mock via consumer interface | [mocking-and-assertions.md](references/mocking-and-assertions.md) |
| Component + real DB or HTTP seam | Integration test, gated | [integration-and-e2e.md](references/integration-and-e2e.md) |
| Full user journey across the deployed app | E2E (Godog / Docker) | [integration-and-e2e.md](references/integration-and-e2e.md) |
| Change structure without changing behavior | Refactor under green tests | [refactoring-and-microservices.md](references/refactoring-and-microservices.md) |
| Two services must agree on an API | Contract test (Pact) | [refactoring-and-microservices.md](references/refactoring-and-microservices.md) |
| Latency, throughput, allocations | Benchmark + pprof | [refactoring-and-microservices.md](references/refactoring-and-microservices.md) |
| Goroutines, channels, locks | Concurrency tests + `-race` | [concurrency.md](references/concurrency.md) |
| Unknown or hostile input | Fuzz / property test | [fuzzing-and-properties.md](references/fuzzing-and-properties.md) |
| Generic functions or types | Generic table tests | [generics.md](references/generics.md) |

Keep the pyramid shape: many unit tests, fewer integration tests, fewest E2E tests. Push variations down to the cheapest level that can catch them.

## Command cheat sheet

```bash
go test ./...                                  # all packages (results cached)
go test -count=1 ./...                         # bypass the cache
go test -v -run 'TestParsePort/above_max' ./netcfg   # one subtest (spaces -> _)
go test -short ./...                           # skip tests that check testing.Short()
go test -race ./...                            # race detector
go test -cover ./...                           # coverage %
go test -coverprofile=c.out ./... && go tool cover -func=c.out   # per-function
go tool cover -html=c.out                      # browse coverage
go test -run '^$' -bench . -benchmem ./pkg     # benchmarks only
go test -run '^$' -fuzz '^FuzzParse$' -fuzztime 30s ./pkg      # fuzz one target
go vet ./...                                   # copylocks, printf, loopclosure, ...
```

The book prints flags with en dashes (`–race`). Always type a single ASCII hyphen.

## Known errors in the source book

Do not copy these patterns from the book or its companion code:

- `assert.Equal(t, errors.New("x"), err)` passes only by accident. Use sentinel errors with `ErrorIs`, or `EqualError` when the message is the contract.
- A closure that calls the **parent** `t` from inside `t.Run` reports failures on the wrong test. Always use the subtest's own `t`.
- Subtests do **not** share one `*testing.T`. Each gets its own.
- A nil channel blocks **forever**, not "until initialized".
- `-parallel n` limits parallel tests inside one test binary. `-p n` limits packages run at once.
- `if err := db.First(&x); err != nil` checks a `*gorm.DB`, which is never nil. Check `.Error`.
- `fmt.Errorf(msgVar)` with a non-constant format fails `go vet`. Use `errors.New`.
- Outdated libraries: `golang/mock` → `go.uber.org/mock`; pact-go v1 → `pact-go/v2`; `hystrix-go` → `sony/gobreaker`; Ginkgo v1 → `ginkgo/v2`; `golang.org/x/exp/constraints` → `cmp.Ordered`.
