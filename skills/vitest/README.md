# Vitest Skill - Quick Reference

Comprehensive Vitest skill focused on Jest-to-Vitest migration with automated tooling.

## Skill Structure

- **SKILL.md** - Main skill documentation with migration focus
- **references/MIGRATION.md** - Detailed API mappings and troubleshooting
- **references/CONFIG.md** - Complete configuration reference
- **references/MIGRATION_SCRIPT.md** - Automated migration scripts

## Quick Migration

### Fastest Method (Automated)

```bash
# One-line migration
npx @vitest-codemod/jest src/**/*.test.ts && npm uninstall jest @types/jest ts-jest && npm install -D vitest @vitest/ui happy-dom
```

### Recommended Method (Script)

Use the comprehensive migration script in `references/MIGRATION_SCRIPT.md`:

```bash
# Copy the script to your project
curl -o migrate-to-vitest.sh [script-url]

# Make executable and run
chmod +x migrate-to-vitest.sh
./migrate-to-vitest.sh
```

## Key Features

### Migration Tools

1. **Automated codemods**
   - `vitest-codemod` - CLI transformation tool
   - Codemod.com platform - VS Code extension + CLI
   - Manual find & replace patterns

2. **Complete API mapping**
   - Jest → Vitest function mapping
   - Configuration migration guide
   - Common pattern transformations

3. **Framework-specific guides**
   - React + Testing Library
   - Vue Test Utils
   - Angular (with @analogjs)
   - Next.js
   - Node.js backend

### Configuration Examples

- React projects
- Vue projects
- TypeScript projects
- Node.js backend
- Monorepo workspaces
- CI/CD pipelines

### Troubleshooting

- Globals not working
- Mock behavior differences
- Path aliases not resolving
- Testing Library cleanup
- Performance optimization
- Snapshot formatting

## When to Use This Skill

Invoke this skill when:

- Migrating from Jest to Vitest
- Setting up Vitest in new projects
- Configuring Vitest environments
- Debugging migration issues
- Optimizing test performance
- Understanding Vitest vs Jest differences

## Quick Reference

### Basic Commands

```bash
npm run test              # Watch mode
npm run test:run          # Run once (CI)
npm run test:ui           # Visual UI
npm run test:coverage     # With coverage
```

### Common Config

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './vitest.setup.ts',
    clearMocks: true,
    restoreMocks: true,
  }
})
```

### API Quick Reference

| Jest | Vitest |
|------|--------|
| `jest.fn()` | `vi.fn()` |
| `jest.spyOn()` | `vi.spyOn()` |
| `jest.mock()` | `vi.mock()` |
| `jest.useFakeTimers()` | `vi.useFakeTimers()` |
| `jest.setTimeout(ms)` | `vi.setConfig({ testTimeout: ms })` |

## Documentation Quality

- **3,341 total lines** of comprehensive documentation
- **697 lines** in main SKILL.md
- **943 lines** of configuration reference
- **887 lines** of migration guide
- **814 lines** of automation scripts

## Success Metrics

Expected improvements after migration:

- ✅ **5x faster** cold start (10s → 2s)
- ✅ **5x faster** watch mode reload (5s → <1s)
- ✅ **2x faster** test execution
- ✅ **10x faster** TypeScript tests (no ts-jest)
- ✅ **Zero config** TypeScript support

## Resources

- Vitest docs: <https://vitest.dev>
- Migration guide: <https://vitest.dev/guide/migration>
- vitest-codemod: <https://github.com/trivikr/vitest-codemod>
- Codemod platform: <https://codemod.com>
