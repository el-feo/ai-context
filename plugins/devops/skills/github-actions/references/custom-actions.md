# Custom Actions

Guide to creating JavaScript, Docker, and composite actions.

## Action Types Comparison

| Feature | JavaScript | Docker | Composite |
|---------|-----------|---------|-----------|
| **Speed** | Fast | Slower (container build) | Fast |
| **OS Support** | All (Linux, macOS, Windows) | Linux only | All |
| **Use Case** | General purpose, fast execution | Specific environment needs | Combine existing actions |
| **Dependencies** | Node.js required | Self-contained | Depends on steps |
| **Complexity** | Moderate | Higher | Low |

**Choose JavaScript** for most cases - faster and cross-platform.
**Choose Docker** when you need specific tools, languages, or environment control.
**Choose Composite** to combine multiple actions/steps into a reusable unit.

## JavaScript Actions

### Structure

```
my-action/
├── action.yml          # Action metadata
├── index.js           # Entry point
├── package.json       # Dependencies
├── package-lock.json
├── node_modules/      # Committed for distribution
└── README.md
```

### action.yml

```yaml
name: 'My JavaScript Action'
description: 'Description of what this action does'
author: 'Your Name'

inputs:
  api-key:
    description: 'API key for authentication'
    required: true
  environment:
    description: 'Deployment environment'
    required: false
    default: 'production'

outputs:
  deployment-id:
    description: 'ID of the deployment'
  deployment-url:
    description: 'URL of the deployment'

runs:
  using: 'node20'        # node20 or node16
  main: 'index.js'
  post: 'cleanup.js'     # Optional: runs after job completes
  post-if: 'always()'    # Optional: condition for post
```

### index.js

```javascript
const core = require('@actions/core');
const github = require('@actions/github');
const exec = require('@actions/exec');

async function run() {
  try {
    // Get inputs
    const apiKey = core.getInput('api-key', { required: true });
    const environment = core.getInput('environment');

    // Log information (not visible in runner logs unless in debug mode)
    core.debug(`Deploying to ${environment}`);
    core.info('Starting deployment...');

    // Mask secrets
    core.setSecret(apiKey);

    // Set environment variables
    core.exportVariable('DEPLOY_ENV', environment);

    // Execute commands
    await exec.exec('npm', ['run', 'build']);

    // Access GitHub context
    const { context } = github;
    core.info(`Running for ${context.repo.owner}/${context.repo.repo}`);

    // Set outputs
    core.setOutput('deployment-id', '12345');
    core.setOutput('deployment-url', 'https://example.com');

    // Add job summary (markdown)
    await core.summary
      .addHeading('Deployment Summary')
      .addTable([
        [{data: 'Environment', header: true}, {data: 'Status', header: true}],
        [environment, '✅ Success']
      ])
      .write();

  } catch (error) {
    core.setFailed(error.message);
  }
}

run();
```

### package.json

```json
{
  "name": "my-action",
  "version": "1.0.0",
  "description": "My custom action",
  "main": "index.js",
  "scripts": {
    "test": "jest"
  },
  "dependencies": {
    "@actions/core": "^1.10.1",
    "@actions/github": "^6.0.0",
    "@actions/exec": "^1.1.1",
    "@actions/tool-cache": "^2.0.1",
    "@actions/http-client": "^2.2.0"
  },
  "devDependencies": {
    "@vercel/ncc": "^0.38.1",
    "jest": "^29.7.0"
  }
}
```

### GitHub Actions Toolkit

**@actions/core** - Core functions (inputs, outputs, logging, secrets):
```javascript
core.getInput('name')
core.setOutput('name', 'value')
core.setFailed('error message')
core.info('message')
core.warning('message')
core.error('message')
core.debug('message')
core.setSecret('password')
core.exportVariable('VAR_NAME', 'value')
core.addPath('/path/to/add')
core.group('Group Name', async () => { /* grouped logs */ })
core.saveState('state-key', 'value')
core.getState('state-key')
```

**@actions/github** - GitHub API and context:
```javascript
const github = require('@actions/github');

// Get authenticated Octokit client
const octokit = github.getOctokit(core.getInput('github-token'));

// Access context
const { context } = github;
context.repo      // { owner: 'user', repo: 'repo' }
context.payload   // Webhook payload
context.sha       // Commit SHA
context.ref       // Git ref
context.actor     // User who triggered workflow

// Use Octokit
const { data: pr } = await octokit.rest.pulls.get({
  owner: context.repo.owner,
  repo: context.repo.repo,
  pull_number: context.issue.number
});
```

**@actions/exec** - Execute commands:
```javascript
const exec = require('@actions/exec');

// Simple execution
await exec.exec('npm', ['install']);

// Capture output
let output = '';
await exec.exec('git', ['log', '-1'], {
  listeners: {
    stdout: (data) => { output += data.toString(); }
  }
});
```

**@actions/tool-cache** - Download and cache tools:
```javascript
const tc = require('@actions/tool-cache');

const downloadPath = await tc.downloadTool('https://example.com/tool.tar.gz');
const extractPath = await tc.extractTar(downloadPath);
const cachedPath = await tc.cacheDir(extractPath, 'tool-name', 'version');
core.addPath(cachedPath);
```

### Distribution

**Option 1: Commit node_modules** (simplest):
```bash
npm install --production
git add node_modules
git commit -m "Add dependencies"
git tag -a v1.0.0 -m "Release v1.0.0"
git push --follow-tags
```

**Option 2: Use ncc to bundle** (single file):
```bash
npm install -g @vercel/ncc
ncc build index.js -o dist
# Commit only dist/index.js
```

Update action.yml:
```yaml
runs:
  using: 'node20'
  main: 'dist/index.js'
```

### Testing

```javascript
// index.test.js
const core = require('@actions/core');
const run = require('./index');

jest.mock('@actions/core');

describe('My Action', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('sets output correctly', async () => {
    core.getInput.mockReturnValue('test-value');

    await run();

    expect(core.setOutput).toHaveBeenCalledWith(
      'deployment-id',
      expect.any(String)
    );
  });

  test('fails on error', async () => {
    core.getInput.mockImplementation(() => {
      throw new Error('Input not found');
    });

    await run();

    expect(core.setFailed).toHaveBeenCalled();
  });
});
```

## Docker Actions

### Structure

```
my-docker-action/
├── action.yml
├── Dockerfile
├── entrypoint.sh
└── README.md
```

### action.yml

```yaml
name: 'My Docker Action'
description: 'Description of what this action does'

inputs:
  api-key:
    description: 'API key for authentication'
    required: true

outputs:
  result:
    description: 'Result of the operation'

runs:
  using: 'docker'
  image: 'Dockerfile'
  # OR use pre-built image:
  # image: 'docker://alpine:3.18'

  args:
    - ${{ inputs.api-key }}

  env:
    CUSTOM_VAR: 'value'
```

### Dockerfile

```dockerfile
FROM ruby:3.3-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install gems
RUN gem install bundler

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create non-root user
RUN useradd -m -u 1000 actionuser
USER actionuser

ENTRYPOINT ["/entrypoint.sh"]
```

### entrypoint.sh

```bash
#!/bin/bash
set -e

# Inputs are passed as arguments
API_KEY=$1

echo "Running with API key: ${API_KEY:0:4}****"

# Set outputs using GitHub Actions commands
echo "result=success" >> $GITHUB_OUTPUT

# Add to job summary
echo "## Deployment Complete" >> $GITHUB_STEP_SUMMARY
echo "Status: ✅ Success" >> $GITHUB_STEP_SUMMARY

# Exit with status code
exit 0
```

### Pre-built images

Use pre-built images for faster execution:

```yaml
runs:
  using: 'docker'
  image: 'docker://myorg/myimage:v1.0.0'
```

Build and push to GitHub Container Registry:
```bash
docker build -t ghcr.io/username/action:v1.0.0 .
docker push ghcr.io/username/action:v1.0.0
```

Update action.yml:
```yaml
runs:
  using: 'docker'
  image: 'docker://ghcr.io/username/action:v1.0.0'
```

### Environment Variables in Docker Actions

Access GitHub Actions environment variables:
- `GITHUB_TOKEN`: Authentication token
- `GITHUB_REPOSITORY`: owner/repo
- `GITHUB_SHA`: Commit SHA
- `GITHUB_REF`: Git ref
- `GITHUB_WORKSPACE`: Workspace path
- `GITHUB_OUTPUT`: Path to output file
- `GITHUB_STEP_SUMMARY`: Path to summary file

## Composite Actions

Combine multiple steps into a single reusable action.

### Structure

```
my-composite-action/
├── action.yml
└── README.md
```

### action.yml

```yaml
name: 'Setup Ruby on Rails'
description: 'Sets up Ruby, installs gems, and prepares database'

inputs:
  ruby-version:
    description: 'Ruby version to use'
    required: false
    default: '.ruby-version'
  database-url:
    description: 'Database URL'
    required: true

outputs:
  ruby-version:
    description: 'Installed Ruby version'
    value: ${{ steps.setup-ruby.outputs.ruby-version }}

runs:
  using: 'composite'
  steps:
    - name: Setup Ruby
      id: setup-ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ inputs.ruby-version }}
        bundler-cache: true

    - name: Setup database
      shell: bash
      env:
        DATABASE_URL: ${{ inputs.database-url }}
      run: |
        bundle exec rails db:create
        bundle exec rails db:schema:load

    - name: Print summary
      shell: bash
      run: |
        echo "✅ Rails environment ready" >> $GITHUB_STEP_SUMMARY
```

### Important Notes

1. **Secrets must be passed explicitly** - they're not inherited:
   ```yaml
   - uses: ./.github/actions/my-action
     with:
       github-token: ${{ secrets.GITHUB_TOKEN }}
   ```

2. **Must specify shell** for run steps:
   ```yaml
   - shell: bash
     run: echo "Hello"
   ```

3. **Cannot use `continue-on-error` or `timeout-minutes`** at step level

4. **Can reference other actions** including other composite actions

## Publishing Actions

### To GitHub Marketplace

1. Create public repository
2. Add action.yml in root or specify path
3. Create release with tag (v1.0.0)
4. GitHub will prompt to publish to Marketplace

### Versioning Strategy

Users reference actions by tag:
```yaml
- uses: username/action@v1      # Major version (recommended)
- uses: username/action@v1.0.0  # Specific version
- uses: username/action@main    # Branch (not recommended)
- uses: username/action@sha     # Commit SHA (most secure)
```

Maintain major version tags:
```bash
git tag v1.0.0
git tag -f v1    # Update v1 to point to v1.0.0
git push --tags --force
```

### Security

- **Never commit secrets** to action repository
- **Use .gitignore** for node_modules (if not distributing with action)
- **Scan dependencies** regularly (Dependabot)
- **Pin action versions** in composite actions
- **Run as non-root** in Docker actions
- **Validate inputs** before using in shell commands

### Documentation

Include in README.md:
- Description of what action does
- Input parameters with descriptions
- Output values with descriptions
- Usage examples
- Requirements (e.g., GITHUB_TOKEN permissions)
- License

## Testing Actions Locally

### act (for complete workflows)
```bash
# Install act
brew install act

# Run workflow locally
act push

# Run specific job
act -j test

# Pass secrets
act -s GITHUB_TOKEN=your_token
```

### Manual testing
```bash
# Set environment variables
export INPUT_API_KEY=test_key
export GITHUB_REPOSITORY=owner/repo

# Run action
node index.js
```

## Common Patterns

### Conditional execution in composite
```yaml
- name: Deploy to production
  if: ${{ inputs.environment == 'production' }}
  shell: bash
  run: ./deploy.sh
```

### Loop with matrix in composite
```yaml
# NOT SUPPORTED - use JavaScript action instead
# Composite actions cannot use matrix strategy
```

### Reading files
```javascript
// JavaScript action
const fs = require('fs');
const content = fs.readFileSync('file.txt', 'utf8');
```

```bash
# Docker/Composite action
content=$(cat file.txt)
```

### HTTP requests
```javascript
// JavaScript action
const http = require('@actions/http-client');
const client = new http.HttpClient('my-action');
const response = await client.get('https://api.example.com');
```

```bash
# Docker/Composite action
curl -X GET https://api.example.com
```

### Working with artifacts
```yaml
# Composite action
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
```

## Resources

- [GitHub Actions Toolkit](https://github.com/actions/toolkit)
- [actions/typescript-action template](https://github.com/actions/typescript-action)
- [actions/javascript-action template](https://github.com/actions/javascript-action)
- [actions/container-action template](https://github.com/actions/container-action)
- [GitHub Actions Documentation](https://docs.github.com/en/actions/creating-actions)
