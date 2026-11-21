# Testing Generic Code

## Contents
- Generics refresher
- Constraints
- Generic table-driven tests
- Generic test helpers
- Pitfalls

## Generics refresher

- Type parameter `[T C]`, constraint `C`, type argument (`Sum[int64](xs)`). Type inference usually lets you omit the argument.
- Generics specify **types**. Interfaces specify **behavior**. Keep using interfaces for dependencies you want to mock.
- Use generics for shared plumbing: collections, response envelopes, test helpers. Keep separate code paths where domains differ.

## Constraints

| Constraint | Allows |
|---|---|
| `any` | Any type. No operators. |
| `comparable` | `==`, `!=`. Not `<` or `+`. Interfaces satisfy it since Go 1.20 and may panic at runtime. |
| `cmp.Ordered` (Go 1.21+) | `<`, `<=`, `>`, `>=` on ints, uints, floats, strings |
| `int64 \| float64` | Exactly these types |
| `~int` | Any type whose underlying type is `int` (e.g. `type Score int`) |

```go
type Number interface {
	~int | ~int64 | ~float64
}

func Sum[T Number](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}
```

- Constrain as tightly as the body needs. The signature documents the contract.
- `golang.org/x/exp/constraints` is outdated. Use `cmp.Ordered` and the `slices` and `maps` packages.
- Go 1.23+: `maps.Keys` returns an iterator. Use `slices.Sorted(maps.Keys(m))`.

## Generic table-driven tests

Test across **type arguments** as well as values. Include at least one built-in type and one `~`-derived named type, plus empty, nil, negative, and duplicate cases.

Recipe:

1. Define a generic case type.
2. Write a generic runner that loops the table with `t.Run`.
3. Build one table per type instantiation.
4. Call the runner once per instantiation, each in its own subtest.

```go
type sumCase[T Number] struct {
	in   []T
	want T
}

func runSumCases[T Number](t *testing.T, cases map[string]sumCase[T]) {
	t.Helper()
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			assert.Equal(t, tc.want, Sum(tc.in))
		})
	}
}

type Score int

func TestSum(t *testing.T) {
	t.Run("int", func(t *testing.T) {
		runSumCases(t, map[string]sumCase[int]{
			"empty": {in: nil, want: 0},
			"mixed": {in: []int{-2, 5}, want: 3},
		})
	})
	t.Run("float64", func(t *testing.T) {
		runSumCases(t, map[string]sumCase[float64]{
			"fraction": {in: []float64{0.5, 0.25}, want: 0.75},
		})
	})
	t.Run("named Score", func(t *testing.T) {
		runSumCases(t, map[string]sumCase[Score]{
			"two": {in: []Score{10, 20}, want: 30},
		})
	})
}
```

## Generic test helpers

Generic helpers replace `interface{}`- and reflection-based helpers, and they are type-safe:

```go
func AssertSortedBy[T any, K cmp.Ordered](t *testing.T, xs []T, key func(T) K) {
	t.Helper()
	ok := slices.IsSortedFunc(xs, func(a, b T) int { return cmp.Compare(key(a), key(b)) })
	if !ok {
		t.Fatalf("not sorted: %v", xs)
	}
}
```

Generic response envelopes:

```go
type Response[T any] struct {
	Items []T `json:"items"`
}
```

Renaming a JSON field (for example `books` → `items`) is a breaking API change. Update contract tests.

## Pitfalls

- `tc := tc` copies are unnecessary with `go 1.22`+ in `go.mod`.
- Mock generators may emit mocks for type-set constraint interfaces. Those mocks are unusable. Exclude them.
- Generic helpers still need `t.Helper()`.
- Do not genericize code just because you can. Two clear functions beat one confusing generic one.
