---
description: Create a QA Issue as sub-issue of a PRD
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  prd:
    description: "PRD issue number (format: prd=#123)"
    required: false
---

<objective>
You are GHPM (GitHub Project Manager). Create a QA Issue for acceptance testing and link it as a sub-issue of the specified PRD.
</objective>

<arguments>
**Optional arguments:**
- `prd=#123` - PRD issue number to create QA Issue for

**Resolution order if omitted:**

1. Most recent open issue labeled `PRD`:
   `gh issue list -l PRD -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**With PRD number:**

```bash
/ghpm:qa-create prd=#42
```

**Auto-resolve most recent PRD:**

```bash
/ghpm:qa-create
```

</usage_examples>

<qa_issue_template>

## QA Issue Body Template

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

</qa_issue_template>

<workflow>

## Step 1: Resolve PRD Number

```bash
# If prd=#N is provided, use N
PRD={provided_prd_number}

# Else: auto-resolve to most recent open PRD
PRD=$(gh issue list -l PRD -s open --limit 1 --json number -q '.[0].number')

if [ -z "$PRD" ]; then
  echo "Error: No open PRD found. Specify prd=#N or create a PRD first."
  exit 1
fi

# Validate PRD number is positive integer
if ! [[ "$PRD" =~ ^[0-9]+$ ]]; then
  echo "Error: Invalid PRD number. Use format: prd=#123"
  exit 1
fi
```

## Step 2: Fetch PRD Details

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

## Step 3: Ensure QA Label Exists

```bash
# Create QA label if it doesn't exist (ignore error if already exists)
gh label create QA --description "QA Issue for acceptance testing" --color 6B3FA0 2>/dev/null || true
```

## Step 4: Create QA Issue

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

## Step 5: Link QA Issue as Sub-Issue of PRD

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

## Step 6: Add to GitHub Project (Optional)

```bash
# If GHPM_PROJECT is set, add QA Issue to project (best-effort)
if [ -n "$GHPM_PROJECT" ]; then
  gh project item-add "$GHPM_PROJECT" --owner "$OWNER" --url "$QA_URL" \
    && echo "Added QA Issue to project: $GHPM_PROJECT" \
    || echo "Warning: Could not add QA Issue to project"
fi
```

## Step 7: Comment on PRD with QA Issue Link

```bash
gh issue comment "$PRD" --body "$(cat <<COMMENT
## QA

- [ ] #$QA_NUMBER $QA_TITLE

QA Issue created for acceptance testing.
COMMENT
)"

echo "Posted QA link comment on PRD #$PRD"
```

</workflow>

<operating_rules>

- Do not ask clarifying questions. If the PRD has ambiguity, derive a reasonable overview from the PRD objective.
- Do not create local markdown files. All output goes into GitHub issues/comments.
- Execute all `gh` commands directly via bash tool.
- If sub-issue linking fails, continue with the remaining steps (best-effort).

</operating_rules>

<input_validation>

## Validation Checks

Before proceeding, validate:

```bash
# 1. Check gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Validate PRD number format (if provided)
# PRD number must be a positive integer
if [[ -n "$PRD" && ! "$PRD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Invalid PRD number. Use format: prd=#123"
  exit 1
fi

# 3. Verify PRD issue exists and is accessible
gh issue view "$PRD" > /dev/null 2>&1 || { echo "ERROR: Cannot access PRD #$PRD"; exit 1; }
```

</input_validation>

<error_handling>

**If gh CLI not authenticated:**

- Check: `gh auth status`
- Fix: `gh auth login`

**If PRD number invalid:**

- Print error: "Invalid PRD number. Use format: prd=#123"
- Do not proceed

**If PRD not found or inaccessible:**

- Print error: "Could not fetch PRD #N. Check if it exists and you have access."
- Do not proceed

**If QA Issue creation fails:**

- Print error and stop
- Do not proceed with linking or comments

**If sub-issue linking fails:**

- Print warning, continue with remaining steps
- Common causes: feature not available, API changes

**If project add fails:**

- Print warning, continue with remaining steps
- Continue to complete command

</error_handling>

<success_criteria>

Command completes successfully when:

1. PRD has been resolved (explicit or auto-detected)
2. QA Issue created with correct title format and QA label
3. QA Issue body contains all required sections
4. QA Issue linked as sub-issue of PRD (or warning printed)
5. PRD has comment linking to QA Issue
6. Summary printed with all relevant URLs

**Verification:**

```bash
# Check QA Issue was created
gh issue view "$QA_NUMBER"

# Check sub-issue is linked to PRD
gh api repos/{owner}/{repo}/issues/$PRD/sub_issues --jq '.[] | [.number, .title] | @tsv'

# Check PRD has comment with QA link
gh issue view "$PRD" --json comments -q '.comments[-1].body'
```

</success_criteria>

<output>

After completion, report:

1. **PRD processed:** # and URL
2. **QA Issue created:** # and URL
3. **Sub-issue linking:** Success/warning
4. **Project association:** Success/warning/skipped
5. **PRD comment:** Posted

</output>

Proceed now.
