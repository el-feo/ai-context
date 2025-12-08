#!/bin/bash
# quick-migrate.sh - Quick Jest to Vitest migration
# Usage: ./quick-migrate.sh

set -e  # Exit on error

echo "🚀 Starting Jest to Vitest migration..."

# 1. Backup current state
echo "📦 Creating backup..."
git add -A
git commit -m "Backup before Vitest migration" || true

# 2. Remove Jest dependencies
echo "🗑️  Removing Jest..."
npm uninstall jest @types/jest ts-jest jest-environment-jsdom @jest/globals

# 3. Install Vitest
echo "📥 Installing Vitest..."
npm install -D vitest @vitest/ui happy-dom

# 4. Run automated codemod
echo "🔄 Running automated codemod..."
npx @vitest-codemod/jest src/**/*.{test,spec}.{js,ts,jsx,tsx}

# 5. Create basic config
echo "⚙️  Creating vitest.config.ts..."
cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './vitest.setup.ts',
    clearMocks: true,
    restoreMocks: true,
  },
})
EOF

# 6. Create setup file
echo "📝 Creating vitest.setup.ts..."
cat > vitest.setup.ts << 'EOF'
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

afterEach(() => {
  cleanup()
})
EOF

# 7. Update package.json scripts
echo "📝 Updating package.json scripts..."
npm pkg set scripts.test="vitest"
npm pkg set scripts.test:ui="vitest --ui"
npm pkg set scripts.test:run="vitest run"
npm pkg set scripts.test:coverage="vitest run --coverage"

# 8. Update tsconfig.json
echo "📝 Updating tsconfig.json..."
npx json -I -f tsconfig.json -e 'this.compilerOptions.types=["vitest/globals"]' 2>/dev/null || echo "⚠️  Skipping tsconfig update (install 'json' package or update manually)"

# 9. Remove old config files
echo "🗑️  Removing old config files..."
rm -f jest.config.js jest.config.ts jest.setup.js jest.setup.ts

echo "✅ Migration complete!"
echo "🧪 Run 'npm test' to verify migration"
