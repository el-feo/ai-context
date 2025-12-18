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

</workflow>

Proceed now.
