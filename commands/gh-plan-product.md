---
description: Product planning with GitHub Projects - creates product docs and GitHub Epics/issues for roadmap tracking
allowed-tools: [Read, Edit, Write, Bash, WebFetch]
---

<objective>
Generate product documentation AND create GitHub Epics/issues that appear in the project roadmap. Combines product planning with GitHub project management.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated
- GitHub Project URL or number provided
- Repository initialized (can be empty)
</prerequisites>

<workflow>

## Phase 1: Gather Inputs

### Step 1.1: Collect Product Information

Gather from user:

1. **Main idea** for the product
2. **Key features** (minimum 3)
3. **Target users** and use cases (minimum 1)
4. **Tech stack preferences**
5. **GitHub Project URL** (e.g., `https://github.com/users/{user}/projects/{n}`)
6. **Repository** (if not obvious from current directory)

If any are missing, request:

```txt
Please provide the following:
1. Main idea for the product
2. Key features (minimum 3)
3. Target users (minimum 1)
4. Tech stack preferences
5. GitHub Project URL
6. Repository name (or confirm current directory)
```

### Step 1.2: Parse Project URL

```bash
# Extract owner and project number
# Example: https://github.com/users/jsmith/projects/5
PROJECT_URL="{provided_url}"
OWNER="{extracted_owner}"
PROJECT_NUMBER="{extracted_number}"
REPO="{owner}/{repo}"

# Verify access
gh project view $PROJECT_NUMBER --owner $OWNER
```

### Step 1.3: Discover Project Fields

```bash
gh project field-list $PROJECT_NUMBER --owner $OWNER --format json
```

Look for:

- **Status** field (for workflow states)
- **Size/Estimate** field (for Fibonacci points)
- **Iteration** field (for phases/sprints)
- **Priority** field (if available)

## Phase 2: Create Product Documentation

Create `.agent-os/product/` directory structure:

```bash
mkdir -p .agent-os/product
```

### Step 2.1: Create mission.md

```markdown
# Product Mission

## Pitch
{PRODUCT_NAME} is a {PRODUCT_TYPE} that helps {TARGET_USERS} {SOLVE_PROBLEM} by providing {KEY_VALUE_PROPOSITION}.

## Users
### Primary Customers
- {CUSTOMER_SEGMENT}: {DESCRIPTION}

### User Personas
**{USER_TYPE}** ({AGE_RANGE})
- **Role:** {JOB_TITLE}
- **Pain Points:** {PAIN_POINTS}
- **Goals:** {GOALS}

## The Problem
{PROBLEM_DESCRIPTION}. {QUANTIFIABLE_IMPACT}.
**Our Solution:** {SOLUTION_DESCRIPTION}

## Differentiators
Unlike {COMPETITOR}, we provide {ADVANTAGE}. This results in {BENEFIT}.

## Key Features
{LIST_OF_FEATURES_WITH_BENEFITS}
```

### Step 2.2: Create tech-stack.md

```markdown
# Technical Stack

## Application
- **Framework:** {FRAMEWORK} {VERSION}
- **Database:** {DATABASE}
- **Frontend:** {JS_FRAMEWORK}
- **CSS:** {CSS_FRAMEWORK}
- **Components:** {UI_LIBRARY}

## Infrastructure
- **Hosting:** {APP_HOSTING}
- **Database Hosting:** {DB_HOSTING}
- **Assets:** {ASSET_HOSTING}
- **Deployment:** {DEPLOYMENT_SOLUTION}

## Repository
{CODE_REPOSITORY_URL}
```

### Step 2.3: Create roadmap.md

Structure phases for both documentation AND GitHub issues:

```markdown
# Product Roadmap

## Phase 1: {PHASE_NAME}
**Goal:** {PHASE_GOAL}
**Success Criteria:** {MEASURABLE_CRITERIA}

### Features
- [ ] {FEATURE_1} - {DESCRIPTION} `{EFFORT}`
- [ ] {FEATURE_2} - {DESCRIPTION} `{EFFORT}`
- [ ] {FEATURE_3} - {DESCRIPTION} `{EFFORT}`

## Phase 2: {PHASE_NAME}
...
```

**Effort to Fibonacci mapping:**

| Effort | Days     | Fibonacci |
| ------ | -------- | --------- |
| XS     | 1 day    | 1         |
| S      | 2-3 days | 2-3       |
| M      | 1 week   | 5         |
| L      | 2 weeks  | 8         |
| XL     | 3+ weeks | 13        |

### Step 2.4: Create mission-lite.md

```markdown
# Product Mission (Lite)

{ELEVATOR_PITCH}

{1-3_SENTENCES_VALUE_SUMMARY}
```

### Step 2.5: Create decisions.md

```markdown
# Product Decisions Log

> Override Priority: Highest

## {DATE}: Initial Product Planning

**ID:** DEC-001
**Status:** Accepted
**Category:** Product

### Decision
{PRODUCT_MISSION_SUMMARY}

### Context
{WHY_THIS_PRODUCT_WHY_NOW}

### Rationale
{KEY_DECISION_FACTORS}
```

## Phase 3: Create GitHub Epics

For each roadmap phase, create an Epic issue:

### Step 3.1: Create Phase Epics

```bash
# For each phase in roadmap
gh issue create \
  --repo $REPO \
  --title "[Epic] Phase {N}: {PHASE_NAME}" \
  --body "{EPIC_BODY}"
```

**Epic body template:**

```markdown
## Overview
{PHASE_GOAL}

## Success Criteria
{MEASURABLE_CRITERIA}

## Features
| Feature   | Description | Estimate |
| --------- | ----------- | -------- |
| {FEATURE} | {DESC}      | {EFFORT} |

## Phase Guidelines
- Phase 1: Core MVP functionality
- Phase 2: Key differentiators
- Phase 3: Scale and polish

## Dependencies
{PHASE_DEPENDENCIES}

## Size
{S/M/L/XL based on total points}
```

### Step 3.2: Create Feature Issues

For each feature in a phase:

```bash
gh issue create \
  --repo $REPO \
  --title "{FEATURE_NAME}" \
  --body "{FEATURE_BODY}"
```

**Feature body template:**

```markdown
## Summary
{FEATURE_DESCRIPTION}

## Parent Epic
#{EPIC_NUMBER}

## Acceptance Criteria
- [ ] {AC_1}
- [ ] {AC_2}
- [ ] {AC_3}

## Implementation Notes
{TECHNICAL_APPROACH_IF_KNOWN}

## Affected Components
- {COMPONENT_1}
- {COMPONENT_2}

## Estimate
**{FIBONACCI_POINTS}** points ({EFFORT_LABEL})

| Effort        | Fibonacci |
| ------------- | --------- |
| XS (1 day)    | 1         |
| S (2-3 days)  | 2-3       |
| M (1 week)    | 5         |
| L (2 weeks)   | 8         |
| XL (3+ weeks) | 13        |
```

### Step 3.3: Link Features to Epics

Use the REST API to link feature issues as sub-issues to their parent Epic.

**Important:** The `sub_issue_id` must be the **database ID** (integer), not the issue number or GraphQL node ID.

```bash
# Get the database ID for the feature issue (NOT the node ID)
FEATURE_DB_ID=$(gh api /repos/$REPO/issues/{feature_num} --jq '.id')

# Add as sub-issue using parent issue NUMBER and child DATABASE ID
gh api /repos/$REPO/issues/{epic_num}/sub_issues -X POST -F sub_issue_id=$FEATURE_DB_ID
```

**Batch linking example:**

```bash
EPIC_NUM=42
REPO="owner/repo"

# Link multiple features to an Epic
for feature_num in 43 44 45 46; do
  FEATURE_DB_ID=$(gh api /repos/$REPO/issues/$feature_num --jq '.id')
  gh api /repos/$REPO/issues/$EPIC_NUM/sub_issues -X POST -F sub_issue_id=$FEATURE_DB_ID --silent
done

# Verify linkage
gh api /repos/$REPO/issues/$EPIC_NUM/sub_issues --jq '[.[].number] | @csv'
```

**Key notes:**

- Use `-F` (not `-f`) to pass the ID as an integer type
- The URL uses the **issue number** for the parent Epic
- The body uses the **database ID** for the child feature

## Phase 4: Add to GitHub Project

### Step 4.1: Discover Project IDs and Fields

```bash
PROJECT_NUMBER={project_number}
OWNER={owner}

# Get Project ID (needed for item-edit)
PROJECT_ID=$(gh project view $PROJECT_NUMBER --owner $OWNER --format json | jq -r '.id')

# Discover all field IDs and their types
gh project field-list $PROJECT_NUMBER --owner $OWNER --format json | jq '.fields[] | {name, id, type}'
```

Save the field IDs you need:

- **Estimate field ID**: Look for `"name": "Estimate"` with `"type": "ProjectV2Field"` (number field)
- **Status field ID**: Look for `"name": "Status"` with options array
- **Size field ID**: Look for `"name": "Size"` with options like XS, S, M, L, XL

### Step 4.2: Add Epics to Project

```bash
# Add epic (no estimate needed for epics - they aggregate from children)
ITEM_ID=$(gh project item-add $PROJECT_NUMBER --owner $OWNER --url {epic_url} --format json | jq -r '.id')

# Optionally set status to Backlog
gh project item-edit --project-id $PROJECT_ID --id $ITEM_ID \
  --field-id {status_field_id} --single-select-option-id {backlog_option_id}
```

### Step 4.3: Add Features to Project with Estimates

**IMPORTANT:** After adding each feature to the project, immediately set its Estimate field. The Estimate field is a number field that accepts Fibonacci values (1, 2, 3, 5, 8, 13).

```bash
PROJECT_ID="{project_id}"
ESTIMATE_FIELD="{estimate_field_id}"

# Add single feature with estimate
ISSUE_URL="https://github.com/{owner}/{repo}/issues/{feature_num}"
FEATURE_POINTS={fibonacci_points}

ITEM_ID=$(gh project item-add $PROJECT_NUMBER --owner $OWNER --url $ISSUE_URL --format json | jq -r '.id')
gh project item-edit --project-id $PROJECT_ID --id $ITEM_ID --field-id $ESTIMATE_FIELD --number $FEATURE_POINTS
```

### Step 4.4: Batch Add Features with Estimates

For multiple features, use a data structure to map issue numbers to estimates:

```bash
PROJECT_NUMBER={project_number}
OWNER={owner}
REPO="{owner}/{repo}"
PROJECT_ID="{project_id}"
ESTIMATE_FIELD="{estimate_field_id}"

# Define features with estimates: "issue_number:points"
# Example from Phase 1: organization features
FEATURES="63:3 64:3 65:5 66:2 67:3"

for feature in $FEATURES; do
  FEATURE_NUM=$(echo $feature | cut -d: -f1)
  POINTS=$(echo $feature | cut -d: -f2)

  ISSUE_URL="https://github.com/$REPO/issues/$FEATURE_NUM"
  ITEM_ID=$(gh project item-add $PROJECT_NUMBER --owner $OWNER --url $ISSUE_URL --format json | jq -r '.id')
  gh project item-edit --project-id $PROJECT_ID --id $ITEM_ID --field-id $ESTIMATE_FIELD --number $POINTS
  echo "Added #$FEATURE_NUM with estimate: $POINTS points"
done
```

### Step 4.5: Verify Estimates Were Set

```bash
# Check all items have estimates
gh project item-list $PROJECT_NUMBER --owner $OWNER --format json | \
  jq -r '.items[] | "\(.content.number): \(.estimate // "NOT SET")"'
```

## Phase 5: Create Local Tracker

Create `.github-workflow-tracker.md`:

```markdown
# Product Roadmap Tracker

## Project Info
| Field           | Value         |
| --------------- | ------------- |
| **Project URL** | {PROJECT_URL} |
| **Repository**  | {REPO}        |
| **Created**     | {TIMESTAMP}   |

## GitHub Project IDs
These IDs are needed for `gh project item-edit` commands:

| Resource           | ID                  |
| ------------------ | ------------------- |
| **Project ID**     | {PROJECT_ID}        |
| **Estimate Field** | {ESTIMATE_FIELD_ID} |
| **Status Field**   | {STATUS_FIELD_ID}   |
| **Size Field**     | {SIZE_FIELD_ID}     |

## Phases (Epics)

### Phase 1: {NAME}
- **Epic:** [#{number}]({url})
- **Item ID:** {ITEM_ID}
- **Goal:** {goal}
- **Features:** {count}
- **Total Points:** {sum}

### Phase 2: {NAME}
...

## All Issues
| #    | Title          | Phase | Est   | Item ID   | Status |
| ---- | -------------- | ----- | ----- | --------- | ------ |
| #{n} | [Epic] Phase 1 | -     | -     | {ITEM_ID} | Open   |
| #{n} | {Feature}      | 1     | {pts} | {ITEM_ID} | Open   |
...

## Session Log
### {DATE}
- Created product documentation in .agent-os/product/
- Created {N} phase epics
- Created {M} feature issues
- Added all to GitHub Project with Item IDs recorded above
```

**Tip:** To get Item IDs for existing issues:

```bash
gh project item-list {project_number} --owner {owner} --format json | \
  jq -r '.items[] | "\(.content.number): \(.id)"'
```

</workflow>

<output_summary>
After completion, report:

## Files Created

- `.agent-os/product/mission.md`
- `.agent-os/product/mission-lite.md`
- `.agent-os/product/tech-stack.md`
- `.agent-os/product/roadmap.md`
- `.agent-os/product/decisions.md`
- `.github-workflow-tracker.md`

## GitHub Issues Created

- **Epics:** {N} phase epics
- **Features:** {M} feature issues
- **Total Points:** {SUM}

## Project Roadmap

All issues added to: {PROJECT_URL}

View roadmap: {PROJECT_URL}?layout=roadmap
</output_summary>

<phase_guidelines>
When decomposing features into phases:

- **Phase 1:** Core MVP - minimum viable functionality
- **Phase 2:** Key differentiators - competitive advantages
- **Phase 3:** Scale and polish - performance, UX refinement
- **Phase 4:** Advanced features - power user capabilities
- **Phase 5:** Enterprise features - team/org functionality
</phase_guidelines>

<rules>
- Create 1-3 phases initially (more can be added later)
- Each phase should have 3-7 features
- Features should be small enough for single PRs
- Use Fibonacci for estimates (1, 2, 3, 5, 8, 13)
- Link all features to their parent Epic
- Set iteration field to match phase (if available)
</rules>
