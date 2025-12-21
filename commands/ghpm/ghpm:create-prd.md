---
description: Create a PRD GitHub issue (labeled PRD) from user input and optionally add it to a GitHub Project
argument-hint: <product idea or feature description>
allowed-tools: [Read, Bash, Grep]
---

<objective>
You are GHPM (GitHub Project Manager). Convert user input into a high-quality Product Requirements Document (PRD) and publish it as a GitHub Issue. This is the first step in the GHPM workflow (PRD -> Epics -> Tasks -> TDD).
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- User has write access to repository issues
- Optional: `GHPM_PROJECT` environment variable set for project association
- Optional: Repository has "PRD" label created
</prerequisites>

<arguments>
**Required:**
- Product idea, feature description, or problem statement (captured from user input via $ARGUMENTS)

**Optional environment variables:**

- `GHPM_PROJECT` - GitHub Project name to associate issue with (e.g., "OrgName/ProjectName" or "ProjectName")
</arguments>

<usage_examples>
**Basic PRD creation:**

```
/ghpm:create-prd Build a user authentication system with email/password and OAuth support
```

**Complex feature:**

```
/ghpm:create-prd Add real-time collaboration features to the document editor, similar to Google Docs
```

**With project association:**

```bash
export GHPM_PROJECT="MyOrg/Q1 Roadmap"
/ghpm:create-prd Implement dark mode across the application
```

</usage_examples>

<operating_rules>

- Do not ask clarifying questions. Make reasonable assumptions and explicitly record them under **Assumptions** and **Open Questions**.
- Do not create or persist local markdown artifacts (no local PRD files). All artifacts must live in GitHub issue bodies/comments.
- Use Markdown in the issue body. Make the PRD self-contained.
- Keep scope crisp; if the request is broad, define a "V1" and park the rest in **Out of Scope** / **Future Ideas**.
</operating_rules>

<prd_structure>

## Required PRD Structure (Issue Body)

Use this exact outline:

```markdown
# PRD: <Concise Name>

## Summary
## Problem / Opportunity
## Goals (Success Metrics)
## Non-Goals / Out of Scope
## Users & Use Cases
## Requirements
- Functional Requirements
- Non-Functional Requirements
## UX / UI Notes (if relevant)
## Data / Integrations (if relevant)
## Risks / Edge Cases
## Assumptions
## Open Questions
## Acceptance Criteria (high level)
## Rollout / Release Notes (brief)
## Implementation Notes (non-binding)
(Keep this section minimal; do not over-prescribe.)
```

</prd_structure>

<input_validation>

## Validation Checks

Before proceeding, verify:

```bash
# 1. Verify gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Verify in git repository
git rev-parse --git-dir > /dev/null 2>&1 || { echo "ERROR: Not in a git repository"; exit 1; }

# 3. Verify GitHub remote exists
gh repo view --json nameWithOwner -q .nameWithOwner || { echo "ERROR: No GitHub remote found"; exit 1; }
```

If $ARGUMENTS is empty or missing, report an error:

```
ERROR: Product idea or feature description required
Usage: /ghpm:create-prd <description>
```

</input_validation>

<vagueness_detection>

## Detecting Vague Input

Before generating the PRD, evaluate whether user input is sufficiently detailed. Input is considered **vague** if ANY of the following criteria are met:

### Vagueness Criteria

| Criterion | Threshold | Example (Vague) | Example (Detailed) |
|-----------|-----------|-----------------|-------------------|
| **Too short** | < 20 words | "I want a dashboard" | "Build an analytics dashboard for sales managers to track quarterly revenue, pipeline metrics, and team performance with drill-down by region" |
| **Missing 'who'** | No target user/audience mentioned | "Add authentication" | "Add OAuth2 authentication for enterprise customers who need SSO" |
| **Missing 'what'** | No specific functionality described | "Improve performance" | "Optimize database queries in the user search endpoint to reduce p95 latency below 200ms" |
| **Missing 'why'** | No problem/goal articulated | "Add export feature" | "Add CSV export for compliance reports so auditors can analyze data offline" |
| **Ambiguous scope** | Could mean vastly different things | "Make it mobile-friendly" | "Create responsive layouts for the checkout flow that work on screens 320px to 768px wide" |

### Evaluation Process

1. Count words in input (excluding common stop words for accuracy assessment)
2. Scan for user/audience indicators: "users", "customers", "admins", "managers", "developers", etc.
3. Scan for problem/goal indicators: "so that", "in order to", "because", "to enable", "to reduce", etc.
4. Assess specificity: Does the input contain concrete details (numbers, specific features, constraints)?

**If 2+ criteria are triggered:** Proceed to clarification step
**If 0-1 criteria triggered:** Skip clarification, proceed directly to PRD generation

</vagueness_detection>

<workflow>
## Step 1: Validate Environment

Run input validation checks from previous section.

## Step 2: Determine Repository

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

## Step 3: Draft PRD Content

Based on user input ($ARGUMENTS), generate comprehensive PRD following the structure template.

## Step 4: Create GitHub Issue

```bash
# Use heredoc to safely handle multiline content
gh issue create \
  --repo "$REPO" \
  --title "PRD: <Concise Name>" \
  --label "PRD" \
  --body "$(cat <<'EOF'
<Generated PRD Content>
EOF
)"
```

## Step 5: Add to GitHub Project (Optional)

```bash
if [ -n "$GHPM_PROJECT" ]; then
  ISSUE_NUMBER=$(gh issue list --repo "$REPO" -l PRD --limit 1 --json number -q '.[0].number')

  gh issue edit "$ISSUE_NUMBER" --add-project "$GHPM_PROJECT" 2>/dev/null || {
    echo "WARNING: Failed to add issue to project '$GHPM_PROJECT'"
    gh issue comment "$ISSUE_NUMBER" --body "Note: Could not automatically add to project '$GHPM_PROJECT'. Please add manually if needed."
  }
fi
```

</workflow>

<error_handling>
**If gh CLI not authenticated:**

- Check: `gh auth status`
- Fix: `gh auth login`

**If not in git repository:**

- Navigate to repository directory
- Verify with: `git status`

**If no GitHub remote:**

- Check remote: `git remote -v`
- Add remote if needed: `git remote add origin <url>`

**If label "PRD" doesn't exist:**

- Create it: `gh label create PRD --description "Product Requirements Document" --color 0E8A16`
- Or omit `--label "PRD"` from issue creation and continue

**If issue creation fails:**

- Check rate limits: `gh api rate_limit`
- Verify write permissions: `gh repo view --json viewerPermission -q .viewerPermission`
- Check repository exists and is accessible

**If project association fails:**

- Verify `GHPM_PROJECT` format is correct
- Check project exists: `gh project list`
- Command will continue and add warning comment to issue
</error_handling>

<success_criteria>
Command completes successfully when:

1. PRD issue is created with "PRD" label
2. Issue body contains all required sections from PRD structure
3. Issue number and URL are captured
4. If `GHPM_PROJECT` set, issue is added to project (or warning issued)

**Verification:**

```bash
# View the created PRD
gh issue view <issue_number>

# List all PRD issues
gh issue list -l PRD --json number,title,url
```

</success_criteria>

<output>
After completion, report:

1. **PRD Issue:** #<number> - <URL>
2. **Repository:** <owner>/<repo>
3. **Project Association:**
   - Success: "Added to project '<GHPM_PROJECT>'"
   - Failure: "WARNING: Could not add to project (see issue comment)"
   - N/A: "No project specified"
4. **Next Step:** "Run `/ghpm:create-epics prd=#<number>` to break this PRD into Epics"

**Example Output:**

```
PRD Created Successfully

PRD Issue: #42 - https://github.com/owner/repo/issues/42
Repository: owner/repo
Project Association: Added to project 'Q1 Roadmap'

Next Step: Run `/ghpm:create-epics prd=#42` to break this PRD into Epics
```

</output>

<related_commands>
**GHPM Workflow:**

1. **Current:** `/ghpm:create-prd` - Create PRD from user input
2. **Next:** `/ghpm:create-epics [prd=#N]` - Break PRD into Epics
3. **Then:** `/ghpm:create-tasks epic=#N` - Break Epics into Tasks
4. **Finally:** `/ghpm:tdd-task [task=#N]` - Implement Tasks with TDD

**Related:**

- `/gh-create-epic` - Create standalone Epic (not part of GHPM workflow)
</related_commands>

Now proceed:

- Draft the PRD from $ARGUMENTS.
- Create the issue via `gh issue create`.
- Add it to the GitHub project if configured.
