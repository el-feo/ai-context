---
description: Create QA Step issues as sub-issues of a QA Issue
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  qa:
    description: "QA issue number (format: qa=#123)"
    required: false
---

<qa_step_issue_template>

## QA Step Issue Body Template

```markdown
# QA Step: <Brief Description>

## Scenario

As a <role>,
Given <precondition>,
When <action>,
Then <expected outcome>

## Parent QA Issue

- QA: #<QA_NUMBER>

## Test Details

- **URL/Page:** <starting URL or page>
- **Prerequisites:** <any setup needed>
- **Test Data:** <if applicable>

## Execution Log

- [ ] Pass / Fail
- **Executed by:** (not yet executed)
- **Timestamp:** (pending)
- **Notes:** (none)

## Bugs Found

(None)
```

### Template Field Descriptions

| Field | Description |
|-------|-------------|
| `<Brief Description>` | Concise 3-8 word summary of what is being tested |
| `<role>` | User role or persona (e.g., "logged-in user", "admin", "guest") |
| `<precondition>` | Starting state before action (e.g., "I am on the dashboard page") |
| `<action>` | Single user action being tested (e.g., "I click the Submit button") |
| `<expected outcome>` | Observable result (e.g., "I should see a success message") |
| `<QA_NUMBER>` | Parent QA Issue number |
| `<URL/Page>` | Starting URL or page name |
| `<Prerequisites>` | Any setup required before testing |
| `<Test Data>` | Specific test data needed (if any) |

### Given/When/Then Format Guidelines

- **Given** describes the initial state or preconditions
- **When** describes a single, atomic user action
- **Then** describes the expected observable outcome
- Keep each step atomic (one action per QA Step)
- Use clear, specific language that is machine-parseable

</qa_step_issue_template>

<objective>
You are GHPM (GitHub Project Manager). Generate QA Step issues for systematic acceptance testing and link them as sub-issues of the specified QA Issue. Each QA Step follows the Given/When/Then format for consistent, machine-parseable test scenarios.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- Target QA Issue exists and is accessible
- QA Issue should have a linked PRD for context
</prerequisites>

<arguments>
**Optional arguments:**
- `qa=#123` - QA issue number

**Resolution order if omitted:**

1. Most recent open QA issue:
   `gh issue list -l QA -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**With QA number:**

```bash
/ghpm:qa-create-steps qa=#42
```

**Auto-resolve most recent QA issue:**

```bash
/ghpm:qa-create-steps
```

</usage_examples>

<workflow>

## Step 1: Resolve Target QA Issue

```bash
# If qa=#N provided, use N
QA={provided_qa_number}

# Else pick most recent open QA issue
QA=$(gh issue list -l QA -s open --limit 1 --json number -q '.[0].number')

if [ -z "$QA" ]; then
  echo "Error: No open QA issue found. Specify qa=#N or create a QA issue first."
  exit 1
fi

# Validate QA number is positive integer
if ! [[ "$QA" =~ ^[0-9]+$ ]]; then
  echo "Error: Invalid QA number. Use format: qa=#123"
  exit 1
fi
```

## Step 2: Fetch QA Issue and PRD Context

```bash
# Fetch QA Issue details
QA_DATA=$(gh issue view "$QA" --json title,body,url -q '.')
QA_TITLE=$(echo "$QA_DATA" | jq -r '.title')
QA_BODY=$(echo "$QA_DATA" | jq -r '.body')
QA_URL=$(echo "$QA_DATA" | jq -r '.url')

if [ -z "$QA_TITLE" ]; then
  echo "Error: Could not fetch QA Issue #$QA. Check if it exists and is accessible."
  exit 1
fi

echo "QA Issue #$QA: $QA_TITLE"
echo "URL: $QA_URL"

# Extract PRD reference from QA Issue body (look for "PRD: #123" pattern)
PRD=$(echo "$QA_BODY" | grep -oE 'PRD: #[0-9]+' | head -1 | grep -oE '[0-9]+')

if [ -n "$PRD" ]; then
  # Fetch PRD details for additional context
  PRD_DATA=$(gh issue view "$PRD" --json title,body -q '.')
  PRD_TITLE=$(echo "$PRD_DATA" | jq -r '.title')
  PRD_BODY=$(echo "$PRD_DATA" | jq -r '.body')
  echo "Parent PRD #$PRD: $PRD_TITLE"
else
  echo "Warning: No PRD reference found in QA Issue. Generating steps from QA Issue context only."
fi
```

## Step 3: Generate QA Steps from Context

Analyze the QA Issue and PRD context to generate 5-20 QA Steps that:

1. Cover all acceptance criteria from the PRD
2. Test key user flows and interactions
3. Include both happy path and critical error cases
4. Are atomic (one user action per step)

### Step Generation Strategy

```
For each acceptance criterion in the PRD:
  1. Identify the user role performing the action
  2. Determine the precondition (starting state)
  3. Extract the specific user action
  4. Define the expected observable outcome
  5. Note any test data or prerequisites needed
```

### Step Categories to Cover

| Category | Examples |
|----------|----------|
| **Happy Path** | Core user flows work as expected |
| **Validation** | Required fields, format validation |
| **Edge Cases** | Empty states, boundary values |
| **Error Handling** | Invalid input, network errors |
| **Permissions** | Access control, role-based behavior |

### Generation Guidelines

- **Be specific**: "I click the Submit button" not "I submit the form"
- **Be observable**: "I should see a success message" not "The form is submitted"
- **Be atomic**: One action per step, split complex flows into multiple steps
- **Be consistent**: Use the same terminology as the PRD/QA Issue
- **Target 5-20 steps**: Enough for thorough coverage, not so many as to be overwhelming

### Example Generated Steps

Given a PRD for "User Login Feature", generate steps like:

1. **QA Step: Valid login with correct credentials**
   - As a guest user,
   - Given I am on the login page,
   - When I enter valid credentials and click Login,
   - Then I should be redirected to the dashboard

2. **QA Step: Login with invalid password**
   - As a guest user,
   - Given I am on the login page,
   - When I enter a valid email but incorrect password,
   - Then I should see an error message "Invalid credentials"

3. **QA Step: Login form validation**
   - As a guest user,
   - Given I am on the login page,
   - When I click Login without entering any credentials,
   - Then I should see validation errors for email and password fields

## Step 4: Create QA Step Issues with QA-Step Label

```bash
# Get repository owner and name
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Ensure QA-Step label exists (create if not)
gh label create QA-Step --description "QA Step for acceptance testing" --color 9B59B6 2>/dev/null || true
```

For each generated QA Step, create a GitHub issue:

```bash
# For each step, create issue with populated template
STEP_TITLE="QA Step: <Brief Description>"

STEP_BODY=$(cat <<BODY
# QA Step: <Brief Description>

## Scenario

As a <role>,
Given <precondition>,
When <action>,
Then <expected outcome>

## Parent QA Issue

- QA: #$QA

## Test Details

- **URL/Page:** <starting URL or page>
- **Prerequisites:** <any setup needed>
- **Test Data:** <if applicable>

## Execution Log

- [ ] Pass / Fail
- **Executed by:** (not yet executed)
- **Timestamp:** (pending)
- **Notes:** (none)

## Bugs Found

(None)
BODY
)

# Create the QA Step issue
STEP_URL=$(gh issue create \
  --title "$STEP_TITLE" \
  --label "QA-Step" \
  --body "$STEP_BODY")

# Extract step number from URL
STEP_NUM=$(echo "$STEP_URL" | grep -oE '[0-9]+$')

echo "Created QA Step #$STEP_NUM: $STEP_URL"

# Store step number and title for later use
STEP_NUMBERS+=("$STEP_NUM")
STEP_TITLES["$STEP_NUM"]="$STEP_TITLE"
```

### Issue Creation Notes

- Create all steps before proceeding to linking
- If any step creation fails, log the error and continue with remaining steps
- Track created step numbers for sub-issue linking and checklist generation

## Step 5: Link QA Steps as Sub-Issues of QA Issue

**IMPORTANT:** QA Steps MUST be linked as sub-issues of the QA Issue, not just listed in a comment.

For each created QA Step, link it as a sub-issue:

```bash
# Get the QA Step's internal issue ID
STEP_ID=$(gh api repos/$OWNER/$REPO/issues/$STEP_NUM --jq .id)

# Add QA Step as sub-issue of QA Issue
gh api repos/$OWNER/$REPO/issues/$QA/sub_issues \
  -X POST \
  -F sub_issue_id=$STEP_ID \
  --silent && echo "Linked QA Step #$STEP_NUM as sub-issue of QA #$QA" \
  || echo "Warning: Could not link QA Step #$STEP_NUM as sub-issue"
```

### Sub-Issue Linking Notes

- Link all steps after creation completes
- If linking fails for a step, log warning and continue with remaining steps
- Sub-issues should appear in the QA Issue's "Sub-issues" section
- Verify linking with: `gh api repos/$OWNER/$REPO/issues/$QA/sub_issues --jq '.[] | [.number, .title] | @tsv'`

### Add QA Steps to GitHub Project (Optional)

For each created QA Step, add it to the GitHub Project if `GHPM_PROJECT` is set:

```bash
# If GHPM_PROJECT is set, add QA Step to project (best-effort)
if [ -n "$GHPM_PROJECT" ]; then
  gh project item-add "$GHPM_PROJECT" --owner "$OWNER" --url "$STEP_URL" \
    && echo "Added QA Step #$STEP_NUM to project: $GHPM_PROJECT" \
    || echo "Warning: Could not add QA Step #$STEP_NUM to project"
fi
```

### Fallback if Sub-Issues Not Supported

If the sub-issues API is not available (older GitHub Enterprise, etc.):

1. Log a warning that sub-issue linking is not available
2. Continue to Step 6 (checklist comment) which provides alternative tracking
3. Consider adding a comment on each QA Step referencing the parent QA Issue

## Step 6: Add QA Issue Comment with QA Steps Checklist

Post a comment on the QA Issue with a checklist of all created QA Steps for tracking:

```bash
# Build checklist from created steps
CHECKLIST=""
for step_num in "${STEP_NUMBERS[@]}"; do
  step_title="${STEP_TITLES[$step_num]}"
  CHECKLIST="$CHECKLIST
- [ ] #$step_num $step_title"
done

# Post comment on QA Issue
gh issue comment "$QA" --body "$(cat <<COMMENT
## QA Steps

The following QA Steps have been created for acceptance testing:
$CHECKLIST

### Execution Instructions

1. Execute each step in order
2. Mark the checkbox when the step passes
3. If a step fails, create a Bug issue and link it in the step's "Bugs Found" section
4. Update each step's Execution Log with results
COMMENT
)"

echo "Posted QA Steps checklist comment on QA Issue #$QA"
```

### Checklist Format

The checklist follows this format for consistent tracking:

```markdown
## QA Steps

The following QA Steps have been created for acceptance testing:

- [ ] #101 QA Step: Valid login with correct credentials
- [ ] #102 QA Step: Login with invalid password
- [ ] #103 QA Step: Login form validation
...

### Execution Instructions

1. Execute each step in order
2. Mark the checkbox when the step passes
3. If a step fails, create a Bug issue and link it in the step's "Bugs Found" section
4. Update each step's Execution Log with results
```

</workflow>

<operating_rules>

- Do not ask clarifying questions. Make assumptions and record them in the QA Steps.
- Do not create local markdown files. All output goes into GitHub issues/comments.
- QA Steps must be atomic and independently testable.
- Each QA Step must follow the Given/When/Then format consistently.
- Generate 5-20 QA Steps per QA Issue that fully cover the acceptance criteria.
- Each QA Step MUST be linked as a sub-issue of the parent QA Issue.

</operating_rules>

<input_validation>

## Validation Checks

Before proceeding, validate:

```bash
# 1. Check gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Validate QA issue number format (if provided)
# QA number must be a positive integer
if [[ -n "$QA" && ! "$QA" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Invalid QA number. Use format: qa=#123"
  exit 1
fi

# 3. Verify QA issue exists and is accessible
gh issue view "$QA" > /dev/null 2>&1 || { echo "ERROR: Cannot access QA issue #$QA"; exit 1; }
```

</input_validation>

<error_handling>

**If gh CLI not authenticated:**

- Check: `gh auth status`
- Fix: `gh auth login`

**If QA Issue not found:**

- Verify issue number is correct
- Check repository access permissions
- Confirm issue is not closed/deleted

**If no open QA Issue found (auto-resolve):**

- Create a QA Issue first using `/ghpm:qa-create`
- Or specify an explicit QA number with `qa=#N`

**If PRD reference not found in QA Issue:**

- Continue with QA Issue context only
- Log warning: "No PRD reference found. Generating steps from QA Issue context only."

**If QA Step creation fails:**

- Check rate limits: `gh api rate_limit`
- Verify label "QA-Step" exists or create it
- Check repository write permissions
- Log error and continue with remaining steps

**If sub-issue linking fails:**

- Continue with next step (don't block on linking failures)
- Log warning in output summary with specific step number
- Common causes: step already has a parent, duplicate sub-issue, API error
- Checklist comment provides alternative tracking

**If project add fails:**

- Print warning and continue (best-effort)
- Common causes: project not found, user lacks project permissions
- Do not block QA Step creation on project failures

</error_handling>

<success_criteria>

Command completes successfully when:

1. Target QA Issue has been resolved (explicit or auto-detected)
2. PRD context has been fetched (if available)
3. 5-20 QA Step issues have been created with `QA-Step` label
4. Each QA Step follows the Given/When/Then format
5. Each QA Step is linked as a sub-issue of the QA Issue
6. QA Steps added to `GHPM_PROJECT` when set (best-effort)
7. Checklist comment has been posted on the QA Issue

**Verification:**

```bash
# List created QA Steps
gh issue list -l QA-Step -s open --limit 50 --json number,title

# Verify sub-issues are linked to QA Issue
gh api repos/{owner}/{repo}/issues/$QA/sub_issues --jq '.[] | [.number, .title] | @tsv'

# View QA Issue to confirm (sub-issues and checklist appear)
gh issue view "$QA"
```

</success_criteria>

<output>

After completion, report:

1. **QA Issue processed:** # and URL
2. **PRD context:** # and title (if found)
3. **QA Steps created:** Issue numbers and titles
4. **Sub-issue linking:** Success/failure for each step
5. **Project association:** Success/warning/skipped for each step
6. **Total steps:** Count
7. **Warnings:** Any issues encountered (PRD not found, linking failures, project failures, etc.)

</output>

Proceed now.
