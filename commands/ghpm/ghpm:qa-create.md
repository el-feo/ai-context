---
description: Create a QA Issue as sub-issue of a PRD
allowed-tools: [Read, Bash, Grep, Glob]
---
# /ghpm:qa-create

You are GHPM (GitHub Project Manager). Create a QA Issue for acceptance testing and link it as a sub-issue of the specified PRD.

## Arguments

- Optional: `prd=#123` - PRD issue number to create QA Issue for

If omitted, choose the most recent open issue labeled `PRD`.

## QA Issue format (body)

```markdown
# QA: <PRD Title> - Acceptance Testing

## Overview

<Brief description derived from PRD objective>

## Parent PRD

- PRD: #<PRD_NUMBER>

## QA Steps

(Populated by /ghpm:qa-create-steps)
- [ ] (No steps created yet)

## Status

- [ ] All steps created
- [ ] All steps passed
- [ ] Bugs found: (none)
```

## GitHub publishing steps (execute via bash)

### Step 1: Resolve PRD number

```bash
# If prd=#N is provided, use N
# Else: auto-resolve to most recent open PRD
PRD=$(gh issue list -l PRD -s open --limit 1 --json number -q '.[0].number')

if [ -z "$PRD" ]; then
  echo "Error: No open PRD found. Specify prd=#N or create a PRD first."
  exit 1
fi
```

### Step 2: Fetch PRD details

```bash
# Fetch PRD title, body, and URL
PRD_DATA=$(gh issue view "$PRD" --json title,body,url -q '.')
PRD_TITLE=$(echo "$PRD_DATA" | jq -r '.title')
PRD_URL=$(echo "$PRD_DATA" | jq -r '.url')

if [ -z "$PRD_TITLE" ]; then
  echo "Error: Could not fetch PRD #$PRD. Check if it exists and is accessible."
  exit 1
fi

echo "PRD #$PRD: $PRD_TITLE"
echo "URL: $PRD_URL"
```

### Step 3: Ensure QA label exists

```bash
# Create QA label if it doesn't exist (ignore error if already exists)
gh label create QA --description "QA Issue for acceptance testing" --color 6B3FA0 2>/dev/null || true
```

### Step 4: Create QA Issue

```bash
# Build QA Issue body from template
QA_TITLE="QA: $PRD_TITLE - Acceptance Testing"

QA_BODY=$(cat <<BODY
# QA: $PRD_TITLE - Acceptance Testing

## Overview

Acceptance testing for PRD: $PRD_TITLE

## Parent PRD

- PRD: #$PRD

## QA Steps

(Populated by /ghpm:qa-create-steps)
- [ ] (No steps created yet)

## Status

- [ ] All steps created
- [ ] All steps passed
- [ ] Bugs found: (none)
BODY
)

# Create the QA Issue
QA_URL=$(gh issue create --title "$QA_TITLE" --label "QA" --body "$QA_BODY")
QA_NUMBER=$(echo "$QA_URL" | grep -oE '[0-9]+$')

echo "Created QA Issue #$QA_NUMBER: $QA_URL"
```

### Step 5: Link QA Issue as sub-issue of PRD

```bash
# Get repository owner and name
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# Get the QA Issue's internal ID
QA_ID=$(gh api repos/$OWNER/$REPO/issues/$QA_NUMBER --jq .id)

# Add QA Issue as sub-issue of PRD
gh api repos/$OWNER/$REPO/issues/$PRD/sub_issues \
  -X POST \
  -F sub_issue_id=$QA_ID \
  --silent && echo "Linked QA Issue #$QA_NUMBER as sub-issue of PRD #$PRD" \
  || echo "Warning: Could not link QA Issue as sub-issue (feature may not be available)"
```

### Step 6: Add to GitHub Project (optional)

```bash
# If GHPM_PROJECT is set, add QA Issue to project (best-effort)
if [ -n "$GHPM_PROJECT" ]; then
  gh project item-add "$GHPM_PROJECT" --owner "$OWNER" --url "$QA_URL" \
    && echo "Added QA Issue to project: $GHPM_PROJECT" \
    || echo "Warning: Could not add QA Issue to project"
fi
```

### Step 7: Comment on PRD with QA Issue link

```bash
gh issue comment "$PRD" --body "$(cat <<COMMENT
## QA

- [ ] #$QA_NUMBER $QA_TITLE

QA Issue created for acceptance testing.
COMMENT
)"

echo "Posted QA link comment on PRD #$PRD"
```

