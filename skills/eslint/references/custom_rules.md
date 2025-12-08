# Creating Custom ESLint Rules

## Overview

Custom ESLint rules allow you to enforce project-specific patterns and conventions that aren't covered by standard ESLint rules. This guide covers creating, testing, and deploying custom rules.

## When to Create Custom Rules

Create custom rules when you need to:
- Enforce company-specific coding standards
- Prevent common bugs unique to your codebase
- Maintain consistency in API usage patterns
- Enforce architectural decisions (e.g., module boundaries)
- Prevent deprecated API usage in your own libraries

## Quick Start: Local Custom Rule

### 1. Project Structure

```
my-project/
├── eslint-local-rules/
│   ├── index.js
│   └── rules/
│       └── my-custom-rule.js
├── eslint.config.js
└── package.json
```

### 2. Create Rule File

`eslint-local-rules/rules/my-custom-rule.js`:
```javascript
module.exports = {
  meta: {
    type: "problem", // "problem", "suggestion", or "layout"
    docs: {
      description: "Disallow usage of deprecated API",
      category: "Best Practices",
      recommended: true
    },
    fixable: "code", // or "whitespace" or null
    schema: [] // options schema
  },
  
  create(context) {
    return {
      // Visit CallExpression nodes
      CallExpression(node) {
        if (
          node.callee.type === 'MemberExpression' &&
          node.callee.object.name === 'OldAPI' &&
          node.callee.property.name === 'deprecatedMethod'
        ) {
          context.report({
            node,
            message: 'OldAPI.deprecatedMethod is deprecated. Use NewAPI.modernMethod instead.',
            fix(fixer) {
              // Optional: provide auto-fix
              return fixer.replaceText(
                node.callee,
                'NewAPI.modernMethod'
              );
            }
          });
        }
      }
    };
  }
};
```

### 3. Load Local Rules

`eslint-local-rules/index.js`:
```javascript
module.exports = {
  'my-custom-rule': require('./rules/my-custom-rule'),
  'another-rule': require('./rules/another-rule')
};
```

### 4. Configure ESLint

`eslint.config.js`:
```javascript
import { defineConfig } from 'eslint/config';
import localRules from './eslint-local-rules/index.js';

export default defineConfig([
  {
    plugins: {
      local: {
        rules: localRules
      }
    },
    rules: {
      'local/my-custom-rule': 'error'
    }
  }
]);
```

## Rule Development Deep Dive

### Rule Structure

Every ESLint rule has two main parts:

1. **Metadata (`meta`)**: Describes the rule
2. **Implementation (`create`)**: Contains the rule logic

### Metadata Properties

```javascript
module.exports = {
  meta: {
    type: "problem",        // Rule category
    docs: {
      description: "",      // Brief description
      category: "",         // Grouping category
      recommended: true,    // Include in recommended config
      url: ""              // Documentation URL
    },
    fixable: "code",       // Can auto-fix
    hasSuggestions: true,  // Provides manual fix suggestions
    messages: {           // Message templates
      avoidApi: "Avoid using {{api}}. Use {{replacement}} instead."
    },
    schema: [             // Rule options schema
      {
        type: "object",
        properties: {
          exceptions: {
            type: "array"
          }
        },
        additionalProperties: false
      }
    ]
  },
  create(context) {
    // Rule implementation
  }
};
```

### Working with the AST

ESLint uses the Abstract Syntax Tree (AST) to analyze code. Use [AST Explorer](https://astexplorer.net/) to understand AST structure.

**Common Node Types:**
- `Program` - Root of AST
- `VariableDeclaration` - `var`, `let`, `const`
- `FunctionDeclaration` - Function definitions
- `CallExpression` - Function calls
- `MemberExpression` - Property access (e.g., `obj.prop`)
- `Identifier` - Variable names
- `Literal` - String, number, boolean values

### Visitor Pattern

```javascript
create(context) {
  return {
    // Visit all function declarations
    FunctionDeclaration(node) {
      if (node.id.name.startsWith('_')) {
        context.report({
          node: node.id,
          message: 'Function names should not start with underscore'
        });
      }
    },
    
    // Visit variable declarations
    VariableDeclaration(node) {
      if (node.kind === 'var') {
        context.report({
          node,
          message: 'Use let or const instead of var'
        });
      }
    },
    
    // Exit event (runs after children visited)
    'FunctionDeclaration:exit'(node) {
      // Clean up or final checks
    }
  };
}
```

### Context API

The `context` object provides utilities:

```javascript
create(context) {
  // Get source code
  const sourceCode = context.sourceCode;
  
  // Get rule options
  const options = context.options[0] || {};
  
  // Report issues
  context.report({
    node,
    message: 'Error message',
    data: { varName: node.name },
    fix(fixer) {
      return fixer.replaceText(node, 'replacement');
    },
    suggest: [
      {
        desc: 'Use const instead',
        fix(fixer) {
          return fixer.replaceText(node, 'const');
        }
      }
    ]
  });
  
  // Get parent nodes
  const parent = sourceCode.getAncestors(node);
  
  // Get comments
  const comments = sourceCode.getCommentsBefore(node);
  
  return {
    // Visitors
  };
}
```

## Real-World Examples

### Example 1: Enforce Import Order

```javascript
// eslint-local-rules/rules/import-order.js
module.exports = {
  meta: {
    type: "suggestion",
    docs: {
      description: "Enforce specific import order"
    },
    fixable: "code",
    schema: []
  },
  
  create(context) {
    const sourceCode = context.sourceCode;
    let imports = [];
    
    return {
      ImportDeclaration(node) {
        imports.push(node);
      },
      
      'Program:exit'() {
        const groups = {
          external: [],
          internal: [],
          relative: []
        };
        
        imports.forEach(node => {
          const source = node.source.value;
          if (source.startsWith('.')) {
            groups.relative.push(node);
          } else if (source.startsWith('@/')) {
            groups.internal.push(node);
          } else {
            groups.external.push(node);
          }
        });
        
        // Check if order is correct
        let lastEnd = 0;
        ['external', 'internal', 'relative'].forEach(group => {
          groups[group].forEach((node, i) => {
            if (node.range[0] < lastEnd) {
              context.report({
                node,
                message: `Import from "${node.source.value}" should come earlier`
              });
            }
            lastEnd = node.range[1];
          });
        });
      }
    };
  }
};
```

### Example 2: Prevent Specific API Usage

```javascript
// eslint-local-rules/rules/no-moment.js
module.exports = {
  meta: {
    type: "problem",
    docs: {
      description: "Disallow moment.js, use date-fns instead"
    },
    messages: {
      noMoment: "Don't use moment.js. Use date-fns instead for better tree-shaking."
    }
  },
  
  create(context) {
    return {
      ImportDeclaration(node) {
        if (node.source.value === 'moment') {
          context.report({
            node,
            messageId: 'noMoment'
          });
        }
      },
      
      CallExpression(node) {
        if (
          node.callee.type === 'Identifier' &&
          node.callee.name === 'require' &&
          node.arguments[0] &&
          node.arguments[0].value === 'moment'
        ) {
          context.report({
            node,
            messageId: 'noMoment'
          });
        }
      }
    };
  }
};
```

### Example 3: Enforce Naming Conventions

```javascript
// eslint-local-rules/rules/component-naming.js
module.exports = {
  meta: {
    type: "suggestion",
    docs: {
      description: "Enforce PascalCase for React components"
    },
    schema: []
  },
  
  create(context) {
    function isPascalCase(name) {
      return /^[A-Z][a-zA-Z0-9]*$/.test(name);
    }
    
    function isReactComponent(node) {
      // Check if function returns JSX
      const sourceCode = context.sourceCode;
      const text = sourceCode.getText(node.body);
      return text.includes('return') && text.includes('<');
    }
    
    return {
      FunctionDeclaration(node) {
        if (node.id && isReactComponent(node)) {
          if (!isPascalCase(node.id.name)) {
            context.report({
              node: node.id,
              message: `React component "${node.id.name}" should be in PascalCase`
            });
          }
        }
      },
      
      VariableDeclaration(node) {
        node.declarations.forEach(declarator => {
          if (
            declarator.init &&
            declarator.init.type === 'ArrowFunctionExpression' &&
            isReactComponent(declarator.init)
          ) {
            if (!isPascalCase(declarator.id.name)) {
              context.report({
                node: declarator.id,
                message: `React component "${declarator.id.name}" should be in PascalCase`
              });
            }
          }
        });
      }
    };
  }
};
```

## Testing Custom Rules

### Using RuleTester

```javascript
// eslint-local-rules/tests/my-custom-rule.test.js
const { RuleTester } = require('eslint');
const rule = require('../rules/my-custom-rule');

const ruleTester = new RuleTester({
  parserOptions: { ecmaVersion: 2020 }
});

ruleTester.run('my-custom-rule', rule, {
  valid: [
    // Valid code examples
    'const x = 1;',
    'NewAPI.modernMethod();'
  ],
  
  invalid: [
    {
      code: 'OldAPI.deprecatedMethod();',
      errors: [{
        message: 'OldAPI.deprecatedMethod is deprecated. Use NewAPI.modernMethod instead.'
      }],
      output: 'NewAPI.modernMethod();' // Expected after fix
    }
  ]
});
```

Run tests:
```bash
npm install --save-dev mocha
npx mocha eslint-local-rules/tests/*.test.js
```

## Publishing as npm Package

### 1. Package Structure

```
eslint-plugin-mycompany/
├── lib/
│   ├── index.js
│   └── rules/
│       ├── rule-one.js
│       └── rule-two.js
├── tests/
│   └── rules/
│       ├── rule-one.test.js
│       └── rule-two.test.js
├── package.json
└── README.md
```

### 2. Package Configuration

`package.json`:
```json
{
  "name": "eslint-plugin-mycompany",
  "version": "1.0.0",
  "description": "Custom ESLint rules for MyCompany",
  "main": "lib/index.js",
  "keywords": ["eslint", "eslintplugin", "eslint-plugin"],
  "peerDependencies": {
    "eslint": ">=8.0.0"
  }
}
```

### 3. Plugin Entry Point

`lib/index.js`:
```javascript
module.exports = {
  rules: {
    'rule-one': require('./rules/rule-one'),
    'rule-two': require('./rules/rule-two')
  },
  configs: {
    recommended: {
      plugins: ['mycompany'],
      rules: {
        'mycompany/rule-one': 'error',
        'mycompany/rule-two': 'warn'
      }
    }
  }
};
```

### 4. Usage

```bash
npm install --save-dev eslint-plugin-mycompany
```

```javascript
// eslint.config.js
import mycompany from 'eslint-plugin-mycompany';

export default [
  {
    plugins: { mycompany },
    rules: {
      'mycompany/rule-one': 'error'
    }
  }
];
```

## Advanced Techniques

### TypeScript Support

For TypeScript rules, use `@typescript-eslint/utils`:

```javascript
const { ESLintUtils } = require('@typescript-eslint/utils');

module.exports = ESLintUtils.RuleCreator(
  name => `https://docs.example.com/rules/${name}`
)({
  name: 'my-ts-rule',
  meta: {
    type: 'problem',
    docs: {
      description: 'TypeScript-aware rule'
    },
    schema: []
  },
  defaultOptions: [],
  
  create(context) {
    const parserServices = ESLintUtils.getParserServices(context);
    const checker = parserServices.program.getTypeChecker();
    
    return {
      Identifier(node) {
        // Get TypeScript type information
        const tsNode = parserServices.esTreeNodeToTSNodeMap.get(node);
        const type = checker.getTypeAtLocation(tsNode);
        
        // Use type information in rule logic
      }
    };
  }
});
```

### Performance Considerations

1. **Minimize AST Traversals**: Visit only necessary node types
2. **Cache Computations**: Store results of expensive operations
3. **Use Selectors**: Target specific patterns efficiently

```javascript
create(context) {
  // Cache source code
  const sourceCode = context.sourceCode;
  
  // Use specific selectors instead of visiting all nodes
  return {
    // Target specific pattern
    'CallExpression[callee.name="oldFunction"]'(node) {
      context.report({ node, message: 'Use newFunction instead' });
    }
  };
}
```

## Resources

- [ESLint Rule Documentation](https://eslint.org/docs/latest/extend/custom-rules)
- [AST Explorer](https://astexplorer.net/) - Visualize code AST
- [ESLint GitHub](https://github.com/eslint/eslint) - Source code for reference
- [@typescript-eslint/utils](https://typescript-eslint.io/developers/custom-rules) - TypeScript rule helpers
