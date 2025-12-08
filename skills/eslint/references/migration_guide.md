# Migrating from ESLint 8.x to 9.x (Flat Config)

## Overview

ESLint 9.0 introduced a new "flat config" format as the default, replacing the legacy `.eslintrc.*` format. This guide helps you migrate existing projects to the new configuration system.

## Key Changes

### 1. Configuration File Format

**Old (.eslintrc.json):**
```json
{
  "extends": ["eslint:recommended"],
  "env": {
    "browser": true,
    "es2021": true
  },
  "rules": {
    "semi": "error"
  }
}
```

**New (eslint.config.js):**
```javascript
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import globals from "globals";

export default defineConfig([
  js.configs.recommended,
  {
    languageOptions: {
      globals: {
        ...globals.browser
      }
    },
    rules: {
      semi: "error"
    }
  }
]);
```

### 2. Key Differences

| Aspect | eslintrc | Flat Config |
|--------|----------|-------------|
| File names | `.eslintrc.*` | `eslint.config.js` |
| Format | JSON/YAML/JS | JavaScript ES modules |
| Structure | Single object | Array of config objects |
| Extends | String array | Spread configs directly |
| Environments | `env` object | `languageOptions.globals` |
| Parser | Top-level `parser` | `languageOptions.parser` |
| Globals | `globals` object | `languageOptions.globals` |

## Migration Steps

### Step 1: Update ESLint

```bash
npm install --save-dev eslint@latest @eslint/js
```

### Step 2: Create New Config File

Create `eslint.config.js` in your project root:

```javascript
import { defineConfig } from "eslint/config";

export default defineConfig([
  // Your configuration
]);
```

### Step 3: Migrate Each Section

#### Migrating `extends`

**Before:**
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "prettier"
  ]
}
```

**After:**
```javascript
import js from "@eslint/js";
import react from "eslint-plugin-react";
import prettier from "eslint-config-prettier";

export default defineConfig([
  js.configs.recommended,
  react.configs.recommended,
  prettier
]);
```

#### Migrating `env`

**Before:**
```json
{
  "env": {
    "browser": true,
    "node": true,
    "es2021": true
  }
}
```

**After:**
```javascript
import globals from "globals";

export default defineConfig([
  {
    languageOptions: {
      ecmaVersion: 2021,
      globals: {
        ...globals.browser,
        ...globals.node
      }
    }
  }
]);
```

#### Migrating `parser` and `parserOptions`

**Before:**
```json
{
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "project": "./tsconfig.json"
  }
}
```

**After:**
```javascript
import parser from "@typescript-eslint/parser";

export default defineConfig([
  {
    languageOptions: {
      parser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        project: "./tsconfig.json"
      }
    }
  }
]);
```

#### Migrating `plugins`

**Before:**
```json
{
  "plugins": ["react", "import", "@typescript-eslint"]
}
```

**After:**
```javascript
import react from "eslint-plugin-react";
import importPlugin from "eslint-plugin-import";
import tseslint from "@typescript-eslint/eslint-plugin";

export default defineConfig([
  {
    plugins: {
      react,
      import: importPlugin,
      "@typescript-eslint": tseslint
    }
  }
]);
```

#### Migrating `rules`

Rules remain mostly the same, but plugin rule names change slightly:

**Before:**
```json
{
  "rules": {
    "semi": "error",
    "react/prop-types": "off",
    "@typescript-eslint/no-unused-vars": "warn"
  }
}
```

**After:**
```javascript
export default defineConfig([
  {
    rules: {
      "semi": "error",
      "react/prop-types": "off",
      "@typescript-eslint/no-unused-vars": "warn"
    }
  }
]);
```

#### Migrating `overrides`

**Before:**
```json
{
  "overrides": [
    {
      "files": ["*.ts", "*.tsx"],
      "rules": {
        "no-undef": "off"
      }
    }
  ]
}
```

**After:**
```javascript
export default defineConfig([
  {
    // Default config
  },
  {
    files: ["**/*.ts", "**/*.tsx"],
    rules: {
      "no-undef": "off"
    }
  }
]);
```

#### Migrating `ignorePatterns`

**Before:**
```json
{
  "ignorePatterns": ["dist/", "build/", "*.config.js"]
}
```

**After:**
```javascript
export default defineConfig([
  {
    ignores: ["**/dist/**", "**/build/**", "**/*.config.js"]
  }
]);
```

Note: Patterns in flat config are now glob patterns and should include `**/`.

## Complete Migration Examples

### Example 1: Basic JavaScript Project

**Before (.eslintrc.json):**
```json
{
  "extends": "eslint:recommended",
  "env": {
    "browser": true,
    "es2021": true
  },
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "semi": ["error", "always"],
    "quotes": ["error", "single"]
  }
}
```

**After (eslint.config.js):**
```javascript
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import globals from "globals";

export default defineConfig([
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: globals.browser
    },
    rules: {
      semi: ["error", "always"],
      quotes: ["error", "single"]
    }
  }
]);
```

### Example 2: TypeScript Project

**Before (.eslintrc.json):**
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "project": "./tsconfig.json"
  },
  "rules": {
    "@typescript-eslint/no-explicit-any": "warn"
  }
}
```

**After (eslint.config.js):**
```javascript
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default defineConfig([
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname
      }
    },
    rules: {
      "@typescript-eslint/no-explicit-any": "warn"
    }
  }
]);
```

### Example 3: React + TypeScript

**Before (.eslintrc.json):**
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["react", "@typescript-eslint"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true
    }
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  },
  "rules": {
    "react/react-in-jsx-scope": "off"
  }
}
```

**After (eslint.config.js):**
```javascript
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import react from "eslint-plugin-react";
import tseslint from "typescript-eslint";
import globals from "globals";

export default defineConfig([
  js.configs.recommended,
  ...tseslint.configs.recommended,
  react.configs.flat.recommended,
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: globals.browser,
      parserOptions: {
        ecmaFeatures: {
          jsx: true
        }
      }
    },
    settings: {
      react: {
        version: "detect"
      }
    },
    rules: {
      "react/react-in-jsx-scope": "off"
    }
  }
]);
```

### Example 4: Monorepo with Different Configs

**After (eslint.config.js):**
```javascript
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import react from "eslint-plugin-react";
import globals from "globals";

export default defineConfig([
  // Global ignores
  {
    ignores: ["**/dist/**", "**/build/**", "**/node_modules/**"]
  },
  
  // Base config for all files
  js.configs.recommended,
  ...tseslint.configs.recommended,
  
  // Frontend package
  {
    files: ["packages/frontend/**/*.{ts,tsx}"],
    ...react.configs.flat.recommended,
    languageOptions: {
      globals: globals.browser
    },
    rules: {
      "react/react-in-jsx-scope": "off"
    }
  },
  
  // Backend package
  {
    files: ["packages/backend/**/*.ts"],
    languageOptions: {
      globals: globals.node
    },
    rules: {
      "no-console": "off"
    }
  },
  
  // Test files
  {
    files: ["**/*.test.{ts,tsx}", "**/*.spec.{ts,tsx}"],
    languageOptions: {
      globals: {
        ...globals.node,
        ...globals.jest
      }
    },
    rules: {
      "@typescript-eslint/no-explicit-any": "off"
    }
  }
]);
```

## Common Migration Issues

### Issue 1: "Unexpected top-level property 'extends'"

**Cause:** Using old `.eslintrc` format in new config file.

**Solution:** Import and spread configs instead:
```javascript
// ❌ Wrong
export default {
  extends: ["eslint:recommended"]
};

// ✅ Correct
import js from "@eslint/js";

export default defineConfig([
  js.configs.recommended
]);
```

### Issue 2: Plugin Rules Not Found

**Cause:** Plugins not properly imported or installed.

**Solution:** Ensure plugins are installed and imported:
```bash
npm install --save-dev eslint-plugin-react
```

```javascript
import react from "eslint-plugin-react";

export default defineConfig([
  {
    plugins: { react },
    rules: {
      "react/prop-types": "off"
    }
  }
]);
```

### Issue 3: Ignores Not Working

**Cause:** Ignore patterns don't include `**/`.

**Solution:** Use glob patterns:
```javascript
// ❌ Wrong
ignores: ["dist", "build"]

// ✅ Correct
ignores: ["**/dist/**", "**/build/**"]
```

### Issue 4: "require() is not defined"

**Cause:** Using CommonJS in ESM flat config.

**Solution:** Use ESM imports:
```javascript
// ❌ Wrong
const js = require("@eslint/js");

// ✅ Correct
import js from "@eslint/js";
```

If you need CommonJS, use `.cjs` extension:
```javascript
// eslint.config.cjs
const js = require("@eslint/js");

module.exports = [
  js.configs.recommended
];
```

### Issue 5: TypeScript Parsing Errors

**Cause:** Parser not configured for TypeScript files.

**Solution:** Specify parser for TypeScript files:
```javascript
export default defineConfig([
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: tseslintParser,
      parserOptions: {
        project: true
      }
    }
  }
]);
```

## Gradual Migration Strategy

### Phase 1: Keep Both Configs

You can run both configs side-by-side:

1. Keep `.eslintrc.json` for now
2. Create `eslint.config.js` for testing
3. Use environment variable to switch:

```json
{
  "scripts": {
    "lint:old": "ESLINT_USE_FLAT_CONFIG=false eslint .",
    "lint:new": "ESLINT_USE_FLAT_CONFIG=true eslint .",
    "lint": "npm run lint:new"
  }
}
```

### Phase 2: Migrate Incrementally

1. Migrate basic rules first
2. Test thoroughly
3. Migrate complex configs (overrides, plugins)
4. Remove old config file

### Phase 3: Clean Up

```bash
# Remove old config
rm .eslintrc.json

# Update package.json scripts
{
  "scripts": {
    "lint": "eslint ."
  }
}
```

## Migration Tools

### Automatic Migration (Experimental)

Some plugins provide migration utilities:

```bash
# For specific plugins, check their documentation
npm install --save-dev @eslint/migrate-config
npx @eslint/migrate-config .eslintrc.json
```

### Manual Verification

After migration, verify:

```bash
# Test linting
npm run lint

# Check rules are working
npx eslint --print-config src/index.ts

# Verify ignored files
npx eslint --debug src/
```

## Best Practices

1. **Test Thoroughly** - Run linting on entire codebase after migration
2. **Use TypeScript** - `.ts` extension provides better type safety for config
3. **Document Changes** - Comment complex migrations
4. **Update CI/CD** - Ensure CI uses ESLint 9+
5. **Update Editor Plugins** - Upgrade VS Code ESLint extension

## Resources

- [Official Migration Guide](https://eslint.org/docs/latest/use/configure/migration-guide)
- [Flat Config Documentation](https://eslint.org/docs/latest/use/configure/configuration-files)
- [Configuration Inspector](https://eslint.org/docs/latest/use/configure/configuration-inspector)
