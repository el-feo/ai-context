# TypeScript Type-Aware Linting

## Overview

Type-aware linting uses TypeScript's type checker to enable more powerful analysis that understands your code's types. This allows catching bugs that regular linting cannot detect, such as incorrect type usage, Promise mishandling, and more.

## Why Type-Aware Linting?

### Problems Only Type-Aware Rules Can Catch

**1. Unhandled Promises:**
```typescript
// Without type-aware linting: No error
async function fetchData() {
  return { id: 1, name: 'John' };
}

// This Promise is never awaited or handled!
fetchData(); // ❌ Should use await or .then()
```

**2. Type-Unsafe Array Access:**
```typescript
const items: string[] = ['a', 'b', 'c'];
const item = items.find(x => x === 'd'); // Type: string | undefined

// Without type-aware linting: No error
item.toUpperCase(); // ❌ Runtime error if undefined
```

**3. Incorrect Type Assertions:**
```typescript
const data: unknown = { name: 'John' };

// Without type-aware linting: No error
const person = data as Person; // ❌ Unsafe assertion
person.email.toLowerCase(); // Runtime error if email doesn't exist
```

## Setup

### 1. Install Dependencies

```bash
npm install --save-dev \
  eslint \
  @typescript-eslint/parser \
  @typescript-eslint/eslint-plugin \
  typescript-eslint
```

### 2. Configure ESLint

**Basic Type-Aware Configuration:**
```javascript
// eslint.config.js
import { defineConfig } from 'eslint/config';
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default defineConfig([
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname
      }
    }
  }
]);
```

**Strict Type-Aware Configuration:**
```javascript
export default defineConfig([
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname
      }
    }
  }
]);
```

### 3. TypeScript Configuration

Your `tsconfig.json` must include the files you want to lint:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "strict": true,
    "esModuleInterop": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Type-Aware Rules

### Essential Rules

#### 1. @typescript-eslint/no-floating-promises

Requires Promise-returning statements to be awaited or handled.

```typescript
// ❌ Bad
async function fetchData() {
  return fetch('/api/data');
}

fetchData(); // Promise not handled

// ✅ Good
await fetchData();

// ✅ Also good
fetchData().catch(console.error);

// ✅ Also good
void fetchData(); // Explicitly ignore
```

**Configuration:**
```javascript
rules: {
  '@typescript-eslint/no-floating-promises': 'error'
}
```

#### 2. @typescript-eslint/no-misused-promises

Prevents using Promises in contexts that don't expect them.

```typescript
// ❌ Bad - Promise in if condition
if (fetchData()) { // Always truthy!
  console.log('Data fetched');
}

// ✅ Good
if (await fetchData()) {
  console.log('Data fetched');
}

// ❌ Bad - Promise as event handler
button.addEventListener('click', fetchData); // Returns Promise!

// ✅ Good
button.addEventListener('click', () => void fetchData());
```

**Configuration:**
```javascript
rules: {
  '@typescript-eslint/no-misused-promises': [
    'error',
    {
      checksConditionals: true,
      checksVoidReturn: true
    }
  ]
}
```

#### 3. @typescript-eslint/no-unnecessary-condition

Prevents conditions that are always truthy or falsy.

```typescript
// ❌ Bad
const arr: string[] = [];
if (arr) { // Arrays are always truthy
  console.log('Array exists');
}

// ✅ Good
if (arr.length > 0) {
  console.log('Array has items');
}

// ❌ Bad
function process(value: string) {
  if (value === undefined) { // Never true - value is always string
    return;
  }
}

// ✅ Good
function process(value: string | undefined) {
  if (value === undefined) {
    return;
  }
}
```

**Configuration:**
```javascript
rules: {
  '@typescript-eslint/no-unnecessary-condition': 'error'
}
```

#### 4. @typescript-eslint/strict-boolean-expressions

Ensures only boolean values used in conditions.

```typescript
// ❌ Bad
const items: string[] = [];
if (items) { // Arrays are always truthy
  console.log('Has items');
}

// ✅ Good
if (items.length > 0) {
  console.log('Has items');
}

// ❌ Bad
const count: number = 0;
if (count) { // 0 is falsy but valid number
  console.log('Count is set');
}

// ✅ Good
if (count > 0) {
  console.log('Count is positive');
}
```

**Configuration:**
```javascript
rules: {
  '@typescript-eslint/strict-boolean-expressions': [
    'error',
    {
      allowString: false,
      allowNumber: false,
      allowNullableObject: false
    }
  ]
}
```

#### 5. @typescript-eslint/await-thenable

Disallows awaiting non-Promise values.

```typescript
// ❌ Bad
function syncFunction() {
  return 42;
}

await syncFunction(); // Not a Promise!

// ✅ Good
async function asyncFunction() {
  return 42;
}

await asyncFunction();
```

#### 6. @typescript-eslint/no-unnecessary-type-assertion

Disallows type assertions that don't change the type.

```typescript
const str: string = 'hello';

// ❌ Bad - assertion doesn't change type
const result = str as string;

// ✅ Good - no unnecessary assertion
const result = str;

// ✅ Good - assertion actually changes type
const data: unknown = { name: 'John' };
const person = data as Person;
```

#### 7. @typescript-eslint/require-await

Requires async functions to contain await.

```typescript
// ❌ Bad - no await in async function
async function processData() {
  return data.map(x => x * 2);
}

// ✅ Good - has await
async function processData() {
  const data = await fetchData();
  return data.map(x => x * 2);
}

// ✅ Good - not async
function processData() {
  return data.map(x => x * 2);
}
```

### Advanced Type-Aware Rules

#### 8. @typescript-eslint/no-unsafe-assignment

Prevents assignments of `any` type values.

```typescript
// ❌ Bad
const data: any = fetchFromAPI();
const user: User = data; // Unsafe!

// ✅ Good
const data: unknown = fetchFromAPI();
const user: User = data as User; // Explicit assertion
// Or use type guard:
if (isUser(data)) {
  const user: User = data;
}
```

#### 9. @typescript-eslint/no-unsafe-call

Prevents calling values of type `any`.

```typescript
// ❌ Bad
const fn: any = getSomeFunction();
fn(); // Unsafe call

// ✅ Good
const fn: () => void = getSomeFunction();
fn();
```

#### 10. @typescript-eslint/no-unsafe-member-access

Prevents accessing members of `any` values.

```typescript
// ❌ Bad
const obj: any = fetchData();
console.log(obj.name); // Unsafe access

// ✅ Good
const obj: { name: string } = fetchData();
console.log(obj.name);
```

## Recommended Configurations

### Strict Configuration (Recommended for New Projects)

```javascript
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig([
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true
      }
    },
    rules: {
      // Promise handling
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/require-await': 'error',
      
      // Type safety
      '@typescript-eslint/no-unnecessary-condition': 'error',
      '@typescript-eslint/strict-boolean-expressions': 'error',
      '@typescript-eslint/no-unnecessary-type-assertion': 'error',
      
      // Unsafe any usage
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-unsafe-call': 'error',
      '@typescript-eslint/no-unsafe-member-access': 'error',
      '@typescript-eslint/no-unsafe-return': 'error',
      
      // Prefer type-safe alternatives
      '@typescript-eslint/prefer-nullish-coalescing': 'error',
      '@typescript-eslint/prefer-optional-chain': 'error',
      '@typescript-eslint/no-confusing-void-expression': 'error'
    }
  }
]);
```

### Balanced Configuration (Good for Existing Projects)

```javascript
export default defineConfig([
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true
      }
    },
    rules: {
      // Essential safety
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      
      // Warnings for gradual adoption
      '@typescript-eslint/no-unnecessary-condition': 'warn',
      '@typescript-eslint/no-unsafe-assignment': 'warn',
      '@typescript-eslint/no-unsafe-call': 'warn',
      
      // Helpful suggestions
      '@typescript-eslint/prefer-nullish-coalescing': 'warn',
      '@typescript-eslint/prefer-optional-chain': 'warn'
    }
  }
]);
```

## Performance Optimization

Type-aware linting is slower than regular linting because it invokes the TypeScript compiler. Here's how to optimize:

### 1. Lint Only Necessary Files

```javascript
export default defineConfig([
  {
    files: ['src/**/*.ts', 'src/**/*.tsx'],
    // Don't lint test files with type-aware rules
    ignores: ['**/*.test.ts', '**/*.spec.ts'],
    languageOptions: {
      parserOptions: {
        project: './tsconfig.json'
      }
    }
  },
  {
    // Separate config for tests without type checking
    files: ['**/*.test.ts', '**/*.spec.ts'],
    extends: [tseslint.configs.recommended]
  }
]);
```

### 2. Use Multiple tsconfig Files

Create `tsconfig.eslint.json` for linting:

```json
{
  "extends": "./tsconfig.json",
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.ts"
  ]
}
```

Reference in ESLint config:
```javascript
languageOptions: {
  parserOptions: {
    project: './tsconfig.eslint.json'
  }
}
```

### 3. Use ESLint Cache

```bash
# Enable caching
npx eslint --cache src/

# Specify cache location
npx eslint --cache --cache-location .eslintcache src/
```

### 4. Parallel Execution

For large projects, use multiple processes:

```json
{
  "scripts": {
    "lint": "eslint --cache --max-warnings 0 .",
    "lint:fix": "eslint --cache --fix ."
  }
}
```

## Troubleshooting

### "Parsing error: Cannot read file 'tsconfig.json'"

**Solution:** Ensure tsconfig.json exists and parserOptions.project path is correct:

```javascript
parserOptions: {
  project: './tsconfig.json',
  tsconfigRootDir: import.meta.dirname // Or __dirname for CJS
}
```

### "You must pass a `parserOptions.project` to type-check"

**Solution:** Some rules require type information. Add parserOptions:

```javascript
languageOptions: {
  parserOptions: {
    project: true // Automatically finds tsconfig.json
  }
}
```

### Very Slow Linting

**Solutions:**
1. Exclude unnecessary files from tsconfig
2. Use separate tsconfig.eslint.json
3. Enable ESLint cache
4. Lint fewer files with type-aware rules
5. Consider upgrading hardware or using CI for thorough checks

### Type-Aware Rules Not Working

**Checklist:**
1. ✅ @typescript-eslint/parser installed
2. ✅ parserOptions.project configured
3. ✅ File is included in tsconfig.json
4. ✅ TypeScript compiles without errors
5. ✅ Using typescript-eslint v6+ with ESLint 8+

## Migration Strategy

### For Existing Projects

1. **Start with Recommended Config:**
```javascript
export default defineConfig([
  ...tseslint.configs.recommendedTypeChecked
]);
```

2. **Gradually Enable Strict Rules:**
```javascript
rules: {
  // Start with warnings
  '@typescript-eslint/no-unnecessary-condition': 'warn',
  '@typescript-eslint/strict-boolean-expressions': 'warn',
  
  // After addressing warnings, upgrade to errors
  '@typescript-eslint/no-floating-promises': 'error'
}
```

3. **Fix Issues Incrementally:**
```bash
# Fix one rule at a time
npx eslint --fix --rule '@typescript-eslint/no-floating-promises: error' src/
```

4. **Use Disable Comments Temporarily:**
```typescript
// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
const data = apiResponse;
// TODO(#123): Add proper type validation
```

## Best Practices

1. **Always Use Type-Aware Linting for TypeScript Projects**
2. **Start Strict with New Projects** - Easier than retrofitting
3. **Document Disabled Rules** - Explain why and create follow-up tasks
4. **Optimize for Performance** - Use caching and targeted linting
5. **Run in CI/CD** - Enforce on all code changes
6. **Combine with Strict TypeScript** - Use `strict: true` in tsconfig.json

## Resources

- [typescript-eslint Documentation](https://typescript-eslint.io/)
- [Type-Aware Rules List](https://typescript-eslint.io/linting/typed-linting/)
- [Performance Troubleshooting](https://typescript-eslint.io/linting/troubleshooting/performance-troubleshooting/)
