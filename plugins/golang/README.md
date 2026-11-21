# golang

Go development toolkit for Claude Code.

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install golang@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/golang
```

## Features

### Skills (1)

- **go-tdd** - Test-driven development in Go. Based on *Test-Driven Development in Go* by Adelina Simion (Packt, 2023), updated for Go 1.22+ and current tooling.

| Reference | Covers |
|---|---|
| `unit-testing.md` | `testing` package, subtests, table-driven tests, edge cases, `t.Parallel`, coverage, benchmarks |
| `mocking-and-assertions.md` | Consumer-side interfaces, dependency injection, testify + mockery, gomock, error assertions |
| `integration-and-e2e.md` | Gating slow tests, httptest, Ginkgo/Gomega, DB testing, Docker compose, Godog |
| `refactoring-and-microservices.md` | Refactoring under tests, monolith split, benchmarks + pprof, Pact v2, circuit breakers |
| `concurrency.md` | Goroutines, channels, sync primitives, `-race`, `testing/synctest`, goleak |
| `fuzzing-and-properties.md` | Native fuzzing, corpus handling, `testing/quick`, `rapid` |
| `generics.md` | Constraints, generic table-driven tests, generic test helpers |

## Usage

The skill triggers automatically when you write or fix Go tests, practice TDD in Go, or ask about `go test` flags, mocks, the race detector, or fuzzing.
