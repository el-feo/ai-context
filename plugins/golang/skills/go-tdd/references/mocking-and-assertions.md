# Mocking, Assertions, and Testable Design

## Contents
- Interfaces as dependencies
- Dependency injection
- Choosing a test double
- testify + mockery
- go.uber.org/mock (gomock)
- Assertions with testify
- Asserting errors
- Writing testable code

## Interfaces as dependencies

- Declare small interfaces **where they are used** (consumer side), not next to the implementation.
- Depend on the interface, not the concrete type. This breaks package coupling and narrows what the unit can reach.
- Small interfaces give small mocks and simple tests (Interface Segregation).
- Mock **direct** dependencies only. Transitive dependencies then vanish from the test.
- Interfaces are satisfied implicitly. Their zero value is `nil`; handle it.
- Do not mock type-set constraint interfaces (`interface{ ~int | ~float64 }`). They cannot be variable types. Exclude them from mock generation.

```go
package checkout

// PaymentGateway is what Checkout needs. The real Stripe client satisfies it implicitly.
type PaymentGateway interface {
	Charge(orderID string, cents int) error
}

type Checkout struct{ pay PaymentGateway }

func New(pay PaymentGateway) *Checkout { return &Checkout{pay: pay} }
```

## Dependency injection

- **Constructor injection** (`New(dep)`) is the default. Dependencies are complete and do not change.
- Avoid setter injection. Nothing guarantees the dependency is set, so you add nil checks and get subtle bugs.
- Wire by hand in `main`. Use a framework only for large graphs:
  - `github.com/google/wire`: compile-time code generation. Write a `wire.go` with `//go:build wireinject`, then run `wire`.
  - `go.uber.org/dig`: runtime reflection.
- Function injection (pass a `func` value) is fine for one small behavior such as a clock: `now func() time.Time`. Use it sparingly; it hurts readability.

## Choosing a test double

| Double | When |
|---|---|
| Hand-written fake (small struct implementing the interface) | Interface has 1–3 methods. Often the clearest option. |
| Stub (fixed return values) | You only need the unit to proceed. |
| Generated mock with expectations | You must verify calls: arguments, counts, order. |
| Real implementation | Pure, fast, in-memory code. Do not mock it. |

Mocks give false confidence when the real implementation drifts. Back them with integration or contract tests.

## testify + mockery

Install:

```bash
go get github.com/stretchr/testify
go install github.com/vektra/mockery/v2@latest   # or v3, configured by .mockery.yml
```

Generate:

- mockery v2: `mockery --dir ./checkout --name PaymentGateway --output ./checkout/mocks`, or `--all`.
- mockery v3: list `packages:` and interfaces in `.mockery.yml`, then run `mockery`.
- Commit the config or a `//go:generate mockery ...` line so anyone can regenerate.

Use:

```go
func TestComplete_ChargesOrder(t *testing.T) {
	// Arrange
	pay := mocks.NewPaymentGateway(t) // registers AssertExpectations via t.Cleanup
	pay.On("Charge", "order-1", 1999).Return(nil).Once()
	svc := checkout.New(pay)

	// Act
	err := svc.Complete("order-1", 1999)

	// Assert
	require.NoError(t, err)
}
```

- The generated `NewX(t)` constructor asserts expectations automatically at cleanup. If you build `&mocks.X{}` directly, call `pay.AssertExpectations(t)` yourself.
- Arguments in `On` must match the real call exactly, including pointer vs value. A mismatch panics at call time.
- Matchers: `mock.Anything`, `mock.AnythingOfType("checkout.Order")`, `mock.MatchedBy(func(o Order) bool {...})`. Use `Anything` sparingly; it hides intent.
- Counts: `.Once()`, `.Twice()`, `.Times(n)`.
- Never called: `pay.AssertNotCalled(t, "Charge", mock.Anything, mock.Anything)`.
- `.Unset()` removes an expectation. It does **not** mean "must not be called".
- mockery v3 and `--with-expecter` generate typed builders: `pay.EXPECT().Charge("order-1", 1999).Return(nil)`. Prefer them; typos fail at compile time.

## go.uber.org/mock (gomock)

`github.com/golang/mock` is archived. Use the maintained fork.

```bash
go install go.uber.org/mock/mockgen@latest
mockgen -source=checkout.go -destination=mocks/payment_gateway.go -package=mocks
```

```go
ctrl := gomock.NewController(t) // verifies on cleanup
pay := mocks.NewMockPaymentGateway(ctrl)
pay.EXPECT().Charge("order-1", 1999).Return(nil)
```

## Assertions with testify

- `assert.X` records a failure and continues (like `t.Errorf`).
- `require.X` stops the test (like `t.Fatalf`). Use it for preconditions: no error before you use a result, a non-nil value before you dereference it.
- Argument order: `assert.Equal(t, want, got)`. Reversed order produces confusing failure output.
- Common: `Equal`, `NotEqual`, `Nil`, `NotNil`, `Empty`, `NotEmpty`, `Len`, `Contains` (string, slice, or map key), `ElementsMatch` (order-free slices), `Subset`, `JSONEq`, `Eventually`.
- Use `Nil` and `NotNil`, not `Equal(t, nil, x)`.

## Asserting errors

| Check | Use |
|---|---|
| Any error | `require.Error(t, err)` |
| No error | `require.NoError(t, err)` |
| Specific sentinel, even when wrapped | `require.ErrorIs(t, err, store.ErrNotFound)` |
| Error type, then inspect fields | `require.ErrorAs(t, err, &target)` |
| Exact message is the contract | `assert.EqualError(t, err, "msg")` |

Prefer identity or type over message text:

```go
var ErrNotFound = errors.New("not found")

type InsufficientStockError struct {
	SKU                  string
	Requested, Available int
}

func (e *InsufficientStockError) Error() string {
	return fmt.Sprintf("sku %s: requested %d, only %d available", e.SKU, e.Requested, e.Available)
}

func TestReserve_TooMany(t *testing.T) {
	err := inventory.Reserve("ABC", 10)

	var stockErr *inventory.InsufficientStockError
	require.ErrorAs(t, err, &stockErr)
	assert.Equal(t, 3, stockErr.Available)
}
```

- Wrap with `fmt.Errorf("reserve %s: %w", sku, err)`. `errors.Is` and `errors.As` see through wraps; `==` does not.
- Go 1.20+: `errors.Join` and multiple `%w` are also traversed.
- Return the `error` interface, never a concrete error pointer type. A typed nil pointer inside an `error` interface is not `nil`.
- Do not compare `errors.New("x")` values with `assert.Equal`. It passes only by struct comparison and breaks when the error is wrapped.

## Writing testable code

Hard-to-test code is a design smell. SOLID, applied to Go packages:

- **Single responsibility**: small units give small test scope.
- **Open/closed**: extend behavior without breaking existing tests.
- **Liskov**: every implementation honors the interface contract, including fakes.
- **Interface segregation**: small, consumer-defined interfaces.
- **Dependency inversion**: depend on interfaces, inject them.

Also: no hidden globals, no `time.Now()` or `rand` buried in logic (inject a clock or source), and validate every input you did not create.
