# Unit Testing Essentials

## Contents
- File and package layout
- The `testing.T` API
- Setup and teardown
- Subtests
- Table-driven tests
- Edge-case checklist
- Parallel tests
- Coverage
- Benchmarks

## File and package layout

- Name test files `<source>_test.go` and put them next to the source. The `_test.go` suffix is required.
- Prefer the **external test package** `package foo_test` in the same directory. It is the one allowed exception to "one package per directory".
  - Tests see only the exported API, so they act like a real client.
  - Test-only imports stay out of the production package.
- Use an internal `package foo` test only to reach unexported code. Prefer redesign over that.
- Test function signature: `func TestXxx(t *testing.T)`. The character after `Test` must be uppercase.
- Create a module with `go mod init <path>`. Treat every package as a small API.

## The `testing.T` API

`testing` has no assertion functions. You compare values and report.

| Method | Effect | Use when |
|---|---|---|
| `t.Log` / `t.Logf` | Log only | Debug output (shown on failure or with `-v`) |
| `t.Error` / `t.Errorf` | Log + mark failed, continue | Independent checks |
| `t.Fatal` / `t.Fatalf` | Log + mark failed, stop this test | Later steps cannot run (unexpected `err`, nil pointer) |
| `t.Skip` / `t.Skipf` | Stop and mark skipped | Gated slow tests, missing environment |
| `t.Helper()` | Report failures at the caller's line | Every test helper |
| `t.Cleanup(f)` | Run `f` after the test and its subtests | Teardown from helpers |
| `t.TempDir()` | Auto-removed temp directory | File system tests |
| `t.Setenv(k, v)` | Set env var, restored after test | Config tests (not allowed with `t.Parallel`) |
| `t.Context()` | Context cancelled at test end (Go 1.24+) | Goroutines and requests started by the test |

Plain-`testing` example:

```go
func TestDeposit(t *testing.T) {
	// Arrange
	w := wallet.New(10)

	// Act
	got := w.Deposit(5)

	// Assert
	if want := 15; got != want {
		t.Errorf("Deposit(5) = %d, want %d", got, want)
	}
}
```

## Setup and teardown

Execution order: `init()` functions → `TestMain` setup → `m.Run()` (tests run, their cleanups fire) → `TestMain` teardown → exit.

```go
func TestMain(m *testing.M) {
	setup()
	code := m.Run()
	teardown() // os.Exit skips defers, so tear down before exit
	os.Exit(code)
}
```

- There is one `TestMain` per package. It wraps every test in the package.
- Use `TestMain` only for expensive, package-wide resources (a container, a DB pool).
- For per-test resources, write a helper that uses `t.Cleanup`:

```go
func newTestStore(t *testing.T) *store.Store {
	t.Helper()
	s, err := store.Open(t.TempDir())
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}
```

## Subtests

- `t.Run(name, func(t *testing.T) {...})` creates a child test with its own `*testing.T`.
- Put shared Arrange in the parent and one scenario in each child.
- A failing child fails the parent.
- Spaces in names become underscores: run one with `-run 'TestAdd/positive_input'`. Each `/`-separated level is its own regex.
- Inside the child, always use the child's `t`. Calling the parent's `t` reports failures on the wrong test.

## Table-driven tests

Recipe:

1. Stub the function signature.
2. Declare the case struct: inputs, `want`, `wantErr`. Use the unit's real parameter types.
3. Build the case collection. Start with the base case only.
4. Loop with `t.Run`.
5. Assert: check the error first, then `return`; else check the value.
6. Run and see it fail.
7. Implement the base case.
8. Add edge, boundary, and error cases one at a time.
9. Implement each one.

Rules:

- Prefer `map[string]struct{...}` keyed by case name. Use an anonymous struct unless tests share the case type.
- Build a fresh unit under test inside each subtest.
- Do not force cases with different setup or different mock behavior into one table. Use separate subtests, each with its own table if needed.
- Keep logic out of the table loop. One `if tc.wantErr != nil` branch is fine; more branches mean you need separate tests.

## Edge-case checklist

Write positive tests (valid input → expected result) **and** negative tests (invalid input → meaningful error, no panic).

| Kind | Meaning |
|---|---|
| Base | Normal, happy-path input |
| Edge | Extreme value of one parameter |
| Boundary | Values just either side of an edge or threshold |
| Corner | Several parameters at their extremes together |

By type:

- **string**: `""`, very long, Unicode and special characters, multiline.
- **numeric**: `0`, negative, type min and max (`math.MinInt8`, `math.MaxUint8`), overflow.
- **struct**: zero value `T{}`, nil pointer, partly initialized.
- **slice/map**: nil, empty, one element, duplicates, large.
- **external service**: error, 5xx, timeout, lost response. Make operations idempotent so retries are safe.

## Parallel tests

- Packages already run in parallel. Tests inside a package run one at a time unless they call `t.Parallel()`.
- In a table test, call `t.Parallel()` **inside each subtest**.
- `-parallel n` caps parallel tests inside one binary (default `GOMAXPROCS`). `-p n` caps packages tested at once.
- Parallel subtests must not share mutable state. Read-only sharing is fine.
- Loop variables:
  - `go 1.22`+ in `go.mod`: each iteration has its own variable. Do not write `tc := tc`; the `copyloopvar` linter flags it.
  - `go 1.21` or lower: copy before the closure, or every subtest sees the last case.
- `t.Setenv` and `t.Chdir` panic in parallel tests.
- Run parallel suites with `-race`.

## Coverage

```bash
go test -cover ./...
go test -coverprofile=c.out -covermode=atomic ./...
go tool cover -func=c.out    # per-function
go tool cover -html=c.out    # line-by-line in a browser
```

- Target about 80%. Above that, returns fall off.
- Cover every branch (`y != 0` and `y == 0`), boolean conditions, parameter ranges, and error paths.
- Low coverage often means a design problem: hidden dependencies, large functions.
- Well-covered code is not bug-free code.

## Benchmarks

```go
func BenchmarkParsePort(b *testing.B) {
	for b.Loop() { // Go 1.24+
		_, _ = netcfg.ParsePort("8080")
	}
}

// Before Go 1.24:
// for i := 0; i < b.N; i++ { ... }
```

```bash
go test -run '^$' -bench . -benchmem ./netcfg
```

- Output `BenchmarkParsePort-8  50000000  23 ns/op  0 B/op  0 allocs/op`. The `-8` is `GOMAXPROCS`.
- Local results are noisy. Compare runs with `benchstat` (`golang.org/x/perf/cmd/benchstat`), using `-count=10`.
- Use `b.Fatal`, not testify, in hot loops.
- A test checks correctness. A benchmark checks speed. Do not mix them.
