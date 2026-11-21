# Testing Concurrent Code

## Contents
- Principles
- Channel behavior table
- Synchronization idioms
- Testing goroutines and channels
- testing/synctest (Go 1.25+)
- The race detector
- Common bugs

## Principles

- Never assume order between goroutines. Libraries start goroutines too: `net/http` serves every request on its own goroutine, so a handler can race even if your code never says `go`.
- The parent must wait for every goroutine it starts. Goroutines die when the program exits.
- "Share memory by communicating" when handing off ownership or signalling. Use a mutex when guarding state. Pick whichever is simpler; neither is always faster.
- Exactly one owner closes a channel.
- Tests cannot prove concurrency bugs are absent. Race conditions, deadlocks, livelocks, and starvation are design faults. Defend with design, review, `go vet`, and `-race`, not only with more tests.

## Channel behavior table

| Operation | nil channel | open channel | closed channel |
|---|---|---|---|
| send | blocks forever | blocks until received (unbuffered) or buffer has space | **panic** |
| receive | blocks forever | blocks until a value arrives | zero value at once; `v, ok := <-ch` gives `ok == false` |
| close | **panic** | succeeds | **panic** |

Setting a channel variable to `nil` inside a `select` disables that case.

## Synchronization idioms

Done signal:

```go
done := make(chan struct{})
go func() {
	defer close(done)
	work()
}()
<-done
```

Close exactly once:

```go
type Closer struct {
	once sync.Once
	ch   chan struct{}
}

func (c *Closer) Close() { c.once.Do(func() { close(c.ch) }) }
```

Go 1.21+: `sync.OnceFunc`, `sync.OnceValue`, `sync.OnceValues`.

Guarded state:

```go
type Counter struct {
	mu sync.RWMutex
	m  map[string]int
}

func (c *Counter) Inc(k string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.m[k]++
}

func (c *Counter) Get(k string) int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.m[k]
}
```

- `defer Unlock()` right after `Lock()`. Do not hold a lock across slow work.
- `sync.Map` is untyped and usually slower than map + mutex. Use it only for append-mostly keys or disjoint keys per goroutine.

Wait for N goroutines:

```go
var wg sync.WaitGroup
for _, j := range jobs {
	wg.Add(1) // before `go`, never inside the goroutine
	go func() {
		defer wg.Done()
		handle(j)
	}()
}
wg.Wait()
```

Go 1.25+: `wg.Go(func() { handle(j) })` does `Add` and `Done` for you.

Collect results without a race: a buffered channel sized to the number of producers, drained fully.

## Testing goroutines and channels

- **Never `time.Sleep` to wait.** Synchronize on a channel, a `WaitGroup`, or an injected callback.
- **Always bound the wait**, so a deadlock fails fast instead of hanging until the 10-minute default `-timeout`:

```go
select {
case got := <-results:
	assert.Equal(t, want, got)
case <-time.After(time.Second):
	t.Fatal("timed out waiting for result")
}
```

- For "eventually true" state, use `assert.Eventually(t, cond, time.Second, 10*time.Millisecond)`.
- Pass `t.Context()` (Go 1.24+) to goroutines the test starts, so they stop when the test ends.
- **Hammer test**: drive a type from many goroutines, then check invariants. It only means something under `-race`.

```go
func TestCounter_ConcurrentInc(t *testing.T) {
	c := NewCounter()
	var wg sync.WaitGroup
	for range 100 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c.Inc("k")
		}()
	}
	wg.Wait()

	require.Equal(t, 100, c.Get("k"))
}
```

- **Goroutine leaks**: `go.uber.org/goleak`. Add `defer goleak.VerifyNone(t)` or `goleak.VerifyTestMain(m)`.
- **Load test a handler**: parallel subtests that each send a request. Use `require.NoError` before `defer resp.Body.Close()`.

## testing/synctest (Go 1.25+)

For timeouts, tickers, retries, backoff, and "has not happened yet" checks:

```go
func TestRetry_BacksOff(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		calls := 0
		go retry.Do(t.Context(), func() error { calls++; return errFail })

		time.Sleep(time.Second) // fake clock: returns at once when all goroutines block
		synctest.Wait()          // wait until every goroutine in the bubble is blocked

		assert.Equal(t, 3, calls)
	})
}
```

- Time inside the bubble is fake. It moves forward only when every goroutine in the bubble is durably blocked.
- Go 1.24 had an experimental `synctest.Run` behind `GOEXPERIMENT=synctest`. Prefer 1.25's `synctest.Test`.

## The race detector

```bash
go test -race ./...
go run -race ./cmd/app
go build -race -o app-race ./cmd/app
```

- It reports `WARNING: DATA RACE` with both stacks, and the process exits with code 66.
- No false positives, but it only sees races that **execute**. Drive realistic load through a `-race` binary.
- Cost: about 5–10× memory and 2–20× CPU. Not for production.
- For a server under E2E load: build with `-race`, set `GORACE="halt_on_error=1"`, run the load, then check the exit code or logs.
- Use `-covermode=atomic` when combining `-race` with coverage.
- The runtime deadlock error (`all goroutines are asleep`) fires only when **every** goroutine is blocked. A partial deadlock in a running server is never reported. Use bounded waits in tests.

## Common bugs

- Concurrent writes to a plain `map` cause `fatal error: concurrent map writes`. This is not a recoverable panic.
- `append` to a shared slice from many goroutines loses writes.
- `wg.Add` inside the goroutine races with `Wait`.
- Copying a `Mutex`, `WaitGroup`, or `Once` by value breaks it. `go vet` (copylocks) catches this.
- Polling a shared `bool` is a race and a livelock risk. Use a channel or `atomic.Bool`.
- An unbuffered channel used as a lock deadlocks on the last worker.
- A buffered channel drained less often than it is filled leaks goroutines.
