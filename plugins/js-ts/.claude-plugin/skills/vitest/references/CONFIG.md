# Vitest Configuration Reference

Complete reference for Vitest configuration options with examples and best practices.

## Table of Contents

- [Basic Setup](#basic-setup)
- [Test Configuration](#test-configuration)
- [Environment Configuration](#environment-configuration)
- [Coverage Configuration](#coverage-configuration)
- [Mocking Configuration](#mocking-configuration)
- [Performance Optimization](#performance-optimization)
- [Workspace Configuration](#workspace-configuration)
- [Common Configurations](#common-configurations)

## Basic Setup

### Minimal Configuration

For projects without Vite:

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    // Your test configuration
  },
})
```

### With Existing Vite Configuration

```typescript
// vitest.config.ts
/// <reference types="vitest/config" />
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    // Vitest options
  },
  // Other Vite options
})
```

### Merging Configurations

```typescript
// vitest.config.ts
import { defineConfig, mergeConfig } from 'vitest/config'
import viteConfig from './vite.config'

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      // Test-specific overrides
    }
  })
)
```

### Conditional Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'

export default defineConfig(({ mode }) => ({
  test: mode === 'test' ? {
    // Test configuration
  } : undefined,
}))
```

## Test Configuration

### File Matching

```typescript
export default defineConfig({
  test: {
    // Include test files (default shown)
    include: [
      '**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'
    ],

    // Exclude files/directories (extends default)
    exclude: [
      '**/node_modules/**',
      '**/dist/**',
      '**/cypress/**',
      '**/.{idea,git,cache,output,temp}/**',
      '**/{karma,rollup,webpack,vite,vitest,jest,ava,babel,nyc,cypress,tsup,build}.config.*',
      // Add custom exclusions
      '**/mockData/**',
      '**/*.integration.test.ts'
    ],

    // Only run files matching pattern
    includeSource: ['src/**/*.{js,ts}'],
  }
})
```

### Test Execution

```typescript
export default defineConfig({
  test: {
    // Timeout configuration (milliseconds)
    testTimeout: 5000,        // Individual test timeout
    hookTimeout: 10000,       // beforeAll/afterAll timeout

    // Retry failed tests
    retry: 0,                 // Number of retries (0 = no retries)

    // Bail on first failure
    bail: 0,                  // Stop after N failures (0 = run all)

    // Test isolation
    isolate: true,            // Run each test file in isolation

    // File-level parallelism
    fileParallelism: true,    // Run test files in parallel

    // Sequence control
    sequence: {
      shuffle: false,         // Randomize test order
      concurrent: false,      // Allow test.concurrent
      seed: Date.now(),       // Seed for shuffle
      hooks: 'parallel',      // Run hooks in parallel ('stack' for sequential)
      setupFiles: 'parallel', // Run setup files in parallel
    },

    // Minimum passing tests required
    passWithNoTests: false,   // Fail if no tests found

    // Allow only tests marked with .only
    allowOnly: false,         // Set true for local dev, false for CI
  }
})
```

### Global API

```typescript
export default defineConfig({
  test: {
    // Enable globals (describe, it, expect, etc.)
    globals: true,

    // Alternative: import explicitly
    // import { describe, it, expect } from 'vitest'
  }
})
```

If using globals, update `tsconfig.json`:

```json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

### Setup Files

```typescript
export default defineConfig({
  test: {
    // Runs before each test file
    setupFiles: [
      './vitest.setup.ts',
      './test/global-setup.ts'
    ],

    // Runs once before all tests
    globalSetup: './vitest.global.ts',
  }
})
```

**Example setup file**:

```typescript
// vitest.setup.ts
import { beforeAll, afterAll } from 'vitest'
import '@testing-library/jest-dom'

beforeAll(() => {
  // Global setup
})

afterAll(() => {
  // Global cleanup
})
```

**Example global setup**:

```typescript
// vitest.global.ts
export async function setup() {
  // Start test database, mock servers, etc.
  console.log('Global setup')
}

export async function teardown() {
  // Cleanup global resources
  console.log('Global teardown')
}
```

## Environment Configuration

### Environment Selection

```typescript
export default defineConfig({
  test: {
    // Test environment
    environment: 'node',      // Default: Node.js environment
    // environment: 'jsdom',  // Browser-like environment (slower)
    // environment: 'happy-dom', // Faster browser-like environment
    // environment: 'edge-runtime', // Edge runtime environment

    // Environment options
    environmentOptions: {
      jsdom: {
        url: 'http://localhost:3000',
        referrer: 'https://example.com',
        contentType: 'text/html',
        storageQuota: 10000000
      }
    },

    // Environment matching patterns
    environmentMatchGlobs: [
      // Files matching pattern use specified environment
      ['**/*.dom.test.ts', 'jsdom'],
      ['**/*.node.test.ts', 'node'],
    ],
  }
})
```

### Environment Comparison

| Environment | Use Case | Speed | Browser APIs |
|-------------|----------|-------|--------------|
| `node` | Backend, utilities | Fastest | None |
| `happy-dom` | Frontend components | Fast | Most common |
| `jsdom` | Frontend (complete) | Slower | Comprehensive |
| `edge-runtime` | Edge functions | Fast | Edge-specific |

**Recommendation**: Use `happy-dom` for frontend tests unless you need specific jsdom features.

### Per-File Environment

Use JSDoc comments:

```typescript
// @vitest-environment jsdom
import { test, expect } from 'vitest'

test('uses jsdom environment', () => {
  expect(window).toBeDefined()
  expect(document).toBeDefined()
})
```

## Coverage Configuration

### Basic Coverage

```typescript
export default defineConfig({
  test: {
    coverage: {
      // Enable coverage (or use --coverage flag)
      enabled: false,

      // Coverage provider
      provider: 'v8',         // Fast, default
      // provider: 'istanbul', // More accurate, slower

      // Reports directory
      reportsDirectory: './coverage',

      // Report formats
      reporter: [
        'text',               // Console output
        'html',               // HTML report
        'json',               // JSON output
        'lcov',               // LCOV format (for CI tools)
      ],

      // Clean coverage directory before running
      clean: true,

      // Clean on watch rerun
      cleanOnRerun: true,
    }
  }
})
```

### Coverage Filtering

```typescript
export default defineConfig({
  test: {
    coverage: {
      // Files to include in coverage
      include: [
        'src/**/*.{js,ts,jsx,tsx}'
      ],

      // Files to exclude from coverage
      exclude: [
        'node_modules/',
        'dist/',
        'build/',
        '**/*.d.ts',
        '**/*.config.{js,ts}',
        '**/mockData/**',
        '**/*.test.{js,ts}',
        '**/*.spec.{js,ts}',
      ],

      // Exclude files/lines based on comments
      excludeNodeModules: true,
    }
  }
})
```

### Coverage Thresholds

```typescript
export default defineConfig({
  test: {
    coverage: {
      // Global thresholds (fail if not met)
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,

        // Auto-update thresholds (useful for ratcheting up)
        autoUpdate: false,

        // Per-file thresholds
        perFile: false,
      },

      // Fail on threshold violations
      skipFull: false,          // Skip files with 100% coverage
    }
  }
})
```

### Istanbul Provider (Jest-compatible)

```bash
# Install Istanbul provider
npm install -D @vitest/coverage-istanbul
```

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',

      // Istanbul-specific options
      all: true,              // Include all files, even untested
      skipFull: false,        // Include 100% covered files

      // Report watermarks (colors in report)
      watermarks: {
        statements: [50, 80],
        functions: [50, 80],
        branches: [50, 80],
        lines: [50, 80]
      }
    }
  }
})
```

## Mocking Configuration

### Mock Behavior

```typescript
export default defineConfig({
  test: {
    // Clear mock history before each test
    clearMocks: true,

    // Reset mock implementation before each test
    mockReset: false,         // Different from Jest!

    // Restore original implementation before each test
    restoreMocks: true,

    // Un-mock all modules after each test
    unmockedModulePathPatterns: [],

    // Modules to not mock
    unmocked: [],
  }
})
```

**Important**: Vitest's `mockReset: true` resets to original implementation, not empty function like Jest.

### Module Resolution

```typescript
export default defineConfig({
  resolve: {
    // Path aliases
    alias: {
      '@': '/src',
      '@components': '/src/components',
      '@utils': '/src/utils',
    },

    // Module extensions
    extensions: ['.mjs', '.js', '.ts', '.jsx', '.tsx', '.json'],

    // Dedupe packages
    dedupe: ['react', 'react-dom'],

    // Conditions for package.json exports
    conditions: ['development', 'browser'],

    // Main fields for package resolution
    mainFields: ['module', 'jsnext:main', 'jsnext'],
  }
})
```

### Server Configuration (for imports)

```typescript
export default defineConfig({
  server: {
    // Dependency optimization
    deps: {
      // Inline dependencies (don't pre-bundle)
      inline: [
        /virtual:/,
        /\.(css|scss)$/,
      ],

      // External dependencies (optimize separately)
      external: ['some-package'],

      // Fallback to CJS for these packages
      fallbackCJS: true,
    }
  }
})
```

## Performance Optimization

### Pool Configuration

```typescript
export default defineConfig({
  test: {
    // Execution pool type
    pool: 'threads',          // Default: worker threads
    // pool: 'forks',         // Process forks (better isolation)
    // pool: 'vmThreads',     // VM threads (TypeScript performance)

    // Pool options
    poolOptions: {
      threads: {
        // Minimum threads
        minThreads: 1,

        // Maximum threads
        maxThreads: 4,

        // Use Atomics for communication (faster)
        useAtomics: true,

        // Isolate environment
        isolate: true,
      },

      forks: {
        minForks: 1,
        maxForks: 4,
        isolate: true,
      },

      vmThreads: {
        minThreads: 1,
        maxThreads: 4,
        useAtomics: true,
        memoryLimit: '512MB',
      }
    },

    // Max concurrent tests per file
    maxConcurrency: 5,

    // Max workers
    maxWorkers: 4,            // undefined = CPU cores

    // Min workers
    minWorkers: 1,
  }
})
```

### Optimization Recommendations

```typescript
export default defineConfig({
  test: {
    // Fastest configuration (use carefully!)
    pool: 'threads',
    poolOptions: {
      threads: {
        useAtomics: true,
      }
    },
    isolate: false,           // Disable isolation (faster, less safe)
    fileParallelism: true,
    maxWorkers: undefined,    // Use all CPU cores

    // Faster environment
    environment: 'node',      // or 'happy-dom' instead of 'jsdom'

    // Reduce overhead
    coverage: {
      enabled: false,         // Disable during development
    },
  }
})
```

### Cache Configuration

```typescript
export default defineConfig({
  test: {
    // Cache test results
    cache: {
      dir: 'node_modules/.vitest',
    },
  },

  cacheDir: '.vite',          // Vite cache directory
})
```

## Workspace Configuration

For monorepos or projects with multiple test configurations:

```typescript
// vitest.workspace.ts
import { defineWorkspace } from 'vitest/config'

export default defineWorkspace([
  // Workspace projects as file paths
  'packages/*',
  'apps/*',

  // Or inline configurations
  {
    test: {
      name: 'unit',
      include: ['**/*.unit.test.ts'],
      environment: 'node',
    }
  },
  {
    test: {
      name: 'integration',
      include: ['**/*.integration.test.ts'],
      environment: 'jsdom',
      testTimeout: 10000,
    }
  },
  {
    test: {
      name: 'browser',
      include: ['**/*.browser.test.ts'],
      environment: 'happy-dom',
    }
  },
])
```

### Project-Specific Configuration

```typescript
// packages/frontend/vitest.config.ts
import { defineProject } from 'vitest/config'

export default defineProject({
  test: {
    name: 'frontend',
    environment: 'happy-dom',
    setupFiles: ['./vitest.setup.ts'],
  }
})
```

## Reporting Configuration

```typescript
export default defineConfig({
  test: {
    // Reporters
    reporters: [
      'default',              // Console reporter
      'verbose',              // Verbose output
      'json',                 // JSON output
      'junit',                // JUnit XML
      'html',                 // HTML report
      'hanging-process',      // Detect hanging processes
    ],

    // Output files for reporters
    outputFile: {
      json: './test-results.json',
      junit: './junit.xml',
      html: './test-report.html',
    },

    // Silent mode (no console output)
    silent: false,

    // Hide successful tests (only show failures)
    hideSkippedTests: false,

    // Expand error details
    expandSnapshotDiff: true,
  }
})
```

### Custom Reporter

```typescript
// custom-reporter.ts
import { Reporter } from 'vitest/reporters'

export default class CustomReporter implements Reporter {
  onInit(ctx) {
    console.log('Tests starting...')
  }

  onFinished(files, errors) {
    console.log('Tests finished!')
  }
}

// vitest.config.ts
import CustomReporter from './custom-reporter'

export default defineConfig({
  test: {
    reporters: [
      'default',
      new CustomReporter()
    ]
  }
})
```

## Common Configurations

### React Project

```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './vitest.setup.ts',
    css: true,                // Enable CSS processing
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/setupTests.ts',
      ]
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    }
  }
})
```

### Vue Project

```typescript
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './vitest.setup.ts',
  }
})
```

### TypeScript Project

```typescript
import { defineConfig } from 'vitest/config'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['**/*.d.ts', '**/*.test.ts'],
    },
  }
})
```

### Node.js Backend

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    clearMocks: true,
    restoreMocks: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      exclude: [
        'dist/',
        '**/*.test.ts',
        'src/types/**',
      ]
    },
    pool: 'forks',            // Better for Node.js
  }
})
```

### Monorepo Root

```typescript
// vitest.workspace.ts
import { defineWorkspace } from 'vitest/config'

export default defineWorkspace([
  {
    test: {
      name: '@myapp/core',
      root: './packages/core',
      environment: 'node',
    }
  },
  {
    test: {
      name: '@myapp/web',
      root: './packages/web',
      environment: 'happy-dom',
    }
  },
  {
    test: {
      name: '@myapp/api',
      root: './packages/api',
      environment: 'node',
    }
  }
])
```

### CI/CD Configuration

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    // CI-specific settings
    globals: true,
    reporters: ['verbose', 'junit'],
    outputFile: {
      junit: './test-results/junit.xml'
    },
    coverage: {
      enabled: true,
      provider: 'v8',
      reporter: ['text', 'lcov', 'json'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      }
    },

    // Strict mode for CI
    allowOnly: false,         // Fail if .only tests exist
    passWithNoTests: false,   // Fail if no tests found
    bail: 1,                  // Stop on first failure

    // Prevent hanging
    testTimeout: 30000,
    hookTimeout: 30000,
  }
})
```

## Configuration Defaults

Vitest includes sensible defaults. Access them:

```typescript
import { configDefaults } from 'vitest/config'

export default defineConfig({
  test: {
    // Extend defaults
    exclude: [
      ...configDefaults.exclude,
      'e2e/**'
    ],
    coverage: {
      exclude: [
        ...configDefaults.coverage.exclude,
        'custom/**'
      ]
    }
  }
})
```

## Environment-Specific Configuration

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig(({ mode }) => ({
  test: {
    globals: true,
    environment: mode === 'production' ? 'node' : 'happy-dom',
    coverage: {
      enabled: mode === 'ci',
    },
    reporters: mode === 'ci' ? ['verbose', 'junit'] : ['default'],
  }
}))
```

## TypeScript Support

Vitest automatically handles TypeScript. No transform configuration needed!

**For additional type safety**:

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import type { UserConfig } from 'vitest/config'

const config: UserConfig = {
  test: {
    // Fully typed!
  }
}

export default defineConfig(config)
```

## Debugging Configuration

```typescript
export default defineConfig({
  test: {
    // Enable inspector
    inspect: true,            // Opens debugger
    inspectBrk: true,         // Break on first line

    // Single threaded for debugging
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: true,   // Run in single thread
      }
    },

    // Verbose output
    reporters: ['verbose'],

    // Increase timeouts
    testTimeout: 300000,      // 5 minutes
    hookTimeout: 300000,
  }
})
```

## Additional Resources

- Official config reference: <https://vitest.dev/config/>
- Vite config reference: <https://vitejs.dev/config/>
- Config IntelliSense: Add `/// <reference types="vitest/config" />`
