# Jest to Vitest Migration Reference

Comprehensive reference guide for migrating from Jest to Vitest, covering all API differences, configuration changes, and common pitfalls.

## Table of Contents

- [Pre-Migration Checklist](#pre-migration-checklist)
- [Automated Migration Tools](#automated-migration-tools)
- [API Mapping Reference](#api-mapping-reference)
- [Configuration Migration](#configuration-migration)
- [Common Migration Patterns](#common-migration-patterns)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Framework-Specific Migrations](#framework-specific-migrations)

## Pre-Migration Checklist

Before starting your migration:

- [ ] All Jest tests are passing
- [ ] Code is committed to version control
- [ ] Created migration branch
- [ ] Documented custom Jest configurations
- [ ] Identified Jest-specific plugins/extensions
- [ ] Reviewed Vitest compatibility of testing libraries
- [ ] Planned rollback strategy

## Automated Migration Tools

### vitest-codemod (Recommended)

**Installation & Usage:**

```bash
# Global installation
npm install -g @vitest-codemod/jest

# Run on entire test directory
vitest-codemod jest src/**/*.test.{js,ts,jsx,tsx}

# Run on specific files
vitest-codemod jest src/components/Button.test.tsx

# With custom parser
vitest-codemod jest --parser tsx src/**/*.test.tsx
```

**What it transforms:**

- Mock functions: `jest.fn()` → `vi.fn()`
- Mock modules: `jest.mock()` → `vi.mock()`
- Spy functions: `jest.spyOn()` → `vi.spyOn()`
- Timer mocks: `jest.useFakeTimers()` → `vi.useFakeTimers()`
- Mock clearing: `jest.clearAllMocks()` → `vi.clearAllMocks()`
- Mock resetting: `jest.resetAllMocks()` → `vi.resetAllMocks()`
- Mock implementation: `jest.requireActual()` → `vi.importActual()`

**Limitations:**

- Does not modify configuration files
- May miss complex mock patterns
- Requires manual review of transformed code
- Cannot handle dynamic mock patterns

### Codemod Platform

**VS Code Extension:**

1. Install "Codemod" extension
2. Right-click project folder
3. Select "Run Codemod"
4. Choose "Jest to Vitest"
5. Review and apply changes

**CLI Usage:**

```bash
# Interactive mode
npx codemod

# Select: Jest → Vitest transformation

# Direct execution
npx codemod jest/vitest

# Dry run (preview changes)
npx codemod jest/vitest --dry
```

### Manual Find & Replace Patterns

For quick manual migration, use these regex patterns:

```bash
# Basic API replacements
jest\.fn → vi.fn
jest\.spyOn → vi.spyOn
jest\.mock → vi.mock
jest\.unmock → vi.unmock
jest\.clearAllMocks → vi.clearAllMocks
jest\.resetAllMocks → vi.resetAllMocks
jest\.restoreAllMocks → vi.restoreAllMocks
jest\.useFakeTimers → vi.useFakeTimers
jest\.useRealTimers → vi.useRealTimers
jest\.runAllTimers → vi.runAllTimers
jest\.advanceTimersByTime → vi.advanceTimersByTime
jest\.setTimeout → vi.setConfig\({ testTimeout:

# Import statements
from 'jest' → from 'vitest'
from "@jest → from "@vitest
```

## API Mapping Reference

### Complete Jest to Vitest API Map

#### Mock Functions

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.fn()` | `vi.fn()` | Identical behavior |
| `jest.fn(impl)` | `vi.fn(impl)` | Identical behavior |
| `mockFn.mockReturnValue(val)` | `mockFn.mockReturnValue(val)` | Identical |
| `mockFn.mockResolvedValue(val)` | `mockFn.mockResolvedValue(val)` | Identical |
| `mockFn.mockRejectedValue(err)` | `mockFn.mockRejectedValue(err)` | Identical |
| `mockFn.mockImplementation(fn)` | `mockFn.mockImplementation(fn)` | Identical |
| `mockFn.mockClear()` | `mockFn.mockClear()` | Identical |
| `mockFn.mockReset()` | `mockFn.mockReset()` | ⚠️ **Different behavior** |
| `mockFn.mockRestore()` | `mockFn.mockRestore()` | Identical |

**Important**: Vitest's `mockReset()` behaves differently than Jest's:
- **Jest**: Resets to empty function returning `undefined`
- **Vitest**: Resets to original implementation

```typescript
// To match Jest's mockReset behavior in Vitest:
mockFn.mockReset()
mockFn.mockImplementation(() => undefined)
```

#### Spying

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.spyOn(obj, 'method')` | `vi.spyOn(obj, 'method')` | Identical |
| `jest.spyOn(obj, 'prop', 'get')` | `vi.spyOn(obj, 'prop', 'get')` | Identical |
| `jest.spyOn(obj, 'prop', 'set')` | `vi.spyOn(obj, 'prop', 'set')` | Identical |

#### Module Mocking

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.mock('./module')` | `vi.mock('./module')` | Different factory behavior |
| `jest.unmock('./module')` | `vi.unmock('./module')` | Identical |
| `jest.doMock('./module')` | `vi.doMock('./module')` | Identical |
| `jest.dontMock('./module')` | `vi.dontMock('./module')` | Identical |
| `jest.requireActual('./module')` | `await vi.importActual('./module')` | ⚠️ **Async in Vitest** |
| `jest.requireMock('./module')` | `await vi.importMock('./module')` | ⚠️ **Async in Vitest** |

**Module Mock Factory Differences:**

```typescript
// Jest - factory return value becomes default export
jest.mock('./module', () => 'hello')
// Equivalent to:
jest.mock('./module', () => ({ default: 'hello' }))

// Vitest - must explicitly define exports
vi.mock('./module', () => ({ default: 'hello' }))
```

#### Timers

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.useFakeTimers()` | `vi.useFakeTimers()` | Identical |
| `jest.useFakeTimers('modern')` | `vi.useFakeTimers()` | Modern is default |
| `jest.useFakeTimers('legacy')` | ❌ Not supported | Use modern timers |
| `jest.useRealTimers()` | `vi.useRealTimers()` | Identical |
| `jest.runAllTimers()` | `vi.runAllTimers()` | Identical |
| `jest.runOnlyPendingTimers()` | `vi.runOnlyPendingTimers()` | Identical |
| `jest.advanceTimersByTime(ms)` | `vi.advanceTimersByTime(ms)` | Identical |
| `jest.clearAllTimers()` | `vi.clearAllTimers()` | Identical |
| `jest.getTimerCount()` | `vi.getTimerCount()` | Identical |
| `jest.setSystemTime(time)` | `vi.setSystemTime(time)` | Identical |
| `jest.getRealSystemTime()` | `vi.getRealSystemTime()` | Identical |

#### Global Mocks

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.clearAllMocks()` | `vi.clearAllMocks()` | Identical |
| `jest.resetAllMocks()` | `vi.resetAllMocks()` | Identical |
| `jest.restoreAllMocks()` | `vi.restoreAllMocks()` | Identical |
| `jest.resetModules()` | `vi.resetModules()` | Identical |

#### Test Configuration

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.setTimeout(ms)` | `vi.setConfig({ testTimeout: ms })` | ⚠️ **Different API** |
| `jest.retryTimes(n)` | `test.retry(n)` | ⚠️ **Different API** |

#### Matchers & Assertions

All Jest matchers work identically in Vitest:

```typescript
expect(value).toBe(expected)
expect(value).toEqual(expected)
expect(value).toBeTruthy()
expect(value).toBeFalsy()
expect(array).toContain(item)
expect(object).toHaveProperty('key')
expect(fn).toHaveBeenCalled()
expect(fn).toHaveBeenCalledWith(args)
expect(fn).toHaveBeenCalledTimes(n)
expect(promise).resolves.toBe(value)
expect(promise).rejects.toThrow()
// ... all other matchers work the same
```

## Configuration Migration

### Jest Config → Vitest Config Mapping

#### Basic Structure

```javascript
// jest.config.js (Jest)
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testMatch: ['**/*.test.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  }
}

// vitest.config.ts (Vitest)
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['**/*.test.js'],
  },
  resolve: {
    alias: {
      '@': '/src'
    }
  }
})
```

#### Configuration Property Mapping

| Jest | Vitest | Notes |
|------|--------|-------|
| `testEnvironment` | `test.environment` | Same values |
| `setupFiles` | `test.setupFiles` | Identical |
| `setupFilesAfterEnv` | `test.setupFiles` | No distinction |
| `testMatch` | `test.include` | Different syntax |
| `testPathIgnorePatterns` | `test.exclude` | Use glob patterns |
| `moduleNameMapper` | `resolve.alias` | Different format |
| `transform` | ❌ Use Vite plugins | Not needed |
| `globals` | `test.globals` | Enable for compatibility |
| `coverageDirectory` | `test.coverage.reportsDirectory` | Different nesting |
| `coverageReporters` | `test.coverage.reporter` | Same values |
| `collectCoverageFrom` | `test.coverage.include` | Use glob patterns |
| `coveragePathIgnorePatterns` | `test.coverage.exclude` | Use glob patterns |
| `testTimeout` | `test.testTimeout` | Identical |
| `clearMocks` | `test.clearMocks` | Identical |
| `resetMocks` | `test.mockReset` | Identical |
| `restoreMocks` | `test.restoreMocks` | Identical |
| `verbose` | ❌ Use reporters | Different approach |
| `maxWorkers` | `test.maxWorkers` | Identical |
| `bail` | `test.bail` | Identical |

### Environment Configuration

```typescript
// Jest
{
  testEnvironment: 'jsdom',
  testEnvironmentOptions: {
    url: 'http://localhost'
  }
}

// Vitest
{
  test: {
    environment: 'jsdom', // or 'happy-dom' for faster alternative
    environmentOptions: {
      jsdom: {
        url: 'http://localhost'
      }
    }
  }
}
```

### Path Aliases

```typescript
// Jest
{
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@components/(.*)$': '<rootDir>/src/components/$1',
    '\\.(css|less|scss)$': 'identity-obj-proxy'
  }
}

// Vitest
import path from 'path'

{
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
    }
  },
  // For CSS modules, no need for identity-obj-proxy
  // Vitest handles CSS imports automatically
}
```

### Transform Configuration

Jest's `transform` is NOT needed in Vitest. Vite handles transformations automatically.

```typescript
// Jest (NOT needed in Vitest)
{
  transform: {
    '^.+\\.tsx?$': 'ts-jest',
    '^.+\\.jsx?$': 'babel-jest'
  }
}

// Vitest - automatic, no configuration needed!
// For special transforms, use Vite plugins instead
{
  plugins: [
    myCustomVitePlugin()
  ]
}
```

### Coverage Configuration

```typescript
// Jest
{
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  collectCoverageFrom: [
    'src/**/*.{js,ts}',
    '!src/**/*.d.ts'
  ],
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/dist/'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
}

// Vitest
{
  test: {
    coverage: {
      enabled: true, // or use --coverage flag
      provider: 'v8', // or 'istanbul' to match Jest
      reportsDirectory: './coverage',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.{js,ts}'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.d.ts'
      ],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80
      }
    }
  }
}
```

## Common Migration Patterns

### Pattern 1: Mocking Modules

```typescript
// Jest
jest.mock('./api', () => ({
  fetchUser: jest.fn()
}))

// Vitest - identical!
vi.mock('./api', () => ({
  fetchUser: vi.fn()
}))
```

### Pattern 2: Mocking with Implementation

```typescript
// Jest
const mockFetch = jest.fn()
mockFetch.mockImplementation(() =>
  Promise.resolve({ json: () => ({ data: 'test' }) })
)

// Vitest - identical!
const mockFetch = vi.fn()
mockFetch.mockImplementation(() =>
  Promise.resolve({ json: () => ({ data: 'test' }) })
)
```

### Pattern 3: Partial Module Mocking

```typescript
// Jest
jest.mock('./utils', () => ({
  ...jest.requireActual('./utils'),
  specificFn: jest.fn()
}))

// Vitest - note async!
vi.mock('./utils', async () => ({
  ...await vi.importActual('./utils'),
  specificFn: vi.fn()
}))
```

### Pattern 4: Auto-Mocking Dependencies

```typescript
// Jest - auto-mocks __mocks__ directory
// __mocks__/api.js exists, automatically used

// Vitest - must explicitly mock
// __mocks__/api.js
export const fetchUser = vi.fn()

// test file
vi.mock('./api') // Now uses __mocks__/api.js
```

### Pattern 5: Callback-Based Tests

```typescript
// Jest - supports done callback
test('async operation', (done) => {
  doAsync(() => {
    expect(true).toBe(true)
    done()
  })
})

// Vitest - use async/await
test('async operation', async () => {
  await new Promise(resolve => {
    doAsync(() => {
      expect(true).toBe(true)
      resolve()
    })
  })
})
```

### Pattern 6: beforeEach/afterEach Cleanup

```typescript
// Jest & Vitest - identical!
beforeEach(() => {
  // Setup
})

afterEach(() => {
  // Cleanup
  vi.clearAllMocks() // or jest.clearAllMocks()
})
```

### Pattern 7: Snapshot Testing

```typescript
// Jest & Vitest - identical!
test('component snapshot', () => {
  const result = render(<Component />)
  expect(result).toMatchSnapshot()
})

// Update snapshots: npm run test -- -u
```

## Troubleshooting Guide

### Issue: "vi is not defined"

**Cause**: Not importing `vi` from vitest

**Solution**:

```typescript
// Add import
import { vi } from 'vitest'

// OR enable globals
// vitest.config.ts
export default defineConfig({
  test: { globals: true }
})

// tsconfig.json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

### Issue: "Cannot find module '@testing-library/jest-dom'"

**Cause**: Package name didn't change, but imports might need updating

**Solution**:

```typescript
// Keep jest-dom package
npm install -D @testing-library/jest-dom

// Import in setup file
// vitest.setup.ts
import '@testing-library/jest-dom'

// OR for explicit imports
import '@testing-library/jest-dom/vitest'
```

### Issue: "cleanup not running automatically"

**Cause**: With `globals: false`, testing-library auto-cleanup disabled

**Solution**:

```typescript
// vitest.setup.ts
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

afterEach(() => {
  cleanup()
})
```

### Issue: "Mock not resetting between tests"

**Cause**: `mockReset` behavior difference or missing config

**Solution**:

```typescript
// Option 1: Configure auto-reset
// vitest.config.ts
export default defineConfig({
  test: {
    clearMocks: true,
    mockReset: true,
    restoreMocks: true,
  }
})

// Option 2: Manual cleanup
afterEach(() => {
  vi.clearAllMocks()
  vi.resetAllMocks()
})
```

### Issue: "Snapshots have different formatting"

**Cause**: Test name separator changed from space to `>`

**Solution**:

```bash
# Regenerate all snapshots
npm run test -- -u

# Or manually update snapshot files
# Change: "describe title test title"
# To: "describe title > test title"
```

### Issue: "Path aliases not resolving"

**Cause**: `moduleNameMapper` not configured in Vitest

**Solution**:

```typescript
// vitest.config.ts
import path from 'path'

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
    }
  }
})
```

### Issue: "CSS/SCSS imports failing"

**Cause**: Missing CSS handling configuration

**Solution**:

```typescript
// Vitest handles CSS automatically, but for CSS modules:
// vitest.config.ts
export default defineConfig({
  css: {
    modules: {
      classNameStrategy: 'non-scoped'
    }
  }
})

// Or mock CSS imports
vi.mock('./styles.css', () => ({}))
```

### Issue: "Dynamic imports not working"

**Cause**: Vitest handles dynamic imports differently

**Solution**:

```typescript
// Ensure using await with vi.importActual
vi.mock('./module', async () => {
  const actual = await vi.importActual('./module')
  return {
    ...actual,
    override: vi.fn()
  }
})
```

### Issue: "Tests slower than Jest"

**Cause**: Wrong environment or pool configuration

**Solution**:

```typescript
// Use faster environment
export default defineConfig({
  test: {
    environment: 'happy-dom', // instead of 'jsdom'

    // Optimize pool
    pool: 'threads', // or 'forks'

    // Reduce isolation overhead
    isolate: false, // use with caution

    // Increase parallelism
    maxWorkers: 4,
  }
})
```

### Issue: "beforeAll return value causing issues"

**Cause**: Vitest interprets return values as cleanup functions

**Solution**:

```typescript
// Jest - return value ignored
beforeAll(() => {
  return someValue
})

// Vitest - wrap in function body if not cleanup
beforeAll(() => {
  const value = someValue
  // Don't return unless it's a cleanup function
})

// Or explicitly return undefined
beforeAll(() => {
  setup()
  return undefined
})
```

## Framework-Specific Migrations

### React Testing Library

**Migration**: Mostly seamless!

```typescript
// No changes needed for most code
import { render, screen } from '@testing-library/react'
import { describe, test, expect } from 'vitest'

describe('Component', () => {
  test('renders', () => {
    render(<Component />)
    expect(screen.getByText('Hello')).toBeInTheDocument()
  })
})
```

**Setup file changes**:

```typescript
// jest.setup.js → vitest.setup.ts
import '@testing-library/jest-dom'

// If globals disabled, add cleanup
import { afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'

afterEach(() => {
  cleanup()
})
```

### Vue Test Utils

**Migration**: Minimal changes

```typescript
// Works the same way
import { mount } from '@vue/test-utils'
import { describe, test, expect } from 'vitest'

describe('Component', () => {
  test('renders', () => {
    const wrapper = mount(Component)
    expect(wrapper.text()).toContain('Hello')
  })
})
```

### Angular Testing

**Migration**: More complex, requires additional setup

```typescript
// Install Vitest Angular dependencies
npm install -D @analogjs/vite-plugin-angular

// vitest.config.ts
import { defineConfig } from 'vitest/config'
import angular from '@analogjs/vite-plugin-angular'

export default defineConfig({
  plugins: [angular()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['src/test-setup.ts'],
  },
})
```

See: <https://cookbook.marmicode.io/angular/testing/migrating-to-vitest>

### Next.js

**Migration**: Requires Vite config adjustments

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: './vitest.setup.ts',
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    }
  }
})
```

### Node.js (Backend) Tests

**Migration**: Very straightforward

```typescript
// Usually just API changes, no config needed
// vitest.config.ts
export default defineConfig({
  test: {
    environment: 'node', // explicit, though it's default
  }
})
```

## Migration Validation Checklist

After migration, verify:

- [ ] All tests passing
- [ ] Coverage reports generated correctly
- [ ] CI/CD pipeline updated and working
- [ ] Watch mode functioning
- [ ] Snapshots regenerated and committed
- [ ] Mock behaviors correct
- [ ] TypeScript types working
- [ ] Import paths resolving
- [ ] Test execution speed acceptable
- [ ] No console errors or warnings
- [ ] Team documentation updated
- [ ] Old Jest dependencies removed

## Rollback Plan

If migration fails:

1. **Revert branch**:
   ```bash
   git checkout main
   git branch -D vitest-migration
   ```

2. **Restore package.json**:
   ```bash
   npm install -D jest @types/jest ts-jest
   npm uninstall vitest @vitest/ui
   ```

3. **Keep learnings**: Document issues for future attempts

## Performance Comparison

Expected improvements after migration:

| Metric | Jest | Vitest | Improvement |
|--------|------|--------|-------------|
| Cold start | 5-10s | 1-2s | 5x faster |
| Watch mode reload | 2-5s | <1s | 5x faster |
| Test execution | Baseline | 1.5-2x faster | 2x faster |
| TypeScript tests | Slow (ts-jest) | Fast (native) | 10x faster |

Note: Actual improvements vary by project size and complexity.

## Additional Resources

- Vitest migration guide: <https://vitest.dev/guide/migration>
- vitest-codemod repo: <https://github.com/trivikr/vitest-codemod>
- Vitest vs Jest comparison: <https://vitest.dev/guide/comparisons>
- Vitest Discord: <https://chat.vitest.dev>
