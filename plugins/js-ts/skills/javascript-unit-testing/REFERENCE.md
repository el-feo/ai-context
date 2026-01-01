# JavaScript Unit Testing Reference

Comprehensive reference documentation for unit testing concepts, patterns, and best practices.

## Table of Contents

- [Core Definitions](#core-definitions)
- [Jest API Reference](#jest-api-reference)
- [Test Patterns](#test-patterns)
- [Dependency Injection](#dependency-injection)
- [Async Testing](#async-testing)
- [Test Quality](#test-quality)
- [Troubleshooting](#troubleshooting)

## Core Definitions

### Unit of Work

A **unit of work** is all the actions that take place between the invocation of an **entry point** up until a noticeable end result through one or more **exit points**.

- **Entry Point**: The function/method signature we trigger
- **Exit Points**: Observable results (return value, state change, or third-party call)
- **Unit**: Can span a single function, multiple functions, or even multiple modules

A unit of work always has:

1. An entry point that can be triggered from outside (via tests or production code)
2. One or more exit points that produce something publicly noticeable

### Exit Point Types

**1. Return Value Exit Point**

- Function returns a useful value (not undefined)
- Easiest to test
- Example: `return sum;`

**2. State-Based Exit Point**

- Noticeable change to system state or behavior
- Can be determined without interrogating private state
- Example: Updating a running total, modifying a cache, changing configuration

**3. Third-Party Call Exit Point**

- Callout to external system over which test has no control
- Examples: Logger calls, database saves, API requests, email sending
- Requires mock objects for verification

### Dependencies

**Definition**: Something we don't have full control over during a unit test, or something that controlling would make our lives miserable.

**Common dependencies:**

- Time (Date.now(), moment())
- Random values (Math.random())
- Network (fetch, axios, http)
- Filesystem (fs.readFile, fs.writeFile)
- Databases (queries, transactions)
- External services (APIs, message queues)
- Code by other teams
- Slow operations (heavy calculations, threads)

**Rule of thumb**: If we can fully and easily control what it's doing, it runs in memory, and it's fast, then it's not a dependency. Otherwise, it probably is.

### Stubs, Mocks, and Fakes

**Test Double / Fake**: Generic term for anything that replaces a real implementation in tests.

**Stub**:

- Breaks **incoming dependencies** (indirect inputs)
- Provides fake behavior or data **INTO** the code under test
- Purpose: Simplify testing by providing controllable data
- **Do NOT assert against stubs**
- Can have **many stubs** in a single test

**Mock**:

- Breaks **outgoing dependencies** (indirect outputs / exit points)
- Purpose: Verify the unit of work called it correctly
- **DO assert against mocks**
- Should have **only ONE mock per test** (represents one exit point)

**Example:**

```javascript
// Stub - provides data in
const stubDatabase = {
  getUser: () => ({ id: 1, name: 'John' })
};

// Mock - verifies calls out
const mockLogger = {
  info: jest.fn()
};

test('getUserName retrieves and logs', () => {
  const service = new UserService(stubDatabase, mockLogger);

  const name = service.getUserName(1);

  expect(name).toBe('John'); // Assert return value
  expect(mockLogger.info).toHaveBeenCalled(); // Assert mock was called
});
```

### Dependency Injection

**Definition**: The act of sending a dependency through a design interface to be used internally by code.

**Inversion of Control**: Designing code to remove the responsibility of creating dependencies internally, externalizing it instead.

**Injection Point / Seam**: Place where two pieces of software meet and something else can be injected.

**Control**: The ability to instruct a dependency how to behave. Whoever creates the dependencies has control over them.

## Jest API Reference

### Test Organization

**test() / it()**

```javascript
test('description', () => { /* test body */ });
it('description', () => { /* test body */ }); // Alias for test()
```

**describe()**

```javascript
describe('group name', () => {
  test('test 1', () => { ... });
  test('test 2', () => { ... });
});
```

**test.each() - Parameterized Tests**

```javascript
test.each([
  ['input1', expected1],
  ['input2', expected2],
])('given %s, expects %s', (input, expected) => {
  expect(fn(input)).toBe(expected);
});
```

### Assertions

**Basic Matchers**

```javascript
expect(value).toBe(expected);           // Strict equality (===)
expect(value).toEqual(expected);        // Deep equality
expect(value).not.toBe(expected);       // Negation
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();
expect(value).toBeTruthy();
expect(value).toBeFalsy();
```

**Numbers**

```javascript
expect(value).toBeGreaterThan(3);
expect(value).toBeGreaterThanOrEqual(3);
expect(value).toBeLessThan(5);
expect(value).toBeLessThanOrEqual(5);
expect(value).toBeCloseTo(0.3, 5); // Floating point comparison
```

**Strings**

```javascript
expect(string).toMatch(/pattern/);
expect(string).toContain('substring');
```

**Arrays and Iterables**

```javascript
expect(array).toContain(item);
expect(array).toHaveLength(3);
```

**Exceptions**

```javascript
expect(() => fn()).toThrow();
expect(() => fn()).toThrow(Error);
expect(() => fn()).toThrow('error message');
expect(() => fn()).toThrow(/pattern/);
```

### Mock Functions

**Creating Mocks**

```javascript
const mockFn = jest.fn();
const mockFn = jest.fn(() => 'return value');
const mockFn = jest.fn().mockReturnValue('value');
```

**Mock Assertions**

```javascript
expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(2);
expect(mockFn).toHaveBeenCalledWith(arg1, arg2);
expect(mockFn).toHaveBeenLastCalledWith(arg1, arg2);
expect(mockFn).toHaveBeenNthCalledWith(2, arg1, arg2);
```

**Mock Return Values**

```javascript
mockFn.mockReturnValue('value');
mockFn.mockReturnValueOnce('first').mockReturnValueOnce('second');
mockFn.mockResolvedValue('async value'); // For promises
mockFn.mockRejectedValue(new Error('error')); // For promise rejections
```

**Mock Implementations**

```javascript
mockFn.mockImplementation((...args) => {
  return 'custom implementation';
});
```

### Module Mocking

**jest.mock()**

```javascript
jest.mock('./module');
const mockModule = require('./module');

test('uses mocked module', () => {
  mockModule.fn.mockReturnValue('value');
  // test code
});
```

**Resetting Mocks**

```javascript
beforeEach(() => {
  jest.resetAllMocks(); // Reset call counts and implementations
  jest.clearAllMocks(); // Only reset call counts
  jest.restoreAllMocks(); // Restore original implementations
});
```

### Timers

**Fake Timers**

```javascript
jest.useFakeTimers();

// Advance timers
jest.advanceTimersByTime(1000); // Advance by milliseconds
jest.runAllTimers(); // Run all pending timers
jest.runOnlyPendingTimers(); // Run only currently pending timers

// Restore real timers
jest.useRealTimers();
```

### Async Testing

**async/await**

```javascript
test('async test', async () => {
  const result = await asyncFunction();
  expect(result).toBe('value');
});
```

**done() callback**

```javascript
test('callback test', (done) => {
  callbackFunction((result) => {
    expect(result).toBe('value');
    done();
  });
});
```

**Promises**

```javascript
test('promise test', () => {
  return promiseFunction().then(result => {
    expect(result).toBe('value');
  });
});
```

## Test Patterns

### AAA Pattern (Arrange-Act-Assert)

```javascript
test('description', () => {
  // Arrange - Set up test data and dependencies
  const input = 'test input';
  const expectedOutput = 'expected';
  const dependency = createDependency();

  // Act - Call the unit of work
  const result = unitUnderTest(input, dependency);

  // Assert - Verify the outcome
  expect(result).toBe(expectedOutput);
});
```

### USE Naming Pattern

**Format**: [Unit of work], [Scenario/input], [Expected behavior]

```javascript
// Good examples
test('sum, with two positive numbers, returns their sum', () => { ... });
test('verify, with no uppercase letter, returns false', () => { ... });
test('save, during maintenance window, throws exception', () => { ... });
test('login, with invalid credentials, returns error message', () => { ... });

// Poor examples (avoid)
test('it works', () => { ... }); // Too vague
test('test1', () => { ... }); // No meaning
test('sum returns 3', () => { ... }); // Missing scenario
```

### Factory Method Pattern

**Instead of beforeEach():**

```javascript
// ❌ BAD - beforeEach causes scroll fatigue
describe('verifier', () => {
  let verifier;
  let logger;

  beforeEach(() => {
    logger = createLogger();
    verifier = new Verifier(logger);
  });

  test('test 1', () => {
    // Where did verifier come from? Scroll up!
    verifier.verify('input');
  });

  test('test 2', () => {
    verifier.verify('input2');
  });
});

// ✅ GOOD - factory method keeps everything visible
describe('verifier', () => {
  const makeVerifier = (logger = createLogger()) => {
    return new Verifier(logger);
  };

  test('verify with valid input returns success', () => {
    const verifier = makeVerifier(); // Clear where it comes from
    const result = verifier.verify('ValidInput123');
    expect(result).toBe(true);
  });

  test('verify logs attempt', () => {
    const mockLogger = { log: jest.fn() };
    const verifier = makeVerifier(mockLogger); // Clear dependencies
    verifier.verify('input');
    expect(mockLogger.log).toHaveBeenCalled();
  });
});
```

### Parameterized Tests

**Use for multiple inputs with same scenario:**

```javascript
describe('one uppercase rule', () => {
  test.each([
    ['Abc', true],
    ['aBc', true],
    ['ABc', true],
  ])('given %s, returns %s', (input, expected) => {
    const result = oneUpperCaseRule(input);
    expect(result.passed).toBe(expected);
  });
});
```

**Important**: Only parameterize inputs. Create separate tests for different outputs to maintain readability.

```javascript
// ❌ BAD - mixes different scenarios
test.each([
  ['Abc', true],  // Has uppercase
  ['abc', false], // No uppercase - different scenario!
])('...', (input, expected) => { ... });

// ✅ GOOD - separate tests for different scenarios
describe('one uppercase rule', () => {
  test.each([
    ['Abc', true],
    ['aBc', true],
  ])('with uppercase %s, returns true', (input, expected) => { ... });

  test.each([
    ['abc', false],
    ['123', false],
  ])('without uppercase %s, returns false', (input, expected) => { ... });
});
```

## Dependency Injection

### Parameter Injection

**Simplest form - inject through function parameters:**

```javascript
// Before - dependency baked in
const verifyPassword = (input, rules) => {
  const dayOfWeek = moment().day(); // Can't control!
  if ([SATURDAY, SUNDAY].includes(dayOfWeek)) {
    throw Error("It's the weekend!");
  }
  return validateRules(input, rules);
};

// After - dependency injected
const verifyPassword = (input, rules, currentDay) => {
  if ([SATURDAY, SUNDAY].includes(currentDay)) {
    throw Error("It's the weekend!");
  }
  return validateRules(input, rules);
};

// Test with full control
test('on weekends, throws exception', () => {
  expect(() => verifyPassword('input', [], SUNDAY))
    .toThrow("It's the weekend!");
});
```

### Functional Injection

**Higher-order functions and currying:**

```javascript
// Configuration function returns the actual function
const createVerifier = (logger) => {
  return (input, rules) => {
    logger.info('Verifying password');
    return validateRules(input, rules);
  };
};

// Production usage
const verify = createVerifier(realLogger);
verify('password123', [lengthRule]);

// Test usage
test('verify logs verification attempt', () => {
  const mockLogger = { info: jest.fn() };
  const verify = createVerifier(mockLogger);

  verify('password', []);

  expect(mockLogger.info).toHaveBeenCalledWith('Verifying password');
});
```

### Module Injection

**Inject entire modules:**

```javascript
// password-verifier.js
const verify = (input, rules, logger = require('./logger')) => {
  logger.info('Verifying');
  return validateRules(input, rules);
};

// Test with jest.mock()
jest.mock('./logger');
const mockLogger = require('./logger');

test('verify calls logger', () => {
  const { verify } = require('./password-verifier');

  verify('input', []);

  expect(mockLogger.info).toHaveBeenCalled();
});
```

### Constructor Injection (OOP)

**Inject dependencies through constructor:**

```typescript
interface ILogger {
  info(message: string): void;
}

class PasswordVerifier {
  constructor(
    private rules: Rule[],
    private logger: ILogger
  ) {}

  verify(input: string): boolean {
    this.logger.info('Verifying password');
    return this.rules.every(rule => rule.check(input));
  }
}

// Test with mock
test('verify logs attempt', () => {
  const mockLogger = { info: jest.fn() };
  const verifier = new PasswordVerifier([], mockLogger);

  verifier.verify('password');

  expect(mockLogger.info).toHaveBeenCalledWith('Verifying password');
});
```

## Async Testing

### The Problem with Integration Tests

```javascript
// ❌ Integration test - slow, flaky, hard to test edge cases
test('website is alive', async () => {
  const result = await isWebsiteAlive(); // Real network call!
  expect(result.success).toBe(true);
  // Problems:
  // - Requires network
  // - Slow (seconds)
  // - Flaky (network issues)
  // - Can't simulate errors easily
  // - Tests external service, not our code
});
```

### Pattern 1: Extract Entry Point

**Extract pure logic into separate testable functions:**

```javascript
// Before - everything mixed together
const isWebsiteAlive = async () => {
  try {
    const resp = await fetch('http://example.com');
    if (!resp.ok) throw resp.statusText;
    const text = await resp.text();

    if (text.includes('illustrative')) {
      return { success: true, status: 'ok' };
    }
    return { success: false, status: 'missing text' };
  } catch (err) {
    return { success: false, status: err };
  }
};

// After - extract pure logic
const isWebsiteAlive = async () => {
  try {
    const resp = await fetch('http://example.com');
    throwIfResponseNotOK(resp);
    const text = await resp.text();
    return processFetchContent(text); // ← New entry point
  } catch (err) {
    return processFetchError(err); // ← New entry point
  }
};

// Pure, testable functions
const processFetchContent = (text) => {
  if (text.includes('illustrative')) {
    return { success: true, status: 'ok' };
  }
  return { success: false, status: 'missing text' };
};

const processFetchError = (err) => {
  return { success: false, status: err };
};

// ✅ Fast, synchronous unit tests
test('with good content, returns success', () => {
  const result = processFetchContent('illustrative content');
  expect(result.success).toBe(true);
  expect(result.status).toBe('ok');
});

test('with bad content, returns failure', () => {
  const result = processFetchContent('unexpected content');
  expect(result.success).toBe(false);
  expect(result.status).toBe('missing text');
});

test('with error, returns failure', () => {
  const result = processFetchError('Network error');
  expect(result.success).toBe(false);
  expect(result.status).toBe('Network error');
});
```

**Benefits:**

- Most tests are fast and synchronous
- Easy to simulate all scenarios (good content, bad content, errors)
- Still can have 1-2 integration tests for the original function
- Separates logic from orchestration

### Pattern 2: Extract Adapter

**Wrap async dependencies behind testable interfaces:**

```javascript
// Step 1: Create adapter wrapper
// network-adapter.js
const fetch = require('node-fetch');

const fetchUrlText = async (url) => {
  const resp = await fetch(url);
  if (resp.ok) {
    const text = await resp.text();
    return { ok: true, text };
  }
  return { ok: false, text: resp.statusText };
};

module.exports = { fetchUrlText };

// Step 2: Inject adapter into production code
// website-verifier.js
const isWebsiteAlive = async (network) => {
  const result = await network.fetchUrlText('http://example.com');

  if (!result.ok) {
    return { success: false, status: result.text };
  }

  const hasKeyword = result.text.includes('illustrative');
  return hasKeyword
    ? { success: true, status: 'ok' }
    : { success: false, status: 'missing text' };
};

// Step 3: Test with fake adapter
test('with good content, returns success', async () => {
  const fakeNetwork = {
    fetchUrlText: () => ({ ok: true, text: 'illustrative content' })
  };

  const result = await isWebsiteAlive(fakeNetwork);

  expect(result.success).toBe(true);
  expect(result.status).toBe('ok');
});

test('with bad content, returns failure', async () => {
  const fakeNetwork = {
    fetchUrlText: () => ({ ok: true, text: 'other content' })
  };

  const result = await isWebsiteAlive(fakeNetwork);

  expect(result.success).toBe(false);
  expect(result.status).toBe('missing text');
});

test('with network error, returns failure', async () => {
  const fakeNetwork = {
    fetchUrlText: () => ({ ok: false, text: 'Network error' })
  };

  const result = await isWebsiteAlive(fakeNetwork);

  expect(result.success).toBe(false);
});
```

**Benefits:**

- Clean separation of concerns
- Adapter hides complexity of real dependency
- Easy to create fake adapters for tests
- Tests use simple synchronous fakes (even though function is async)
- Real network code isolated in one place

## Test Quality

### Trust in Tests

**A trustworthy test:**

- When it **fails** → There's definitely a bug in production code
- When it **passes** → Production code definitely works
- Consistent results (no flakiness)
- Easy to understand what broke

**Tests lose trust when they:**

- Have logic (if/else, loops, try/catch)
- Test multiple concerns
- Are flaky (inconsistent pass/fail)
- Test implementation details vs behavior
- Are hard to understand

### Avoiding Logic in Tests

```javascript
// ❌ BAD - logic in test
test('sum handles various inputs', () => {
  const inputs = ['1,2', '3,4', '5,6'];

  for (const input of inputs) {
    const [a, b] = input.split(',');
    const expected = parseInt(a) + parseInt(b);
    const result = sum(input);

    if (expected > 5) {
      expect(result).toBeGreaterThan(5);
    } else {
      expect(result).toBeLessThanOrEqual(5);
    }
  }
});

// ✅ GOOD - no logic, clear assertions
test('sum with 1 and 2 returns 3', () => {
  expect(sum('1,2')).toBe(3);
});

test('sum with 3 and 4 returns 7', () => {
  expect(sum('3,4')).toBe(7);
});
```

### Dealing with Flaky Tests

**Common causes:**

- Time dependencies (Date.now(), setTimeout)
- Random values (Math.random())
- Network calls
- Filesystem operations
- Race conditions in async code
- Shared state between tests
- Test execution order dependencies

**Solutions:**

```javascript
// ❌ Flaky - depends on current time
test('validates date is in future', () => {
  const tomorrow = new Date(Date.now() + 86400000);
  expect(isValidFutureDate(tomorrow)).toBe(true);
});

// ✅ Fixed - inject time dependency
test('with future date, returns true', () => {
  const currentTime = new Date('2024-01-01');
  const futureDate = new Date('2024-01-02');
  expect(isValidFutureDate(futureDate, currentTime)).toBe(true);
});

// ❌ Flaky - depends on random value
test('generates unique ID', () => {
  const id = generateId(); // Uses Math.random() internally
  expect(id).toMatch(/^[a-z0-9]+$/);
});

// ✅ Fixed - inject random generator
test('generates ID with provided random function', () => {
  const fakeRandom = () => 0.5;
  const id = generateId(fakeRandom);
  expect(id).toBe('expected_deterministic_value');
});

// ❌ Flaky - shared state
let sharedCart = new ShoppingCart();

test('adds item to cart', () => {
  sharedCart.addItem('apple'); // Affects next test!
  expect(sharedCart.itemCount()).toBe(1);
});

// ✅ Fixed - isolated state
test('adds item to cart', () => {
  const cart = new ShoppingCart(); // Fresh instance
  cart.addItem('apple');
  expect(cart.itemCount()).toBe(1);
});
```

### Avoiding Overspecification

**Overspecification = testing implementation details instead of behavior**

```javascript
// ❌ BAD - tests implementation (how it works)
test('verify calls rules in specific order', () => {
  const mockRule1 = jest.fn();
  const mockRule2 = jest.fn();
  const verifier = new Verifier([mockRule1, mockRule2]);

  verifier.verify('input');

  // Too many implementation details!
  expect(mockRule1).toHaveBeenCalledBefore(mockRule2);
  expect(mockRule1).toHaveBeenCalledTimes(1);
  expect(mockRule2).toHaveBeenCalledTimes(1);
  expect(mockRule1).toHaveBeenCalledWith('input');
  expect(mockRule2).toHaveBeenCalledWith('input');
});

// ✅ GOOD - tests behavior (what it does)
test('verify with all passing rules returns success', () => {
  const passingRule1 = () => ({ passed: true });
  const passingRule2 = () => ({ passed: true });
  const verifier = new Verifier([passingRule1, passingRule2]);

  const result = verifier.verify('ValidInput123');

  expect(result.passed).toBe(true);
});

test('verify with one failing rule returns failure', () => {
  const passingRule = () => ({ passed: true });
  const failingRule = () => ({ passed: false, reason: 'Too short' });
  const verifier = new Verifier([passingRule, failingRule]);

  const result = verifier.verify('abc');

  expect(result.passed).toBe(false);
  expect(result.errors).toContain('Too short');
});
```

## Troubleshooting

### Test Isolation Issues

**Problem**: Tests pass individually but fail when run together

**Cause**: Shared state between tests

**Solution**:

```javascript
// Create fresh instances for each test
const makeVerifier = () => new Verifier();

// Or reset state in beforeEach
beforeEach(() => {
  jest.resetAllMocks();
  // Reset any global state
});
```

### Async Test Timeouts

**Problem**: Test times out with no clear error

**Solutions**:

```javascript
// 1. Make sure to return/await promises
test('async test', async () => {
  await asyncFunction(); // Don't forget await!
  expect(something).toBe(true);
});

// 2. Increase timeout for slow operations
test('slow operation', async () => {
  await slowFunction();
}, 10000); // 10 second timeout

// 3. For callbacks, call done()
test('callback test', (done) => {
  callbackFn((result) => {
    expect(result).toBe('value');
    done(); // Don't forget!
  });
});
```

### Mock Not Being Called

**Problem**: `expect(mock).toHaveBeenCalled()` fails but it should pass

**Solutions**:

```javascript
// 1. Verify mock is actually being used
test('logger is called', () => {
  const mockLogger = { info: jest.fn() };
  const verifier = new Verifier(mockLogger); // Is mock passed correctly?
  verifier.verify('input');
  expect(mockLogger.info).toHaveBeenCalled();
});

// 2. Check async timing
test('async logger is called', async () => {
  const mockLogger = { info: jest.fn() };
  const verifier = new Verifier(mockLogger);
  await verifier.verify('input'); // Don't forget await!
  expect(mockLogger.info).toHaveBeenCalled();
});

// 3. Verify method name is correct
test('uses correct method', () => {
  const mockLogger = { info: jest.fn(), log: jest.fn() };
  // Production code calls logger.log(), not logger.info()
  verifier.verify('input');
  expect(mockLogger.log).toHaveBeenCalled(); // Not .info!
});
```

### Tests Pass but Production Code is Broken

**Problem**: Tests pass but real usage fails

**Causes**:

1. Testing wrong thing (not testing actual requirement)
2. Mocking too much (not testing real behavior)
3. Tests don't cover edge cases
4. Tests have bugs

**Solutions**:

- Review what the test is actually verifying
- Reduce use of mocks (prefer return-value and state-based tests)
- Add tests for edge cases
- Verify tests fail when they should (TDD approach)
- Have integration tests to verify real scenarios

## Related Resources

- Main documentation: [SKILL.md](SKILL.md)
- Code examples: [EXAMPLES.md](EXAMPLES.md)
- "The Art of Unit Testing, Third Edition" by Roy Osherove (Manning, 2024)
- "Unit Testing Principles, Practices, and Patterns" by Vladimir Khorikov (Manning, 2020)
- "Working Effectively with Legacy Code" by Michael Feathers (Pearson, 2004)
- "xUnit Test Patterns" by Gerard Meszaros (Addison-Wesley, 2007)
