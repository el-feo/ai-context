---
description: Execute QA Steps using Playwright automation
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  qa:
    description: "QA issue number (format: qa=#123)"
    required: false
  step:
    description: "Specific QA Step to execute (format: step=#123)"
    required: false
---

<objective>
You are GHPM (GitHub Project Manager). Execute QA Steps using Playwright browser automation, recording pass/fail results on GitHub issues and triggering bug creation on failures.
</objective>

<arguments>
**Optional arguments:**
- `qa=#123` - Execute all QA Steps linked to this QA Issue
- `step=#123` - Execute a specific QA Step

**Resolution order if omitted:**

1. Most recent open QA issue with QA Steps:
   `gh issue list -l QA -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**Execute a single QA Step:**

```bash
/ghpm:qa-execute step=#42
```

**Execute all Steps in a QA Issue:**

```bash
/ghpm:qa-execute qa=#10
```

**Auto-resolve most recent QA Issue:**

```bash
/ghpm:qa-execute
```

</usage_examples>

<workflow>

## Step 0: Resolve Target QA Steps

### If `step=#N` provided (single Step execution)

```bash
STEP=$N

# Fetch Step details
STEP_DATA=$(gh issue view "$STEP" --json title,body,url,labels -q '.')
STEP_TITLE=$(echo "$STEP_DATA" | jq -r '.title')
STEP_BODY=$(echo "$STEP_DATA" | jq -r '.body')

# Verify it's a QA Step
HAS_LABEL=$(echo "$STEP_DATA" | jq -r '.labels[].name' | grep -c "QA-Step" || true)
if [ "$HAS_LABEL" -eq 0 ]; then
  echo "Warning: Issue #$STEP does not have QA-Step label. Proceeding anyway."
fi

# Extract parent QA Issue number from body
QA=$(echo "$STEP_BODY" | grep -oE 'QA: #[0-9]+' | head -1 | grep -oE '[0-9]+')

STEPS_TO_EXECUTE=("$STEP")
```

### If `qa=#N` provided (all Steps in QA Issue)

```bash
QA=$N
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Fetch all QA Steps linked as sub-issues of this QA Issue
cat > /tmp/ghpm-qa-subissues.graphql << 'GRAPHQL'
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      subIssues(first: 50) {
        nodes {
          number
          title
          state
          labels(first: 10) {
            nodes { name }
          }
        }
      }
    }
  }
}
GRAPHQL

# Get open QA Steps
STEPS_TO_EXECUTE=$(gh api graphql -F owner="$OWNER" -F repo="$REPO" -F number=$QA \
  -f query="$(cat /tmp/ghpm-qa-subissues.graphql)" \
  --jq '.data.repository.issue.subIssues.nodes[] | select(.state == "OPEN") | select(.labels.nodes[].name == "QA-Step") | .number')

if [ -z "$STEPS_TO_EXECUTE" ]; then
  echo "Error: No open QA Steps found for QA Issue #$QA"
  exit 1
fi

echo "Found $(echo "$STEPS_TO_EXECUTE" | wc -l | tr -d ' ') QA Steps to execute"
```

### If no argument provided (auto-resolve)

```bash
# Find most recent open QA issue
QA=$(gh issue list -l QA -s open --limit 1 --json number -q '.[0].number')

if [ -z "$QA" ]; then
  echo "Error: No open QA issue found. Specify qa=#N or step=#N"
  exit 1
fi

echo "Auto-resolved to QA Issue #$QA"

# Then fetch Steps as above
```

## Step 1: Fetch Step Details

For each Step to execute, fetch the full details:

```bash
for STEP in $STEPS_TO_EXECUTE; do
  STEP_DATA=$(gh issue view "$STEP" --json title,body,url -q '.')
  STEP_TITLE=$(echo "$STEP_DATA" | jq -r '.title')
  STEP_BODY=$(echo "$STEP_DATA" | jq -r '.body')
  STEP_URL=$(echo "$STEP_DATA" | jq -r '.url')

  echo "Processing: #$STEP - $STEP_TITLE"

  # Extract Given/When/Then from body
  # Look for Scenario section
  SCENARIO=$(echo "$STEP_BODY" | sed -n '/## Scenario/,/## /p' | head -n -1)

  # Extract Test Details
  URL_PAGE=$(echo "$STEP_BODY" | grep -oE '\*\*URL/Page:\*\* .+' | sed 's/\*\*URL\/Page:\*\* //')

  # Continue to parsing and execution...
done
```

## Step 2: Parse Given/When/Then into Playwright Actions

Parse the Scenario section to extract actionable Playwright commands.

### Parser Pattern Reference

| Pattern | Playwright Action |
|---------|-------------------|
| `Given I am on <URL>` | `await page.goto('<URL>')` |
| `Given I am on the <page> page` | `await page.goto(baseUrl + '/<page>')` |
| `When I click <element>` | `await page.click('<selector>')` |
| `When I click the <text> button` | `await page.click('button:has-text("<text>")')` |
| `When I click the <text> link` | `await page.click('a:has-text("<text>")')` |
| `When I type <text> into <field>` | `await page.fill('<selector>', '<text>')` |
| `When I enter <text> in the <field> field` | `await page.fill('[name="<field>"], [placeholder*="<field>"]', '<text>')` |
| `When I select <option> from <dropdown>` | `await page.selectOption('<selector>', '<option>')` |
| `When I check <checkbox>` | `await page.check('<selector>')` |
| `When I uncheck <checkbox>` | `await page.uncheck('<selector>')` |
| `When I wait for <seconds> seconds` | `await page.waitForTimeout(<seconds> * 1000)` |
| `Then I should see <text>` | `await expect(page.locator('body')).toContainText('<text>')` |
| `Then I should see the <text> button` | `await expect(page.locator('button:has-text("<text>")')).toBeVisible()` |
| `Then I should be on <URL>` | `await expect(page).toHaveURL('<URL>')` |
| `Then I should be redirected to <page>` | `await expect(page).toHaveURL(/<page>/)` |
| `Then the <field> field should contain <value>` | `await expect(page.locator('<selector>')).toHaveValue('<value>')` |
| `Then I should not see <text>` | `await expect(page.locator('body')).not.toContainText('<text>')` |

### Parsing Logic

```javascript
function parseScenario(scenario) {
  const actions = [];
  const lines = scenario.split('\n').map(l => l.trim()).filter(l => l);

  for (const line of lines) {
    // Given - Setup/Navigation
    if (/^Given I am on (.+)$/i.test(line)) {
      const url = line.match(/^Given I am on (.+)$/i)[1];
      actions.push({ type: 'navigate', url: url.replace(/['"]/g, '') });
    }

    // When - Actions
    else if (/^When I click (?:the )?(.+?) button$/i.test(line)) {
      const text = line.match(/^When I click (?:the )?(.+?) button$/i)[1];
      actions.push({ type: 'click', selector: `button:has-text("${text}")` });
    }
    else if (/^When I click (?:the )?(.+?) link$/i.test(line)) {
      const text = line.match(/^When I click (?:the )?(.+?) link$/i)[1];
      actions.push({ type: 'click', selector: `a:has-text("${text}")` });
    }
    else if (/^When I click (.+)$/i.test(line)) {
      const element = line.match(/^When I click (.+)$/i)[1];
      actions.push({ type: 'click', selector: element });
    }
    else if (/^When I (?:type|enter) ['""]?(.+?)['""]? (?:into|in) (?:the )?(.+?)(?: field)?$/i.test(line)) {
      const match = line.match(/^When I (?:type|enter) ['""]?(.+?)['""]? (?:into|in) (?:the )?(.+?)(?: field)?$/i);
      actions.push({ type: 'fill', selector: match[2], value: match[1] });
    }
    else if (/^When I select ['""]?(.+?)['""]? from (.+)$/i.test(line)) {
      const match = line.match(/^When I select ['""]?(.+?)['""]? from (.+)$/i);
      actions.push({ type: 'select', selector: match[2], value: match[1] });
    }
    else if (/^When I wait for (\d+) seconds?$/i.test(line)) {
      const seconds = line.match(/^When I wait for (\d+) seconds?$/i)[1];
      actions.push({ type: 'wait', duration: parseInt(seconds) * 1000 });
    }

    // Then - Assertions
    else if (/^Then I should see ['""]?(.+?)['""]?$/i.test(line)) {
      const text = line.match(/^Then I should see ['""]?(.+?)['""]?$/i)[1];
      actions.push({ type: 'assertText', text });
    }
    else if (/^Then I should be on (.+)$/i.test(line)) {
      const url = line.match(/^Then I should be on (.+)$/i)[1];
      actions.push({ type: 'assertURL', url: url.replace(/['"]/g, '') });
    }
    else if (/^Then I should be redirected to (.+)$/i.test(line)) {
      const page = line.match(/^Then I should be redirected to (.+)$/i)[1];
      actions.push({ type: 'assertURLContains', pattern: page });
    }
    else if (/^Then I should not see ['""]?(.+?)['""]?$/i.test(line)) {
      const text = line.match(/^Then I should not see ['""]?(.+?)['""]?$/i)[1];
      actions.push({ type: 'assertNoText', text });
    }

    // Unparseable line
    else if (line && !line.startsWith('As a')) {
      console.warn(`Warning: Could not parse line: "${line}"`);
      actions.push({ type: 'unparseable', line });
    }
  }

  return actions;
}
```

### Handling Unparseable Steps

When a step cannot be parsed:

1. Log warning with the unparseable line
2. Add to actions array with type `unparseable`
3. During execution, skip unparseable actions but include in report
4. Do not fail the entire step for unparseable clauses

## Step 3: Execute Playwright Actions

Execute the parsed actions in a browser using Playwright.

### Browser Launch Configuration

```javascript
const { chromium, expect } = require('@playwright/test');

async function executeStep(stepNumber, actions, options = {}) {
  const {
    headless = true,
    timeout = 30000,
    viewport = { width: 1280, height: 720 },
    baseUrl = ''
  } = options;

  const browser = await chromium.launch({ headless });
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();

  page.setDefaultTimeout(timeout);

  const results = {
    stepNumber,
    pass: true,
    actions: [],
    error: null,
    screenshot: null
  };

  try {
    for (const action of actions) {
      const actionResult = { action, success: false, error: null };

      try {
        switch (action.type) {
          case 'navigate':
            const url = action.url.startsWith('http') ? action.url : baseUrl + action.url;
            await page.goto(url, { waitUntil: 'networkidle' });
            actionResult.success = true;
            break;

          case 'click':
            await page.click(action.selector);
            actionResult.success = true;
            break;

          case 'fill':
            // Try common selector patterns
            const fillSelector = action.selector.startsWith('[') || action.selector.startsWith('#') || action.selector.startsWith('.')
              ? action.selector
              : `[name="${action.selector}"], [placeholder*="${action.selector}" i], label:has-text("${action.selector}") + input`;
            await page.fill(fillSelector, action.value);
            actionResult.success = true;
            break;

          case 'select':
            const selectSelector = action.selector.startsWith('[') || action.selector.startsWith('#')
              ? action.selector
              : `select[name="${action.selector}"]`;
            await page.selectOption(selectSelector, action.value);
            actionResult.success = true;
            break;

          case 'wait':
            await page.waitForTimeout(action.duration);
            actionResult.success = true;
            break;

          case 'assertText':
            await expect(page.locator('body')).toContainText(action.text, { timeout });
            actionResult.success = true;
            break;

          case 'assertNoText':
            await expect(page.locator('body')).not.toContainText(action.text, { timeout });
            actionResult.success = true;
            break;

          case 'assertURL':
            await expect(page).toHaveURL(action.url, { timeout });
            actionResult.success = true;
            break;

          case 'assertURLContains':
            await expect(page).toHaveURL(new RegExp(action.pattern), { timeout });
            actionResult.success = true;
            break;

          case 'unparseable':
            // Skip but log
            actionResult.skipped = true;
            actionResult.success = true;
            console.log(`Skipped unparseable action: ${action.line}`);
            break;

          default:
            actionResult.error = `Unknown action type: ${action.type}`;
        }
      } catch (actionError) {
        actionResult.error = actionError.message;
        results.pass = false;
        results.error = actionError.message;
        // Capture screenshot on failure (handled in Step 4)
        break; // Stop execution on first failure
      }

      results.actions.push(actionResult);
    }
  } finally {
    await browser.close();
  }

  return results;
}
```

### Execution Flow

1. Launch headless Chromium browser
2. Create new page with configured viewport
3. Execute each action in sequence
4. Stop on first failure and capture error
5. Close browser and return results

### Timeout and Wait Handling

- Default action timeout: 30 seconds
- Navigation waits for `networkidle` state
- Explicit waits via `When I wait for X seconds`
- Assertions have configurable timeout

## Step 4: Capture Screenshot on Failure

When a QA Step fails, capture a screenshot of the current page state for inclusion in bug reports.

### Screenshot Capture Implementation

Update the executeStep function to capture screenshots on failure:

```javascript
async function executeStep(stepNumber, actions, options = {}) {
  // ... browser launch code from Step 3 ...

  try {
    for (const action of actions) {
      const actionResult = { action, success: false, error: null };

      try {
        // ... action execution code from Step 3 ...
      } catch (actionError) {
        actionResult.error = actionError.message;
        results.pass = false;
        results.error = actionError.message;

        // Capture screenshot on failure
        const screenshotPath = `/tmp/qa-screenshot-step-${stepNumber}-${Date.now()}.png`;
        try {
          await page.screenshot({
            path: screenshotPath,
            fullPage: true
          });
          results.screenshot = screenshotPath;
          console.log(`Screenshot captured: ${screenshotPath}`);
        } catch (screenshotError) {
          console.warn(`Failed to capture screenshot: ${screenshotError.message}`);
        }

        break; // Stop execution on first failure
      }

      results.actions.push(actionResult);
    }
  } finally {
    await browser.close();
  }

  return results;
}
```

### Screenshot Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `fullPage` | `true` | Capture entire scrollable page |
| `path` | `/tmp/qa-screenshot-step-{N}-{timestamp}.png` | File path |
| `type` | `png` | Image format (png for quality) |

### Screenshot Handling Notes

1. **Temp directory**: Screenshots saved to `/tmp/` for accessibility
2. **Naming convention**: `qa-screenshot-step-{stepNumber}-{timestamp}.png`
3. **Full page**: Captures entire page, not just viewport
4. **Error resilience**: Screenshot failure doesn't fail the test (warns only)
5. **No screenshot on pass**: Only captured when test fails

### Accessing Screenshots

The screenshot path is returned in the results object:

```javascript
const results = await executeStep(42, actions);
if (!results.pass && results.screenshot) {
  console.log(`Failure screenshot: ${results.screenshot}`);
  // Pass to bug creation workflow
}
```

## Step 5: Handle Pass Result with GitHub Comment

When a QA Step passes, post a success comment on the Step issue.

### Pass Comment Template

```bash
gh issue comment "$STEP" --body "$(cat <<'COMMENT'
## ✅ Passed

- **Executed by:** AI (Claude Code)
- **Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Result:** All assertions passed

### Actions Executed

- Navigate to <URL>
- Click <element>
- Fill <field> with <value>
- Assert text "<text>" visible
COMMENT
)"
```

### Pass Handler Implementation

```javascript
async function handlePassResult(stepNumber, results) {
  const timestamp = new Date().toISOString().replace('T', ' ').replace(/\.\d+Z$/, ' UTC');

  // Build action summary
  const actionSummary = results.actions
    .filter(a => a.success && !a.skipped)
    .map(a => {
      switch (a.action.type) {
        case 'navigate': return `- Navigate to ${a.action.url}`;
        case 'click': return `- Click \`${a.action.selector}\``;
        case 'fill': return `- Fill \`${a.action.selector}\` with "${a.action.value}"`;
        case 'select': return `- Select "${a.action.value}" from \`${a.action.selector}\``;
        case 'wait': return `- Wait ${a.action.duration / 1000} seconds`;
        case 'assertText': return `- Assert text "${a.action.text}" visible`;
        case 'assertNoText': return `- Assert text "${a.action.text}" not visible`;
        case 'assertURL': return `- Assert URL is ${a.action.url}`;
        case 'assertURLContains': return `- Assert URL contains "${a.action.pattern}"`;
        default: return `- ${a.action.type}`;
      }
    })
    .join('\n');

  const comment = `## ✅ Passed

- **Executed by:** AI (Claude Code)
- **Timestamp:** ${timestamp}
- **Result:** All assertions passed

### Actions Executed

${actionSummary}`;

  // Post comment using gh CLI
  const { execSync } = require('child_process');
  execSync(`gh issue comment ${stepNumber} --body "${comment.replace(/"/g, '\\"')}"`, {
    stdio: 'inherit'
  });

  console.log(`Posted pass comment on QA Step #${stepNumber}`);
}
```

### Pass Comment Format

| Field | Value |
|-------|-------|
| Emoji | ✅ |
| Executed by | AI (Claude Code) |
| Timestamp | UTC timestamp |
| Result | All assertions passed |
| Actions | Bulleted list of executed actions |

## Step 6: Handle Fail Result and Trigger Bug Creation

When a QA Step fails, post a failure comment and trigger the bug creation workflow.

### Fail Comment Template

```bash
gh issue comment "$STEP" --body "$(cat <<'COMMENT'
## ❌ Failed

- **Executed by:** AI (Claude Code)
- **Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Error:** <error message>

### Failed Action

- **Action:** <action that failed>
- **Expected:** <what was expected>
- **Actual:** <what happened>

### Screenshot

📸 Screenshot captured for bug report

### Bug Report

🐛 Creating bug issue...
COMMENT
)"
```

### Fail Handler Implementation

```javascript
async function handleFailResult(stepNumber, stepTitle, stepBody, results, qaNumber) {
  const timestamp = new Date().toISOString().replace('T', ' ').replace(/\.\d+Z$/, ' UTC');

  // Find the failed action
  const failedAction = results.actions.find(a => a.error);
  const failedActionDesc = failedAction
    ? describeAction(failedAction.action)
    : 'Unknown action';

  // Extract scenario from step body
  const scenarioMatch = stepBody.match(/## Scenario\s+([\s\S]*?)(?=##|$)/);
  const scenario = scenarioMatch ? scenarioMatch[1].trim() : 'Scenario not found';

  // Build failure comment
  const comment = `## ❌ Failed

- **Executed by:** AI (Claude Code)
- **Timestamp:** ${timestamp}
- **Error:** ${results.error}

### Failed Action

\`\`\`
${failedActionDesc}
\`\`\`

### Scenario

\`\`\`
${scenario}
\`\`\`

### Screenshot

${results.screenshot ? '📸 Screenshot captured: `' + results.screenshot + '`' : '⚠️ No screenshot available'}

### Bug Report

🐛 Creating bug issue...`;

  // Post failure comment
  const { execSync } = require('child_process');
  execSync(`gh issue comment ${stepNumber} --body "${comment.replace(/"/g, '\\"').replace(/`/g, '\\`')}"`, {
    stdio: 'inherit'
  });

  // Trigger bug creation workflow (Epic #9)
  // Pass context: step number, error, screenshot path, scenario
  const bugContext = {
    qaStep: stepNumber,
    qaIssue: qaNumber,
    title: `Bug: ${stepTitle.replace('QA Step: ', '')} - Failed`,
    error: results.error,
    scenario: scenario,
    screenshot: results.screenshot,
    timestamp: timestamp
  };

  // Create bug issue with full template (Epic #9 implementation)
  // Extract PRD number from QA Issue body for traceability chain
  const qaIssueData = JSON.parse(
    execSync(`gh issue view ${qaNumber} --json body`, { encoding: 'utf-8' })
  );
  const prdMatch = qaIssueData.body.match(/PRD[:\s#]+(\d+)/i);
  const prdNumber = prdMatch ? prdMatch[1] : 'Unknown';

  // Extract Then clause for expected behavior
  const thenMatch = scenario.match(/Then\s+(.+?)(?:\n|$)/i);
  const expectedBehavior = thenMatch ? thenMatch[1].trim() : 'As specified in the QA Step assertions';

  // Build bug body with full template structure (FR6 from PRD #5)
  const bugBody = `# Bug: ${stepTitle.replace('QA Step: ', '')}

## Source

- **QA Step:** #${stepNumber}
- **QA Issue:** #${qaNumber}
- **PRD:** #${prdNumber}

## Reproduction Steps

${generateReproductionSteps(scenario, results.error)}

## Expected Behavior

${expectedBehavior}

## Actual Behavior

${results.error}

## Screenshot

${results.screenshot ? '📸 Screenshot attached below' : '⚠️ No screenshot available'}

## Environment

- **Browser:** Chromium (Playwright)
- **Viewport:** 1280x720
- **Timestamp:** ${timestamp}
- **Executor:** AI (Claude Code)
`;

  const bugUrl = execSync(
    `gh issue create --title "Bug: ${stepTitle.replace('QA Step: ', '')} - Failed" --label "Bug" --body "${bugBody.replace(/"/g, '\\"').replace(/`/g, '\\`')}"`,
    { encoding: 'utf-8' }
  ).trim();

  const bugNumber = bugUrl.match(/\/(\d+)$/)?.[1];

  // Update the failure comment with bug link
  execSync(`gh issue comment ${stepNumber} --body "🐛 Bug created: ${bugUrl}"`, {
    stdio: 'inherit'
  });

  console.log(`Posted fail comment and created bug #${bugNumber} for QA Step #${stepNumber}`);

  return bugNumber;
}

function describeAction(action) {
  switch (action.type) {
    case 'navigate': return `Navigate to ${action.url}`;
    case 'click': return `Click ${action.selector}`;
    case 'fill': return `Fill ${action.selector} with "${action.value}"`;
    case 'select': return `Select "${action.value}" from ${action.selector}`;
    case 'assertText': return `Assert text "${action.text}" is visible`;
    case 'assertNoText': return `Assert text "${action.text}" is not visible`;
    case 'assertURL': return `Assert URL is ${action.url}`;
    case 'assertURLContains': return `Assert URL contains "${action.pattern}"`;
    default: return JSON.stringify(action);
  }
}

// Generate numbered reproduction steps from Given/When/Then scenario (Task #40)
function generateReproductionSteps(scenario, error) {
  const steps = [];
  const lines = scenario.split('\n').map(l => l.trim()).filter(l => l);

  let stepNum = 1;
  for (const line of lines) {
    if (/^Given\s+/i.test(line)) {
      // Convert Given to setup step
      const action = line.replace(/^Given\s+/i, '');
      steps.push(`${stepNum}. ${action.replace(/^I am on /, 'Navigate to ')}`);
      stepNum++;
    } else if (/^When\s+/i.test(line)) {
      // Convert When to action step
      const action = line.replace(/^When\s+/i, '');
      steps.push(`${stepNum}. ${action.charAt(0).toUpperCase() + action.slice(1)}`);
      stepNum++;
    } else if (/^And\s+/i.test(line)) {
      // And clauses continue previous context
      const action = line.replace(/^And\s+/i, '');
      steps.push(`${stepNum}. ${action.charAt(0).toUpperCase() + action.slice(1)}`);
      stepNum++;
    }
    // Skip Then clauses - they are expectations, not steps
  }

  // Add failure observation as final step
  steps.push(`${stepNum}. **Observe:** ${error}`);

  return steps.join('\n');
}
```

### Fail Comment Format

| Field | Value |
|-------|-------|
| Emoji | ❌ |
| Executed by | AI (Claude Code) |
| Timestamp | UTC timestamp |
| Error | Error message from Playwright |
| Failed Action | Description of the action that failed |
| Scenario | The Given/When/Then from the step |
| Screenshot | Path to captured screenshot |
| Bug Report | Link to created bug issue |

### Bug Issue Template Structure (FR6 from PRD #5)

The created bug issue follows this template:

```markdown
# Bug: <Brief Description>

## Source
- QA Step: #<step_number>
- QA Issue: #<qa_number>
- PRD: #<prd_number>

## Reproduction Steps
1. Navigate to <URL>
2. <action from When clause>
3. <additional actions>
4. **Observe:** <error message>

## Expected Behavior
<from the QA Step's Then clause>

## Actual Behavior
<what actually happened / error message>

## Screenshot
📸 Screenshot attached below (or warning if unavailable)

## Environment
- Browser: Chromium (Playwright)
- Viewport: 1280x720
- Timestamp: <execution time>
- Executor: AI (Claude Code)
```

The bug issue includes:

1. **Source**: Full traceability chain (QA Step → QA Issue → PRD)
2. **Reproduction Steps**: Numbered list generated from Given/When/Then + failure observation
3. **Expected Behavior**: Extracted from Then clause
4. **Actual Behavior**: Error message from Playwright
5. **Screenshot**: Attached screenshot (when available)
6. **Environment**: Browser, viewport, timestamp details

## Step 7: Update QA Step Execution Log Section

Update the Execution Log section in the QA Step issue body with execution results.

### Execution Log Section Format

The QA Step issue body contains an Execution Log section:

```markdown
## Execution Log

- [ ] Pass / Fail
- **Executed by:** (not yet executed)
- **Timestamp:** (pending)
- **Notes:** (none)
```

After execution, update to:

**On Pass:**

```markdown
## Execution Log

- [x] Pass / ~~Fail~~
- **Executed by:** AI (Claude Code)
- **Timestamp:** 2025-01-15 14:30:00 UTC
- **Notes:** All 5 actions completed successfully
```

**On Fail:**

```markdown
## Execution Log

- [ ] ~~Pass~~ / Fail
- **Executed by:** AI (Claude Code)
- **Timestamp:** 2025-01-15 14:30:00 UTC
- **Notes:** Failed at action 3: Assert text "Welcome" visible - Bug #123 created
```

### Update Implementation

```javascript
async function updateExecutionLog(stepNumber, results, bugNumber = null) {
  const timestamp = new Date().toISOString().replace('T', ' ').replace(/\.\d+Z$/, ' UTC');

  // Fetch current issue body
  const { execSync } = require('child_process');
  const issueData = JSON.parse(
    execSync(`gh issue view ${stepNumber} --json body`, { encoding: 'utf-8' })
  );
  let body = issueData.body;

  // Build new Execution Log content
  let newExecutionLog;
  if (results.pass) {
    const actionCount = results.actions.filter(a => a.success).length;
    newExecutionLog = `## Execution Log

- [x] Pass / ~~Fail~~
- **Executed by:** AI (Claude Code)
- **Timestamp:** ${timestamp}
- **Notes:** All ${actionCount} actions completed successfully`;
  } else {
    const failedIndex = results.actions.findIndex(a => a.error);
    const notes = bugNumber
      ? `Failed at action ${failedIndex + 1}: ${results.error} - Bug #${bugNumber} created`
      : `Failed at action ${failedIndex + 1}: ${results.error}`;
    newExecutionLog = `## Execution Log

- [ ] ~~Pass~~ / Fail
- **Executed by:** AI (Claude Code)
- **Timestamp:** ${timestamp}
- **Notes:** ${notes}`;
  }

  // Replace Execution Log section in body
  // Match from "## Execution Log" to next "##" or end of string
  const executionLogRegex = /## Execution Log[\s\S]*?(?=##[^#]|$)/;

  if (executionLogRegex.test(body)) {
    body = body.replace(executionLogRegex, newExecutionLog + '\n\n');
  } else {
    // If no Execution Log section exists, append it
    body = body + '\n\n' + newExecutionLog;
  }

  // Update issue body
  // Write body to temp file to avoid shell escaping issues
  const fs = require('fs');
  const tempFile = `/tmp/qa-step-body-${stepNumber}.md`;
  fs.writeFileSync(tempFile, body);

  execSync(`gh issue edit ${stepNumber} --body-file "${tempFile}"`, {
    stdio: 'inherit'
  });

  // Clean up temp file
  fs.unlinkSync(tempFile);

  console.log(`Updated Execution Log for QA Step #${stepNumber}`);
}
```

### Update Notes

1. **Preserve other sections**: Only replace the Execution Log section
2. **Shell escaping**: Use temp file to avoid issues with special characters
3. **Pass/Fail checkbox**: Use strikethrough to indicate the opposite result
4. **Bug reference**: Include bug number in notes when applicable

</workflow>

<operating_rules>

- Do not ask clarifying questions. Make reasonable assumptions and proceed.
- Do not create local markdown files. All output goes into GitHub issues/comments.
- Execute steps sequentially, posting results after each step completes.
- If a step fails, continue to the next step (don't abort entire QA run).
- Minimize noise: only comment at meaningful milestones (pass/fail results).
- Never retry failed steps automatically (manual retry or bug triage expected).

</operating_rules>

<prerequisites>

Before execution, verify:

```bash
# 1. Check gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Check Playwright installation
npx playwright --version || { echo "ERROR: Playwright not installed. Run 'npm install -D @playwright/test'"; exit 1; }

# 3. Check browser availability
npx playwright install chromium --dry-run 2>/dev/null || {
  echo "WARNING: Chromium may not be installed. Run 'npx playwright install chromium'"
}
```

</prerequisites>

<input_validation>

## Validation Checks

```bash
# Validate step number format (if provided)
if [[ -n "$STEP" && ! "$STEP" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Invalid step number. Use format: step=#123"
  exit 1
fi

# Validate QA number format (if provided)
if [[ -n "$QA" && ! "$QA" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Invalid QA number. Use format: qa=#123"
  exit 1
fi

# Verify issue exists and is accessible
if [[ -n "$STEP" ]]; then
  gh issue view "$STEP" > /dev/null 2>&1 || { echo "ERROR: Cannot access QA Step #$STEP"; exit 1; }
fi

if [[ -n "$QA" ]]; then
  gh issue view "$QA" > /dev/null 2>&1 || { echo "ERROR: Cannot access QA Issue #$QA"; exit 1; }
fi
```

</input_validation>

<error_handling>

## Common Errors and Recovery

**If gh CLI not authenticated:**

- Check: `gh auth status`
- Fix: `gh auth login`

**If Playwright not installed:**

- Check: `npx playwright --version`
- Fix: `npm install -D @playwright/test && npx playwright install chromium`

**If browser not installed:**

- Check: `npx playwright install chromium --dry-run`
- Fix: `npx playwright install chromium`

**If QA Step/Issue not found:**

- Verify issue number is correct
- Check repository access permissions
- Confirm issue is not closed/deleted

**If no QA Steps found for QA Issue:**

- Verify QA Steps are linked as sub-issues
- Check that QA Steps have the `QA-Step` label
- Confirm QA Steps are in OPEN state

**If Given/When/Then parsing fails:**

- Log warning with unparseable line
- Skip unparseable actions during execution
- Include unparseable lines in execution report

**If Playwright action fails:**

- Capture screenshot before closing browser
- Post failure comment with error details
- Create bug issue with context
- Continue to next QA Step (don't abort run)

**If screenshot capture fails:**

- Log warning but don't fail the step
- Note "No screenshot available" in bug report

**If GitHub API rate limited:**

- Check: `gh api rate_limit`
- Wait and retry, or authenticate with higher-privilege token

</error_handling>

<success_criteria>

Command completes successfully when:

1. Target QA Steps have been resolved (from argument or auto-resolved)
2. Each QA Step has been executed through Playwright
3. Pass results: ✅ comment posted, Execution Log updated
4. Fail results: ❌ comment posted, bug created, Execution Log updated
5. All steps processed (failures don't abort the run)

**Verification:**

```bash
# Check execution comments on QA Steps
gh issue view "$STEP" --json comments -q '.comments[-1].body'

# Check Execution Log was updated
gh issue view "$STEP" --json body -q '.body' | grep -A5 "## Execution Log"

# Check bugs created for failures
gh issue list -l Bug --json number,title
```

</success_criteria>

<output>

After completion, report:

1. **QA Steps executed:** Count and issue numbers
2. **Results:**
   - Passed: Count and step numbers
   - Failed: Count, step numbers, and bug numbers created
3. **Unparseable steps:** Count and warnings
4. **Execution time:** Total duration
5. **Errors:** Any issues encountered

**Example output:**

```
## QA Execution Complete

- **QA Issue:** #42
- **Steps executed:** 5

### Results

| Step | Title | Result | Bug |
|------|-------|--------|-----|
| #101 | Valid login | ✅ Pass | - |
| #102 | Invalid password | ✅ Pass | - |
| #103 | Form validation | ❌ Fail | #150 |
| #104 | Password reset | ✅ Pass | - |
| #105 | Logout | ✅ Pass | - |

### Summary

- **Passed:** 4
- **Failed:** 1
- **Bugs created:** 1 (#150)
- **Execution time:** 2m 34s
```

</output>

Proceed now.
