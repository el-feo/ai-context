# Automated Jest to Vitest Migration Scripts

This guide explains how to use the automated migration scripts to convert your Jest tests to Vitest.

## Available Scripts

Two migration scripts are provided in the `scripts/` directory:

### 1. Quick Migration (`quick-migrate.sh`)

**Best for:** Simple projects, fast migration, learning Vitest

**Time:** ~30 seconds

**What it does:**

- Removes Jest dependencies
- Installs Vitest and happy-dom
- Runs automated codemod transformations
- Creates basic vitest.config.ts
- Updates package.json scripts
- Cleans up old Jest config files

**Usage:**

```bash
# From your project root
curl -O https://raw.githubusercontent.com/[path]/quick-migrate.sh
chmod +x quick-migrate.sh
./quick-migrate.sh
```

Or copy from: `~/.claude/skills/vitest/scripts/quick-migrate.sh`

### 2. Comprehensive Migration (`comprehensive-migrate.sh`)

**Best for:** Production projects, complex setups, detailed control

**Time:** 5-10 minutes

**What it does:**
- All quick migration features, plus:
- Pre-migration validation
- Detects project type (React/Vue/Node)
- Creates backup branches
- Verifies tests before and after
- Smart configuration based on project type
- Detailed logging and error handling
- Rollback instructions

**Usage:**

```bash
# From your project root
curl -O https://raw.githubusercontent.com/[path]/comprehensive-migrate.sh
chmod +x comprehensive-migrate.sh
./comprehensive-migrate.sh
```

Or copy from: `~/.claude/skills/vitest/scripts/comprehensive-migrate.sh`

## Configuration Options

Edit these variables at the top of `comprehensive-migrate.sh`:

```bash
USE_CODEMOD=true          # Enable/disable automated transformations
USE_HAPPY_DOM=true        # Use happy-dom (true) or jsdom (false)
TEST_PATTERNS='src/**/*.{test,spec}.{js,ts,jsx,tsx}'  # Test file patterns
```

## Prerequisites

Both scripts require:

- Git repository initialized
- Node.js and npm installed
- Jest currently installed and working
- All tests passing before migration

## What Gets Migrated

### Dependencies

**Removed:**
- jest
- @types/jest
- ts-jest
- jest-environment-jsdom
- @jest/globals
- babel-jest
- jest-transform-stub

**Added:**
- vitest
- @vitest/ui
- happy-dom (or jsdom)
- @vitejs/plugin-react (if React detected)
- @vitejs/plugin-vue (if Vue detected)

### Code Transformations

The codemod automatically converts:

```typescript
// Before
jest.fn()
jest.spyOn()
jest.mock()
jest.useFakeTimers()
jest.clearAllMocks()

// After
vi.fn()
vi.spyOn()
vi.mock()
vi.useFakeTimers()
vi.clearAllMocks()
```

### Configuration Files

**Created:**
- `vitest.config.ts` - Vitest configuration
- `vitest.setup.ts` - Test setup file

**Removed:**
- `jest.config.js`
- `jest.config.ts`
- `jest.setup.js`
- `jest.setup.ts`

**Updated:**
- `package.json` - Scripts updated
- `tsconfig.json` - Types updated to vitest/globals

## Post-Migration Verification

After running either script:

1. **Review changes:**
   ```bash
   git diff
   ```

2. **Run tests:**
   ```bash
   npm test
   ```

3. **Check coverage:**
   ```bash
   npm run test:coverage
   ```

4. **Try UI mode:**
   ```bash
   npm run test:ui
   ```

## Rollback Procedure

### For Quick Migration

```bash
# Undo last commit
git reset --hard HEAD~1

# Reinstall Jest
npm install -D jest @types/jest ts-jest
```

### For Comprehensive Migration

The script creates a backup branch:

```bash
# Switch to backup
git checkout jest-backup-YYYYMMDD-HHMMSS

# Delete migration branch
git branch -D vitest-migration
```

## Manual Steps After Script

Some items may need manual attention:

### 1. CI/CD Pipeline Updates

Update your CI configuration:

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: npm run test:run  # Changed from: npm test
```

### 2. Module Mock Factories

Review and update mock factories to explicitly define exports:

```typescript
// May need manual update
vi.mock('./module', () => ({
  default: mockValue,      // Explicit default export
  namedExport: vi.fn()
}))
```

### 3. Callback-Style Tests

Convert done-callback tests to async/await:

```typescript
// Before
test('async', (done) => {
  doAsync(() => {
    expect(true).toBe(true)
    done()
  })
})

// After
test('async', async () => {
  await new Promise(resolve => {
    doAsync(() => {
      expect(true).toBe(true)
      resolve()
    })
  })
})
```

### 4. Path Aliases

If you have custom path mappings, verify they're in `vitest.config.ts`:

```typescript
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

## Troubleshooting

### Script fails: "Not a git repository"

**Solution:** Initialize git first:
```bash
git init
git add -A
git commit -m "Initial commit"
```

### Script fails: "Jest tests failing"

**Solution:** Fix Jest tests before migrating:
```bash
npm test
# Fix any failing tests
```

### Codemod doesn't transform all files

**Solution:** Run manually on missed files:
```bash
npx @vitest-codemod/jest path/to/file.test.ts
```

### "vi is not defined" after migration

**Solution:** Ensure globals are enabled in vitest.config.ts:
```typescript
export default defineConfig({
  test: {
    globals: true
  }
})
```

And in tsconfig.json:
```json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

### Tests slower after migration

**Solution:** Use happy-dom instead of jsdom:
```typescript
export default defineConfig({
  test: {
    environment: 'happy-dom'
  }
})
```

## Additional Resources

- Complete migration guide: [MIGRATION.md](./MIGRATION.md)
- Configuration reference: [CONFIG.md](./CONFIG.md)
- Main skill documentation: [../SKILL.md](../SKILL.md)
- Vitest migration docs: <https://vitest.dev/guide/migration>
- vitest-codemod: <https://github.com/trivikr/vitest-codemod>

## Script Customization

Both scripts can be customized for your needs:

### Add Custom Dependencies

```bash
# In comprehensive-migrate.sh, after line 123:
DEPS="$DEPS your-custom-package"
```

### Change Test Patterns

```bash
# At top of script:
TEST_PATTERNS='tests/**/*.test.ts'  # Custom pattern
```

### Skip Codemod

```bash
# At top of script:
USE_CODEMOD=false  # Manual migration
```

### Use jsdom Instead of happy-dom

```bash
# At top of script:
USE_HAPPY_DOM=false  # Use jsdom
```

## Support

If you encounter issues:

1. Check the [MIGRATION.md](./MIGRATION.md) troubleshooting section
2. Review script output for specific errors
3. Examine the backup branch to compare changes
4. Search Vitest GitHub issues for similar problems

Remember: The comprehensive script creates a backup branch, so you can always rollback safely!
