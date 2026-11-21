# Integration and End-to-End Testing

## Contents
- Unit vs integration vs E2E
- Gating slow tests
- httptest
- BDD with Ginkgo and Gomega
- Database testing
- Docker and docker compose
- E2E with Godog
- Seed data and database assertions

## Unit vs integration vs E2E

| Level | Scope | Real parts | Mock |
|---|---|---|---|
| Unit | One function or type | Nothing external | Direct dependencies |
| Integration | Seams between components in one module | Component + real DB, seeded to a known state | Third-party services only |
| E2E | A whole user journey | The deployed system (Docker) | Nothing, or stubbed external vendors |

- Write integration tests exactly like unit tests: `TestXxx`, Arrange–Act–Assert, tables. Only the scope is larger.
- Integration tests are cheaper than E2E and better for negative and partial-outage cases.
- E2E tests are costly. Cover mainly happy paths from user journeys. Push variations down.
- Do **not** mock the database in integration or E2E tests. Use the same engine as production. Mocks hide schema, NULL, constraint, and performance bugs.

## Gating slow tests

Plain `go test ./...` must stay fast. Slow tests need an explicit opt-in.

| Mechanism | How | Note |
|---|---|---|
| Build tag (recommended) | `//go:build integration` as the first line; run `go test -tags=integration ./...` | Excluded files do not compile by default. Run `go vet -tags=integration ./...` in CI. |
| Env var | `if os.Getenv("INTEGRATION") == "" { t.Skip(...) }`; run `INTEGRATION=1 go test ./...` | Put the check in one helper. |
| Short mode | `if testing.Short() { t.Skip("slow") }`; run `go test -short ./...` | Fast mode is the opt-in, so slow is the default. |
| Name suffix | `TestXxx_Integration`; run `-run Integration` | Bare `go test` still runs everything. |

```go
func requireIntegration(t *testing.T) {
	t.Helper()
	if os.Getenv("INTEGRATION") == "" {
		t.Skip("set INTEGRATION=1 to run")
	}
}
```

Use `//go:build`, not the legacy `// +build` line.

## httptest

Two styles from `net/http/httptest`:

```go
// 1. Real loopback server: the client under test does not know it is fake.
srv := httptest.NewServer(api.NewRouter(store))
t.Cleanup(srv.Close)
res, err := http.Get(srv.URL + "/widgets")
require.NoError(t, err)
defer res.Body.Close()
require.Equal(t, http.StatusOK, res.StatusCode)

// 2. In-process: no port, faster.
rec := httptest.NewRecorder()
req := httptest.NewRequest(http.MethodGet, "/widgets/w1", nil)
api.NewRouter(store).ServeHTTP(rec, req)
assert.Equal(t, http.StatusOK, rec.Code)
assert.JSONEq(t, `{"id":"w1","name":"Sprocket"}`, rec.Body.String())
```

- Use `require.NoError` before `defer res.Body.Close()`. On error `res` is nil and the defer panics.
- Test the whole router, not single handlers, when routing and middleware matter.
- Go 1.22+ `http.ServeMux` supports `"GET /books/{id}"` patterns and `r.PathValue("id")`. New code often needs no router library.

## BDD with Ginkgo and Gomega

```bash
go install github.com/onsi/ginkgo/v2/ginkgo@latest
go get github.com/onsi/gomega/...
ginkgo bootstrap        # creates <pkg>_suite_test.go
ginkgo generate widget  # creates widget_test.go
ginkgo -v ./...         # or plain go test
```

```go
// widget_suite_test.go
func TestAPI(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "API Suite")
}

// widget_test.go
var _ = Describe("Widget API", func() {
	var srv *httptest.Server

	BeforeEach(func() {
		srv = httptest.NewServer(api.NewRouter(seededStore()))
		DeferCleanup(srv.Close)
	})

	Context("with one widget", func() {
		It("returns 200", func() {
			res, err := http.Get(srv.URL + "/widgets")
			Expect(err).NotTo(HaveOccurred())
			Expect(res.StatusCode).To(Equal(http.StatusOK))
		})
	})
})
```

- One suite per package. Each `It` is one spec.
- `Context` is an alias of `Describe`. `It` cannot contain other nodes.
- `BeforeEach` runs outermost first. Teardown runs innermost first.
- v2 features: `DescribeTable`/`Entry`, `DeferCleanup`, `Label("integration")` with `ginkgo --label-filter=integration`, `--focus`, `--skip`.
- Import `github.com/onsi/ginkgo/v2`. The v1 path and `ginkgo/extensions/table` are outdated.

## Database testing

What to cover:

- Startup: the app waits for the DB and fails clearly when it is down.
- Persistence and query correctness.
- Volume: large result sets, extreme column values.
- Format translation: JSON → struct → SQL (for example, a NOT NULL column that is optional in the API).

Libraries:

| Library | Use |
|---|---|
| `github.com/testcontainers/testcontainers-go` | Start a throwaway Postgres (or other) container from `TestMain` or a test |
| `github.com/golang-migrate/migrate/v4` | Versioned schema and seed migrations |
| `github.com/DATA-DOG/go-txdb` | Each test runs in a transaction that rolls back |
| `github.com/go-testfixtures/testfixtures/v3` | YAML fixtures |
| `gorm.io/gorm`, `github.com/uptrace/bun` | ORMs |

Isolation: prefer a rolled-back transaction per test, or `t.Cleanup` with **committed** deletes. A cleanup that deletes inside `Begin()` without `Commit()` deletes nothing.

Migrations in code:

```go
import (
	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

m, err := migrate.New("file://db/migrations", dbURL)
if err != nil {
	return err
}
if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
	return err
}
```

CLI: `migrate create -ext sql -dir db/migrations -seq create_users_table`.

Never call `m.Down()` on app shutdown. It drops every table.

GORM: always check `.Error`. The result of `db.First(&x)` is a `*gorm.DB`, which is never nil.

```go
if err := db.Where("owner_id = ?", userID).Find(&books).Error; err != nil { ... }
```

## Docker and docker compose

Multi-stage Dockerfile with layer caching:

```dockerfile
FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/app ./cmd/app

FROM gcr.io/distroless/static
COPY --from=build /bin/app /app
ENTRYPOINT ["/app"]
```

Compose with a DB health gate:

```yaml
services:
  app:
    build: .
    ports: ["${APP_PORT}:${APP_PORT}"]
    env_file: [test.env]
    depends_on:
      db: { condition: service_healthy }
  db:
    image: postgres:16-alpine
    env_file: [test.env]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app"]
      interval: 1s
      retries: 10
```

- Inside compose, the DB host is the service name: `postgres://app:app@db:5432/app?sslmode=disable`.
- Without `condition: service_healthy`, the app races the DB at startup.
- The top-level `version:` key is obsolete.
- Run: `docker compose -f docker-compose.test.yml up --build -d`, then the tests, then `docker compose down -v`.

## E2E with Godog

Godog is Cucumber for Go. Derive features from **user journeys**.

```bash
go install github.com/cucumber/godog/cmd/godog@latest
```

`features/customer_registers.feature` (one feature per file, plain business language):

```gherkin
Feature: Customer registers
  In order to place orders
  As a new customer
  I need to register an account

  Scenario: Successful registration
    Given the shop API is up
    And valid customer details
    When they are submitted to the customers endpoint
    Then a customer profile is created
```

Steps pass state through `context.Context`:

```go
type stateKey struct{}

type state struct {
	BaseURL  string
	Customer Customer
	Resp     *http.Response
}

func theShopAPIIsUp(ctx context.Context) (context.Context, error) {
	base := os.Getenv("SHOP_BASE_URL")
	res, err := http.Get(base + "/health")
	if err != nil {
		return ctx, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return ctx, fmt.Errorf("health: status %d", res.StatusCode)
	}
	return context.WithValue(ctx, stateKey{}, &state{BaseURL: base}), nil
}

func InitializeScenario(sc *godog.ScenarioContext) {
	sc.Step(`^the shop API is up$`, theShopAPIIsUp)
	sc.Step(`^valid customer details$`, validCustomerDetails)
	sc.Step(`^they are submitted to the customers endpoint$`, submitCustomer)
	sc.Step(`^a customer profile is created$`, profileIsCreated)
}
```

Run through `go test` so CI needs no extra binary:

```go
func TestFeatures(t *testing.T) {
	suite := godog.TestSuite{
		ScenarioInitializer: InitializeScenario,
		Options: &godog.Options{
			Format:   "pretty",
			Paths:    []string{"features"},
			TestingT: t,
			Strict:   true, // pending or undefined steps fail
		},
	}
	if suite.Run() != 0 {
		t.Fatal("feature tests failed")
	}
}
```

- `godog run` prints stubs for undefined steps, returning `godog.ErrPending`. It lists them alphabetically; reorder them to match the feature file.
- Make the target configurable (`SHOP_BASE_URL`), so the same suite runs locally, in compose, or against staging.
- Stub external vendors behind an interface inside the app until the real integration exists.

## Seed data and database assertions

- Static seeds: `INSERT` statements in an up-migration.
- Per-test seeds: insert from test setup, with unique IDs.
- Seed shared fixtures so each E2E test does not rebuild all prerequisites.
- Assert DB state **directly against the DB**, not through your own repository code. Your own bugs then cannot hide in the oracle, and the failing layer is clear.
- Reuse one DB connection per suite.

```go
func assertCustomerStored(ctx context.Context, db *gorm.DB, want Customer) error {
	var got Customer
	if err := db.WithContext(ctx).Where("id = ?", want.ID).First(&got).Error; err != nil {
		return fmt.Errorf("lookup %s: %w", want.ID, err)
	}
	if got != want {
		return fmt.Errorf("got %+v, want %+v", got, want)
	}
	return nil
}
```
