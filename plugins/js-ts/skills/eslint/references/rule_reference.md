# ESLint Rule Reference

## Overview

This reference provides practical examples and guidance for commonly used ESLint rules. Rules are organized by category to help you understand their purpose and application.

## Rule Categories

- **Possible Problems** - Rules that detect potential errors
- **Suggestions** - Rules that suggest better ways of doing things
- **Layout & Formatting** - Rules about code style and formatting

## Severity Levels

- `"off"` or `0` - Disable the rule
- `"warn"` or `1` - Warning (doesn't block builds)
- `"error"` or `2` - Error (blocks builds, exit code 1)

---

## Possible Problems

### no-unused-vars

Disallow unused variables.

**Why:** Unused variables indicate dead code and can confuse readers.

```javascript
// ❌ Bad
const x = 1;
const y = 2; // 'y' is assigned but never used
console.log(x);

// ✅ Good
const x = 1;
console.log(x);

// ✅ Good - prefixing with underscore shows intentional
const _unused = getValue(); // Intentionally unused
```

**Configuration:**
```javascript
rules: {
  "no-unused-vars": ["error", {
    "vars": "all",
    "args": "after-used",
    "ignoreRestSiblings": true,
    "argsIgnorePattern": "^_",
    "varsIgnorePattern": "^_"
  }]
}
```

**Auto-fixable:** No

---

### no-undef

Disallow undefined variables.

**Why:** Prevents typos and ensures variables are declared.

```javascript
// ❌ Bad
console.log(username); // 'username' is not defined

// ✅ Good
const username = 'john';
console.log(username);
```

**Configuration:**
```javascript
rules: {
  "no-undef": "error"
}
```

**Auto-fixable:** No

---

### no-constant-condition

Disallow constant conditions.

**Why:** Indicates logic errors or dead code.

```javascript
// ❌ Bad
if (true) {
  doSomething();
}

while (true) {
  // Infinite loop without break
}

// ✅ Good
if (isReady) {
  doSomething();
}

while (shouldContinue) {
  // ...
}
```

**Configuration:**
```javascript
rules: {
  "no-constant-condition": ["error", {
    "checkLoops": false // Allow while(true) with breaks
  }]
}
```

---

### no-unreachable

Disallow unreachable code.

**Why:** Code after return/throw/break is never executed.

```javascript
// ❌ Bad
function example() {
  return true;
  console.log('Never runs'); // Unreachable
}

// ✅ Good
function example() {
  console.log('Runs');
  return true;
}
```

**Configuration:**
```javascript
rules: {
  "no-unreachable": "error"
}
```

---

### no-duplicate-imports

Disallow duplicate imports.

**Why:** Multiple imports from same module can be consolidated.

```javascript
// ❌ Bad
import { foo } from 'module';
import { bar } from 'module';

// ✅ Good
import { foo, bar } from 'module';
```

**Configuration:**
```javascript
rules: {
  "no-duplicate-imports": "error"
}
```

**Auto-fixable:** No

---

## Suggestions

### eqeqeq

Require === and !== instead of == and !=.

**Why:** Prevents type coercion bugs.

```javascript
// ❌ Bad
if (x == 0) { }
if (obj == null) { }

// ✅ Good
if (x === 0) { }
if (obj === null) { }

// ✅ Also good - explicit coercion
if (Number(x) === 0) { }
```

**Configuration:**
```javascript
rules: {
  "eqeqeq": ["error", "always", {
    "null": "ignore" // Allow == null to check both null and undefined
  }]
}
```

**Auto-fixable:** Sometimes (when safe)

---

### no-console

Disallow console statements.

**Why:** Console statements should be removed before production.

```javascript
// ❌ Bad
console.log('Debug info');

// ✅ Good
// Use proper logging library
logger.info('Important info');

// ✅ Good - warnings and errors allowed
console.warn('Warning');
console.error('Error');
```

**Configuration:**
```javascript
rules: {
  "no-console": ["error", {
    "allow": ["warn", "error"]
  }]
}
```

**Auto-fixable:** No

---

### prefer-const

Require const for variables never reassigned.

**Why:** Signals intent and prevents accidental reassignment.

```javascript
// ❌ Bad
let x = 1;
console.log(x); // Never reassigned

// ✅ Good
const x = 1;
console.log(x);

// ✅ Good - reassignment needed
let counter = 0;
counter++;
```

**Configuration:**
```javascript
rules: {
  "prefer-const": ["error", {
    "destructuring": "all",
    "ignoreReadBeforeAssign": false
  }]
}
```

**Auto-fixable:** Yes

---

### no-var

Require let or const instead of var.

**Why:** var has confusing scoping rules.

```javascript
// ❌ Bad
var x = 1;

// ✅ Good
const x = 1;
let y = 2;
```

**Configuration:**
```javascript
rules: {
  "no-var": "error"
}
```

**Auto-fixable:** Yes

---

### prefer-arrow-callback

Require arrow functions as callbacks.

**Why:** Arrow functions are more concise and don't bind `this`.

```javascript
// ❌ Bad
array.map(function(item) {
  return item * 2;
});

// ✅ Good
array.map(item => item * 2);

// ✅ Good - when 'this' binding needed
array.map(function(item) {
  return this.transform(item);
}, context);
```

**Configuration:**
```javascript
rules: {
  "prefer-arrow-callback": ["error", {
    "allowNamedFunctions": false,
    "allowUnboundThis": true
  }]
}
```

**Auto-fixable:** Yes

---

### no-param-reassign

Disallow reassigning function parameters.

**Why:** Prevents confusing mutations and potential bugs.

```javascript
// ❌ Bad
function update(obj) {
  obj = {}; // Reassigns parameter
}

// ✅ Good
function update(obj) {
  return { ...obj, updated: true };
}

// ⚠️ Note: Modifying properties is often needed
function update(obj) {
  obj.updated = true; // This is allowed by default
}
```

**Configuration:**
```javascript
rules: {
  "no-param-reassign": ["error", {
    "props": true, // Also prevent property modifications
    "ignorePropertyModificationsFor": [
      "acc", // for reduce
      "state" // for Redux/Vuex
    ]
  }]
}
```

**Auto-fixable:** No

---

### curly

Require braces around all control statements.

**Why:** Prevents subtle bugs when adding statements.

```javascript
// ❌ Bad
if (condition) doSomething();

// ✅ Good
if (condition) {
  doSomething();
}
```

**Configuration:**
```javascript
rules: {
  "curly": ["error", "all"]
}
```

**Auto-fixable:** Yes

---

### no-else-return

Disallow else blocks after return in if.

**Why:** Simplifies code flow.

```javascript
// ❌ Bad
function test() {
  if (x) {
    return a;
  } else {
    return b;
  }
}

// ✅ Good
function test() {
  if (x) {
    return a;
  }
  return b;
}
```

**Configuration:**
```javascript
rules: {
  "no-else-return": ["error", {
    "allowElseIf": false
  }]
}
```

**Auto-fixable:** Yes

---

### prefer-template

Require template literals instead of string concatenation.

**Why:** More readable and supports multiline strings.

```javascript
// ❌ Bad
const message = 'Hello, ' + name + '!';

// ✅ Good
const message = `Hello, ${name}!`;
```

**Configuration:**
```javascript
rules: {
  "prefer-template": "error"
}
```

**Auto-fixable:** Yes

---

## Layout & Formatting

### indent

Enforce consistent indentation.

```javascript
// ❌ Bad (inconsistent)
function example() {
    const x = 1;
  const y = 2;
}

// ✅ Good (2 spaces)
function example() {
  const x = 1;
  const y = 2;
}
```

**Configuration:**
```javascript
rules: {
  "indent": ["error", 2, {
    "SwitchCase": 1,
    "VariableDeclarator": "first",
    "FunctionDeclaration": {
      "parameters": "first"
    }
  }]
}
```

**Auto-fixable:** Yes

---

### quotes

Enforce consistent quote style.

```javascript
// ❌ Bad (mixed)
const a = "double";
const b = 'single';

// ✅ Good (single)
const a = 'single';
const b = 'also single';
```

**Configuration:**
```javascript
rules: {
  "quotes": ["error", "single", {
    "avoidEscape": true,
    "allowTemplateLiterals": true
  }]
}
```

**Auto-fixable:** Yes

---

### semi

Require or disallow semicolons.

```javascript
// With semicolons
const x = 1;

// Without semicolons
const x = 1
```

**Configuration:**
```javascript
// Require semicolons
rules: {
  "semi": ["error", "always"]
}

// Disallow semicolons
rules: {
  "semi": ["error", "never"]
}
```

**Auto-fixable:** Yes

---

### comma-dangle

Require or disallow trailing commas.

```javascript
// ❌ Bad (inconsistent)
const obj = {
  a: 1,
  b: 2
};

// ✅ Good (with trailing comma)
const obj = {
  a: 1,
  b: 2,
};
```

**Configuration:**
```javascript
rules: {
  "comma-dangle": ["error", {
    "arrays": "always-multiline",
    "objects": "always-multiline",
    "imports": "always-multiline",
    "exports": "always-multiline",
    "functions": "never"
  }]
}
```

**Auto-fixable:** Yes

---

### max-len

Enforce maximum line length.

```javascript
// ❌ Bad
const message = 'This is a very long string that exceeds the maximum line length and should be broken up';

// ✅ Good
const message = [
  'This is a very long string',
  'broken into multiple parts'
].join(' ');
```

**Configuration:**
```javascript
rules: {
  "max-len": ["error", {
    "code": 100,
    "tabWidth": 2,
    "ignoreUrls": true,
    "ignoreStrings": true,
    "ignoreTemplateLiterals": true,
    "ignoreRegExpLiterals": true
  }]
}
```

**Auto-fixable:** No

---

## TypeScript-Specific Rules

### @typescript-eslint/no-explicit-any

Disallow any type.

```typescript
// ❌ Bad
function process(data: any) {
  return data.value;
}

// ✅ Good
function process(data: unknown) {
  if (isValidData(data)) {
    return data.value;
  }
}

// ✅ Good
function process<T>(data: T) {
  return data;
}
```

**Configuration:**
```javascript
rules: {
  "@typescript-eslint/no-explicit-any": "error"
}
```

---

### @typescript-eslint/explicit-function-return-type

Require explicit return types.

```typescript
// ❌ Bad
function calculate(x: number, y: number) {
  return x + y;
}

// ✅ Good
function calculate(x: number, y: number): number {
  return x + y;
}
```

**Configuration:**
```javascript
rules: {
  "@typescript-eslint/explicit-function-return-type": ["error", {
    "allowExpressions": true,
    "allowTypedFunctionExpressions": true
  }]
}
```

---

### @typescript-eslint/naming-convention

Enforce naming conventions.

```typescript
// ❌ Bad
const my_variable = 1; // Should be camelCase
interface user {} // Should be PascalCase
class api_client {} // Should be PascalCase

// ✅ Good
const myVariable = 1;
interface User {}
class ApiClient {}
```

**Configuration:**
```javascript
rules: {
  "@typescript-eslint/naming-convention": [
    "error",
    {
      "selector": "variable",
      "format": ["camelCase", "UPPER_CASE"]
    },
    {
      "selector": "function",
      "format": ["camelCase"]
    },
    {
      "selector": "typeLike",
      "format": ["PascalCase"]
    }
  ]
}
```

---

## React-Specific Rules

### react/jsx-uses-react

Prevent React from being marked as unused.

**Note:** Not needed in React 17+ with new JSX transform.

```javascript
rules: {
  "react/jsx-uses-react": "off", // React 17+
  "react/react-in-jsx-scope": "off" // React 17+
}
```

---

### react/prop-types

Require PropTypes definitions.

```javascript
// ❌ Bad (if using PropTypes)
function Component({ name }) {
  return <div>{name}</div>;
}

// ✅ Good (with PropTypes)
import PropTypes from 'prop-types';

function Component({ name }) {
  return <div>{name}</div>;
}

Component.propTypes = {
  name: PropTypes.string.isRequired
};

// ✅ Good (with TypeScript)
interface Props {
  name: string;
}

function Component({ name }: Props) {
  return <div>{name}</div>;
}
```

**Configuration:**
```javascript
rules: {
  "react/prop-types": "off" // Disable if using TypeScript
}
```

---

### react-hooks/rules-of-hooks

Enforce Rules of Hooks.

```javascript
// ❌ Bad
function Component() {
  if (condition) {
    useEffect(() => {}); // Conditional hook
  }
}

// ❌ Bad
function regularFunction() {
  useEffect(() => {}); // Hook in non-component
}

// ✅ Good
function Component() {
  useEffect(() => {
    if (condition) {
      // Effect logic inside
    }
  });
}
```

**Configuration:**
```javascript
rules: {
  "react-hooks/rules-of-hooks": "error",
  "react-hooks/exhaustive-deps": "warn"
}
```

---

## Configuration Templates

### Minimal Strict Configuration

```javascript
export default defineConfig([
  {
    rules: {
      // Possible Problems
      "no-unused-vars": "error",
      "no-undef": "error",
      "no-unreachable": "error",
      
      // Suggestions
      "eqeqeq": "error",
      "prefer-const": "error",
      "no-var": "error",
      
      // Formatting
      "semi": ["error", "always"],
      "quotes": ["error", "single"]
    }
  }
]);
```

### Recommended for Most Projects

```javascript
import { defineConfig } from "eslint/config";
import js from "@eslint/js";

export default defineConfig([
  js.configs.recommended,
  {
    rules: {
      // Override or add rules
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "prefer-const": "error",
      "no-var": "error",
      "eqeqeq": ["error", "always"],
      "curly": ["error", "all"],
      "no-else-return": "error"
    }
  }
]);
```

---

## Resources

- [Complete Rules List](https://eslint.org/docs/latest/rules/)
- [Recommended Configuration](https://eslint.org/docs/latest/use/configure/configuration-files#using-predefined-configurations)
- [Rule Deprecation Policy](https://eslint.org/docs/latest/use/rule-deprecation)
