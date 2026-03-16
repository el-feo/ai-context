# ESLint Integration with Development Tools

## VS Code Integration

**Install Extension:**

- ESLint extension by Microsoft (dbaeumer.vscode-eslint)

**Workspace Settings (`.vscode/settings.json`):**

```json
{
  "editor.defaultFormatter": "dbaeumer.vscode-eslint",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ]
}
```

## CI/CD Integration

**GitHub Actions:**

```yaml
name: ESLint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm ci
      - run: npx eslint .
```

**Pre-commit Hook (with Husky):**

```bash
npm install --save-dev husky lint-staged

# Add to package.json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "git add"]
  }
}
```

## Package.json Scripts

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "lint:staged": "lint-staged"
  }
}
```
