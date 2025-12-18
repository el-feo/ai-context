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

</workflow>

Proceed now.
