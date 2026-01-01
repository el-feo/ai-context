#!/bin/bash
# comprehensive-migrate.sh - Comprehensive Jest to Vitest migration
# Usage: ./comprehensive-migrate.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
BACKUP_BRANCH="jest-backup-$(date +%Y%m%d-%H%M%S)"
TEST_PATTERNS='src/**/*.{test,spec}.{js,ts,jsx,tsx}'
USE_CODEMOD=true
USE_HAPPY_DOM=true  # Set to false to use jsdom

log_info "Starting Jest to Vitest migration"

# Step 1: Pre-migration checks
log_info "Running pre-migration checks..."

# Check if git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not a git repository. Please initialize git first."
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    log_warn "You have uncommitted changes. Committing them now..."
    git add -A
    git commit -m "WIP: Before Vitest migration"
fi

# Check if Jest is installed
if ! npm list jest > /dev/null 2>&1; then
    log_error "Jest not found in package.json"
    exit 1
fi

# Step 2: Create backup branch
log_info "Creating backup branch: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"
git checkout -b "vitest-migration"

# Step 3: Run tests with Jest first
log_info "Running Jest tests to verify current state..."
if npm run test -- --passWithNoTests; then
    log_info "Jest tests passed"
else
    log_error "Jest tests failing. Fix tests before migration."
    exit 1
fi

# Step 4: Detect project type
log_info "Detecting project type..."
HAS_REACT=false
HAS_VUE=false
HAS_TESTING_LIBRARY=false

if npm list react > /dev/null 2>&1; then
    HAS_REACT=true
    log_info "Detected React project"
fi

if npm list vue > /dev/null 2>&1; then
    HAS_VUE=true
    log_info "Detected Vue project"
fi

if npm list @testing-library/react > /dev/null 2>&1 || npm list @testing-library/vue > /dev/null 2>&1; then
    HAS_TESTING_LIBRARY=true
    log_info "Detected Testing Library"
fi

# Step 5: Backup Jest configuration
log_info "Backing up Jest configuration..."
if [ -f "jest.config.js" ]; then
    cp jest.config.js jest.config.js.backup
fi
if [ -f "jest.config.ts" ]; then
    cp jest.config.ts jest.config.ts.backup
fi
if [ -f "jest.setup.js" ]; then
    cp jest.setup.js jest.setup.js.backup
fi
if [ -f "jest.setup.ts" ]; then
    cp jest.setup.ts jest.setup.ts.backup
fi

# Step 6: Remove Jest dependencies
log_info "Removing Jest dependencies..."
npm uninstall \
    jest \
    @types/jest \
    ts-jest \
    jest-environment-jsdom \
    @jest/globals \
    babel-jest \
    jest-transform-stub \
    2>/dev/null || true

# Step 7: Install Vitest dependencies
log_info "Installing Vitest dependencies..."

DEPS="vitest @vitest/ui"

if [ "$USE_HAPPY_DOM" = true ]; then
    DEPS="$DEPS happy-dom"
else
    DEPS="$DEPS jsdom"
fi

if [ "$HAS_REACT" = true ]; then
    DEPS="$DEPS @vitejs/plugin-react"
fi

if [ "$HAS_VUE" = true ]; then
    DEPS="$DEPS @vitejs/plugin-vue"
fi

npm install -D $DEPS

# Step 8: Run automated codemod
if [ "$USE_CODEMOD" = true ]; then
    log_info "Running automated codemod transformation..."

    # Install codemod if not available
    if ! command -v vitest-codemod &> /dev/null; then
        log_info "Installing vitest-codemod..."
        npm install -g @vitest-codemod/jest
    fi

    # Run codemod on test files
    vitest-codemod jest $TEST_PATTERNS || log_warn "Codemod completed with warnings"
else
    log_warn "Skipping codemod. Manual migration required."
fi

# Step 9: Create Vitest configuration
log_info "Creating vitest.config.ts..."

if [ "$HAS_REACT" = true ]; then
cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './vitest.setup.ts',
    css: true,
    clearMocks: true,
    restoreMocks: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.d.ts',
        '**/*.config.*',
      ]
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    }
  }
})
EOF

elif [ "$HAS_VUE" = true ]; then
cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './vitest.setup.ts',
    clearMocks: true,
    restoreMocks: true,
  }
})
EOF

else
cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: './vitest.setup.ts',
    clearMocks: true,
    restoreMocks: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    }
  }
})
EOF
fi

# Step 10: Create setup file
log_info "Creating vitest.setup.ts..."

if [ "$HAS_TESTING_LIBRARY" = true ]; then
cat > vitest.setup.ts << 'EOF'
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

afterEach(() => {
  cleanup()
})
EOF
else
cat > vitest.setup.ts << 'EOF'
import { expect } from 'vitest'

// Global setup
EOF
fi

# Step 11: Update package.json
log_info "Updating package.json scripts..."
npm pkg delete scripts.test
npm pkg set scripts.test="vitest"
npm pkg set scripts.test:ui="vitest --ui"
npm pkg set scripts.test:run="vitest run"
npm pkg set scripts.test:coverage="vitest run --coverage"

# Step 12: Update TypeScript configuration
log_info "Updating tsconfig.json..."
if [ -f "tsconfig.json" ]; then
    # Use node to update JSON (more reliable than manual editing)
    node -e "
    const fs = require('fs');
    const config = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
    config.compilerOptions = config.compilerOptions || {};
    config.compilerOptions.types = config.compilerOptions.types || [];
    if (!config.compilerOptions.types.includes('vitest/globals')) {
        config.compilerOptions.types.push('vitest/globals');
    }
    // Remove jest types
    config.compilerOptions.types = config.compilerOptions.types.filter(t => t !== '@types/jest');
    fs.writeFileSync('tsconfig.json', JSON.stringify(config, null, 2));
    "
fi

# Step 13: Remove old configuration files
log_info "Removing old Jest configuration files..."
rm -f jest.config.js jest.config.ts jest.setup.js jest.setup.ts

# Step 14: Search for remaining Jest references
log_info "Searching for remaining Jest references..."
JEST_REFS=$(grep -r "from 'jest'" src/ test/ 2>/dev/null | wc -l || echo "0")
if [ "$JEST_REFS" -gt 0 ]; then
    log_warn "Found $JEST_REFS Jest import references that may need manual update"
    grep -r "from 'jest'" src/ test/ 2>/dev/null || true
fi

# Step 15: Commit changes
log_info "Committing migration changes..."
git add -A
git commit -m "Migrate from Jest to Vitest

- Remove Jest dependencies
- Install Vitest and plugins
- Run automated codemod transformations
- Create vitest.config.ts
- Update package.json scripts
- Update TypeScript configuration
"

# Step 16: Run tests with Vitest
log_info "Running Vitest tests..."
if npm run test:run; then
    log_info "✅ Migration successful! All tests passing."
else
    log_error "❌ Tests failing. Review the output above and fix issues."
    log_info "To rollback: git checkout $BACKUP_BRANCH"
    exit 1
fi

# Success summary
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Migration completed successfully!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info ""
log_info "Next steps:"
log_info "1. Review git diff to verify changes"
log_info "2. Run 'npm run test:ui' to explore test UI"
log_info "3. Run 'npm run test:coverage' to check coverage"
log_info "4. Update CI/CD pipelines to use Vitest"
log_info "5. Clean up: rm *.backup"
log_info ""
log_info "Backup branch: $BACKUP_BRANCH"
log_info "To rollback: git checkout $BACKUP_BRANCH"
