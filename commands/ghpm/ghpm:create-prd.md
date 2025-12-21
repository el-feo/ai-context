---
description: Create a PRD GitHub issue (labeled PRD) from user input and optionally add it to a GitHub Project
argument-hint: <product idea or feature description>
allowed-tools: [Read, Bash, Grep, AskUserQuestion]
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

**Detailed input (skips clarification):**

```
/ghpm:create-prd Build a user authentication system with email/password and OAuth support for enterprise customers who need SSO to reduce IT friction during onboarding
```

→ Detailed input (30+ words, has who/what/why) → Proceeds directly to PRD generation

**Vague input (triggers clarification):**

```
/ghpm:create-prd Add a dashboard
```

→ Vague input (4 words, missing who/why/scope) → Presents clarifying questions:
1. Who is the primary user? (Internal team, Customers, Admins, Developers)
2. What problem does this solve? (Efficiency, Missing capability, UX, Compliance)
3. What's the scope? (MVP, Feature complete, Production-ready, Enterprise-grade)

After user responds → Generates PRD with enriched context

**Complex feature (typically detailed enough):**

```
/ghpm:create-prd Add real-time collaboration features to the document editor, similar to Google Docs, so remote teams can co-edit documents without version conflicts
```

→ Detailed input → Proceeds directly to PRD generation

**With project association:**

```bash
export GHPM_PROJECT="MyOrg/Q1 Roadmap"
/ghpm:create-prd Implement dark mode across the application for users with visual sensitivities to reduce eye strain
```

</usage_examples>

<operating_rules>

- **For vague input:** Use `AskUserQuestion` tool to gather context before generating the PRD. See `<vagueness_detection>` for criteria.
- **For detailed input:** Proceed directly to PRD generation. Make reasonable assumptions and explicitly record them under **Assumptions** and **Open Questions**.
- Do not create or persist local markdown artifacts (no local PRD files). All artifacts must live in GitHub issue bodies/comments.
- Use Markdown in the issue body. Make the PRD self-contained.
- Keep scope crisp; if the request is broad, define a "V1" and park the rest in **Out of Scope** / **Future Ideas**.
- Clarification should be quick (max 4 questions) - do not interrogate the user.
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

<clarification_questions>

## Clarifying Questions

When vague input is detected, use the `AskUserQuestion` tool to gather context. Select 2-4 questions based on what's missing from the input.

### Question Templates

**Q1: Target Users** (use when 'who' is missing)
```json
{
  "question": "Who is the primary user of this feature?",
  "header": "Users",
  "multiSelect": false,
  "options": [
    {"label": "End users/customers", "description": "People using the product directly"},
    {"label": "Internal team members", "description": "Employees within the organization"},
    {"label": "Administrators", "description": "Users who configure or manage the system"},
    {"label": "Developers/API consumers", "description": "Technical users integrating with the system"}
  ]
}
```

**Q2: Problem Being Solved** (use when 'why' is missing)
```json
{
  "question": "What problem does this solve for users?",
  "header": "Problem",
  "multiSelect": false,
  "options": [
    {"label": "Efficiency/speed", "description": "Reduce time or effort to complete tasks"},
    {"label": "Missing capability", "description": "Enable something users currently cannot do"},
    {"label": "User experience", "description": "Improve usability, accessibility, or satisfaction"},
    {"label": "Compliance/security", "description": "Meet regulatory or security requirements"}
  ]
}
```

**Q3: Core Capabilities** (use when 'what' is vague)
```json
{
  "question": "Which capabilities are most important?",
  "header": "Features",
  "multiSelect": true,
  "options": [
    {"label": "View/display data", "description": "Read-only access to information"},
    {"label": "Create/edit content", "description": "CRUD operations on data"},
    {"label": "Automation/workflows", "description": "Automated processes or triggers"},
    {"label": "Reporting/analytics", "description": "Insights, charts, or exports"}
  ]
}
```

**Q4: Technical Constraints** (use when scope is ambiguous)
```json
{
  "question": "Are there specific technical constraints?",
  "header": "Constraints",
  "multiSelect": true,
  "options": [
    {"label": "Must integrate with existing system", "description": "Needs to work with current infrastructure"},
    {"label": "Performance-critical", "description": "High throughput or low latency required"},
    {"label": "Mobile support required", "description": "Must work on mobile devices"},
    {"label": "No constraints", "description": "Greenfield implementation"}
  ]
}
```

**Q5: Scope/Priority** (use when input could mean many things)
```json
{
  "question": "What's the scope for the initial version?",
  "header": "Scope",
  "multiSelect": false,
  "options": [
    {"label": "MVP/proof of concept", "description": "Minimal viable version to validate the idea"},
    {"label": "Feature complete for core use case", "description": "Fully functional for primary scenario"},
    {"label": "Production-ready with edge cases", "description": "Robust handling of all scenarios"},
    {"label": "Enterprise-grade", "description": "Scalability, security, and compliance built-in"}
  ]
}
```

### Selecting Questions

Based on vagueness detection results, select appropriate questions:

| Missing Element | Questions to Ask |
|-----------------|------------------|
| Who (users) | Q1 (Target Users) |
| Why (problem) | Q2 (Problem Being Solved) |
| What (features) | Q3 (Core Capabilities) |
| Scope unclear | Q4 (Technical Constraints), Q5 (Scope/Priority) |
| Multiple missing | Combine up to 4 questions maximum |

### Incorporating Responses

After receiving user responses, append them to the original input before generating the PRD:

```
Original input: "I want a dashboard"

Enriched context from clarification:
- Target users: Internal team members
- Problem: Efficiency/speed - reduce time to complete tasks
- Capabilities: Reporting/analytics, View/display data
- Scope: Feature complete for core use case

Generate PRD using both original input AND enriched context.
```

</clarification_questions>

<workflow>
## Step 1: Validate Environment

Run input validation checks from previous section.

## Step 2: Determine Repository

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

## Step 3: Evaluate Input & Clarify (if needed)

Evaluate user input against the vagueness criteria in `<vagueness_detection>`.

**If input is sufficiently detailed (0-1 criteria triggered):**
- Skip to Step 4 (Draft PRD Content)

**If input is vague (2+ criteria triggered):**

1. Identify which elements are missing (who, what, why, scope)
2. Select appropriate questions from `<clarification_questions>` (max 4)
3. Use `AskUserQuestion` tool to present questions:

```
Use the AskUserQuestion tool with the selected question templates.
Wait for user responses before proceeding.
```

4. Combine original input with user responses to form enriched context
5. Proceed to Step 4 with enriched context

**Example clarification flow:**

Input: "I want a dashboard"

Vagueness analysis:
- ✗ Too short (4 words < 20)
- ✗ Missing 'who' (no user mentioned)
- ✗ Missing 'why' (no problem stated)
- ✓ Has 'what' (dashboard is a feature)
- ✗ Ambiguous scope (dashboard could mean many things)

→ 4 criteria triggered → Ask Q1 (Users), Q2 (Problem), Q5 (Scope)

## Step 4: Draft PRD Content

Based on user input ($ARGUMENTS) and any enriched context from clarification, generate comprehensive PRD following the structure template.

## Step 5: Create GitHub Issue

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

## Step 6: Add to GitHub Project (Optional)

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
