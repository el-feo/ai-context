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

