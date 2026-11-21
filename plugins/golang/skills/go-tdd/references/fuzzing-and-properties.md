# Fuzzing and Property-Based Testing

## Contents
- Write robust code first
- Native fuzzing
- Fuzz commands and corpus
- Property-based testing
- Fuzzing HTTP handlers

## Write robust code first

- No hidden globals. Pass every dependency through the signature.
- Validate every value you did not create. That includes user input **and responses from other services**. These untrusted inputs are your fuzz arguments.
- Return an `error` for bad input (unknown enum value, nil map). Decide nil and empty behavior explicitly, and test it.
- Replace magic strings with typed enums (`type SortDir int` + `iota`). End each `switch` with a `default:` that returns an error.
- Keep `gofmt`, `go vet`, clear names, and doc comments on exported identifiers.

## Native fuzzing

Go 1.18+. Rules:

- In a `_test.go` file: `func FuzzXxx(f *testing.F)`.
- Seed the corpus with `f.Add(...)`. Argument count, types, and order must match the fuzz function's parameters after `t`.
- Call `f.Fuzz(func(t *testing.T, ...) {...})` exactly once.
- Allowed types: `string`, `[]byte`, all `int*` and `uint*` (incl. `rune`, `byte`), `float32`, `float64`, `bool`.
- The fuzz body must be **fast and deterministic**. Do not keep mutable state between iterations; build fresh inputs inside the body.
- Assert **properties**, not exact outputs: no panic, round-trip, invariants.

```go
func FuzzParseQuantity(f *testing.F) {
	for _, s := range []string{"1", "0", "-3", "", "9999999999"} {
		f.Add(s)
	}
	f.Fuzz(func(t *testing.T, s string) {
		q, err := ParseQuantity(s)
		if err != nil {
			return // rejecting input is fine; panicking is not
		}
		if q < 0 {
			t.Fatalf("negative quantity %d from %q", q, s)
		}
		q2, err := ParseQuantity(q.String())
		if err != nil || q2 != q {
			t.Fatalf("round trip %q -> %v -> %v (%v)", s, q, q2, err)
		}
	})
}
```

## Fuzz commands and corpus

```bash
go test ./pkg                                              # runs seeds + testdata corpus only
go test -run '^$' -fuzz '^FuzzParseQuantity$' -fuzztime 30s ./pkg
go test -run '^$' -fuzz '^FuzzParseQuantity$' -fuzztime 10000x ./pkg
go clean -fuzzcache
```

- `-fuzz` must match **exactly one** fuzz target in **one** package.
- Without `-fuzztime`, fuzzing runs until a failure or Ctrl-C.
- A failing input is minimized and saved to `testdata/fuzz/FuzzXxx/<hash>`. **Commit it.** Plain `go test` then reruns it as a regression test.
- Generated interesting inputs live in `$GOCACHE/fuzz`.
- Output: `baseline coverage`, `execs`, `new interesting` (inputs that found new coverage), `workers`.
- Coverage-guided fuzzing runs on amd64 and arm64.
- CI: run seeds on every PR (plain `go test`). Run time-boxed fuzzing nightly.

Fuzzing finds panics and strange inputs cheaply, and helps security. It guarantees nothing and does not replace example-based tests.

## Property-based testing

Assert a **property** that must hold for all inputs, and let a generator search for a counterexample:

- round-trip: `Decode(Encode(x)) == x`
- idempotence: `f(f(x)) == f(x)`
- invariants: output sorted, length preserved, no negatives
- oracle: new implementation agrees with a simple reference implementation

Standard library `testing/quick` (frozen, no shrinking):

```go
func TestReverseTwiceIsIdentity(t *testing.T) {
	prop := func(xs []int) bool {
		return slices.Equal(Reverse(Reverse(xs)), xs)
	}
	if err := quick.Check(prop, &quick.Config{MaxCount: 1000}); err != nil {
		t.Error(err)
	}
}
```

- `quick.CheckEqual(f, g, cfg)` finds inputs where two functions disagree. Use it to check a refactor against the old version.
- Custom types implement `quick.Generator`.

For serious work, prefer `pgregory.net/rapid`. It shrinks failures to a minimal case and supports generics:

```go
func TestReverseTwice_Rapid(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
		if !slices.Equal(Reverse(Reverse(xs)), xs) {
			t.Fatalf("reverse twice changed %v", xs)
		}
	})
}
```

Another option: write the property inside an `f.Fuzz` body and get coverage guidance for free.

## Fuzzing HTTP handlers

Handlers are the untrusted boundary. Make each fuzz argument a request field:

```go
func FuzzCreateUser(f *testing.F) {
	f.Add("Ana", "ana@example.com", 30)
	router := api.NewRouter(newFakeStore())

	f.Fuzz(func(t *testing.T, name, email string, age int) {
		body, _ := json.Marshal(map[string]any{"name": name, "email": email, "age": age})
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/users", bytes.NewReader(body))

		router.ServeHTTP(rec, req)

		if rec.Code >= 500 {
			t.Fatalf("status %d for %s", rec.Code, body)
		}
	})
}
```

- Use `httptest.NewRecorder` in process. A live service is slow and not hermetic.
- The right property is "never 5xx, never panic, always valid JSON", not "always 200".
- If the fake store keeps state across iterations, make sure no assertion depends on that history.
