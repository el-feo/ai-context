---
description: Break a PRD issue into Epic issues and link them back to the PRD.
argument-hint: prd=#123
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  prd:
    description: "PRD issue number (format: prd=#123)"
    required: false
---

<objective>
You are GHPM (GitHub Project Manager). Break a PRD into Epics and publish each Epic as a GitHub Issue. Each Epic is linked as a sub-issue of the PRD. This is the second step in the GHPM workflow (PRD -> Epics -> Tasks -> TDD).
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- User has write access to repository issues
- PRD issue exists with label "PRD"
- Optional: `GHPM_PROJECT` environment variable set for project association
- Optional: Repository has "Epic" label created
</prerequisites>

<arguments>
**Optional:**
- `prd=#123` - PRD issue number to break into Epics

**Resolution order if omitted:**

1. Most recent open issue labeled `PRD`

**Optional environment variables:**

- `GHPM_PROJECT` - GitHub Project name to associate Epics with (e.g., "OrgName/ProjectName" or "ProjectName")
</arguments>

<usage_examples>
**With PRD number:**

```
/ghpm:create-epics prd=#42
```

**Auto-resolve most recent PRD:**

```
/ghpm:create-epics
```

**With project association:**

```bash
export GHPM_PROJECT="MyOrg/Q1 Roadmap"
/ghpm:create-epics prd=#42
```

</usage_examples>

<operating_rules>

- Do not ask clarifying questions. If the PRD has ambiguity, encode it as assumptions within each Epic and/or add open questions.
- Do not create local markdown files. All output goes into GitHub issues/comments.
- Each Epic issue must be self-contained for its scope and must reference the PRD by number/link.
- Epics should collectively cover the entire PRD scope without gaps or overlaps.

### Epic Count Guidelines

**Default to 1 Epic.** Only create multiple Epics when the PRD contains truly independent work streams that could be implemented by different people without coordination.

| PRD Type | Epic Count | Justification Required |
|----------|------------|------------------------|
| Minimal (docs, config, single-file) | 1 | N/A |
| Small (single feature) | 1 | N/A |
| Medium (2-3 independent features) | 2-3 | Each Epic must deliver independent value |
| Large (platform/system) | 3-5 | Each Epic must be separable work stream |

**Decision questions before creating multiple Epics:**
1. Would each Epic deliver independent, usable value if the others were never implemented?
2. Could different developers implement each Epic without needing to coordinate on shared code?
3. Is there a natural break point where work could pause between Epics?

If the answer to any question is "no", consolidate into fewer Epics.

### Anti-patterns (DO NOT create separate Epics for these)

- **"Infrastructure" vs "Integration"**: If the infrastructure is just code embedded in the integration, it's one Epic
- **"Implementation" vs "Documentation"**: Docs are part of completing a feature, not a separate Epic
- **"Backend" vs "Frontend"**: If the feature requires both to be useful, it's one Epic
- **"Core" vs "Extensions"**: If extensions depend entirely on core, it's one Epic
- **Per-file Epics**: Creating Epics for each file touched rather than for outcomes

### Example: Single-Feature PRD → 1 Epic

PRD: "Add issue claiming workflow to execute, tdd-task, and qa-execute commands"

❌ **Wrong (3 Epics):**
1. Epic: Core Claiming Infrastructure
2. Epic: Command Integration
3. Epic: Documentation

❌ **Why it's wrong:** The "infrastructure" is just a bash function embedded in commands. Documentation is part of completing the feature. All three are tightly coupled.

✅ **Correct (1 Epic):**
1. Epic: Issue Claiming Workflow

</operating_rules>

<epic_issue_format>

## Required Epic Structure (Issue Body)

Use this streamlined template. Omit optional sections if empty.

```markdown
# Epic: <Name>

**PRD:** #<PRD_NUMBER>

## Objective
<1-3 sentences: what this Epic accomplishes and delivers>

## Scope
<Bulleted list of specific deliverables - merge any "Key Requirements" here>

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Dependencies
<Only include if external dependencies exist; omit section entirely if none>
```

### Template Guidance

- **PRD link**: Single line at top, not a separate "Links" section
- **Objective**: Concise statement of what this Epic delivers (not duplicating PRD content)
- **Scope**: Specific deliverables; merge "Key Requirements" here rather than separate section
- **Acceptance Criteria**: Checkboxes for Epic-level verification
- **Dependencies**: Only include if there are actual dependencies; omit if none

**Omit these sections** (redundant with PRD or rarely populated):
- Out of Scope (inherit from PRD)
- Risks / Edge Cases (inherit from PRD)
- Notes / Open Questions (use issue comments instead)
- Key Requirements (merge into Scope)

</epic_issue_format>

<input_validation>

## Validation Checks

Before proceeding, verify:

```bash
# 1. Verify gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Verify in git repository
git rev-parse --git-dir > /dev/null 2>&1 || { echo "ERROR: Not in a git repository"; exit 1; }

# 3. Verify GitHub remote exists and get repo info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || { echo "ERROR: No GitHub remote found"; exit 1; }

# 4. Get owner and repo for API calls
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO_NAME=$(gh repo view --json name -q '.name')
```

</input_validation>

<workflow>

## Step 1: Validate Environment

Run input validation checks from previous section.

## Step 2: Resolve PRD Number

```bash
# If prd=#N provided, extract N
if [[ "$ARGUMENTS" =~ prd=#([0-9]+) ]]; then
  PRD="${BASH_REMATCH[1]}"
else
  # Find most recent open PRD
  PRD=$(gh issue list -l PRD -s open --limit 1 --json number -q '.[0].number')
  if [ -z "$PRD" ]; then
    echo "ERROR: No open PRD issues found. Create one with /ghpm:create-prd"
    exit 1
  fi
fi

echo "Using PRD #$PRD"
```

## Step 3: Fetch PRD Content

```bash
# Verify PRD exists and get content
PRD_DATA=$(gh issue view "$PRD" --json title,body,url,number)
if [ -z "$PRD_DATA" ]; then
  echo "ERROR: PRD #$PRD not found"
  exit 1
fi

PRD_TITLE=$(echo "$PRD_DATA" | jq -r '.title')
PRD_BODY=$(echo "$PRD_DATA" | jq -r '.body')
PRD_URL=$(echo "$PRD_DATA" | jq -r '.url')

echo "PRD: $PRD_TITLE"
echo "URL: $PRD_URL"
```

## Step 4: Generate Epics

Analyze the PRD scope and generate the minimum number of Epics needed. For narrow-scope PRDs (documentation updates, configuration changes, single-file modifications), a single Epic is often sufficient. Each Epic should:

- Cover a distinct, cohesive area of functionality
- Be independently implementable (with dependencies noted)
- Reference the PRD by number
- Represent meaningful, separable work (not artificial subdivisions)

## Step 5: Create Epic Issues

```bash
# For each Epic, create an issue
gh issue create \
  --repo "$REPO" \
  --title "Epic: <Name>" \
  --label "Epic" \
  --body "$(cat <<'EOF'
<Generated Epic Content>
EOF
)"

# Capture issue number from output
EPIC_NUM=<captured from gh issue create output>
EPIC_URL=<captured from gh issue create output>

# Track created Epics
CREATED_EPICS+=("$EPIC_NUM|Epic: <Name>|$EPIC_URL")
```

## Step 6: Add to GitHub Project (Optional)

```bash
if [ -n "$GHPM_PROJECT" ]; then
  gh issue edit "$EPIC_NUM" --add-project "$GHPM_PROJECT" 2>/dev/null || {
    echo "WARNING: Failed to add Epic #$EPIC_NUM to project '$GHPM_PROJECT'"
  }
fi
```

## Step 7: Link Epics as Sub-Issues of PRD

```bash
# Get the PRD's internal issue ID
PRD_ID=$(gh api "repos/$OWNER/$REPO_NAME/issues/$PRD" --jq .id)

for epic_info in "${CREATED_EPICS[@]}"; do
  EPIC_NUM=$(echo "$epic_info" | cut -d'|' -f1)

  # Get the Epic's internal issue ID
  EPIC_ID=$(gh api "repos/$OWNER/$REPO_NAME/issues/$EPIC_NUM" --jq .id)

  # Add Epic as sub-issue of PRD
  gh api "repos/$OWNER/$REPO_NAME/issues/$PRD/sub_issues" \
    -X POST \
    -F sub_issue_id="$EPIC_ID" \
    --silent && echo "✓ Linked Epic #$EPIC_NUM as sub-issue of PRD #$PRD" \
    || echo "WARNING: Could not link Epic #$EPIC_NUM as sub-issue"
done
```

## Step 8: Post PRD Comment with Summary

```bash
COMMENT_BODY="## Epics Created

The following Epics have been created from this PRD:

$(for epic_info in "${CREATED_EPICS[@]}"; do
  EPIC_NUM=$(echo "$epic_info" | cut -d'|' -f1)
  EPIC_TITLE=$(echo "$epic_info" | cut -d'|' -f2)
  echo "- #$EPIC_NUM $EPIC_TITLE"
done)

View sub-issues in the PRD's \"Sub-issues\" section.

---
*Generated by GHPM*"

gh issue comment "$PRD" --body "$COMMENT_BODY"
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

**If PRD not found:**

- Verify PRD number: `gh issue view <number>`
- Check PRD label exists: `gh issue list -l PRD`
- Create PRD first: `/ghpm:create-prd <description>`

**If label "Epic" doesn't exist:**

- Create it: `gh label create Epic --description "Epic issue" --color 1D76DB`
- Or omit `--label "Epic"` from issue creation and continue

**If issue creation fails:**

- Check rate limits: `gh api rate_limit`
- Verify write permissions: `gh repo view --json viewerPermission -q .viewerPermission`
- Check repository exists and is accessible

**If sub-issue linking fails:**

- Sub-issues API may not be available for all repositories
- Command continues with warning
- Epics are still created and reference PRD in their body

**If project association fails:**

- Verify `GHPM_PROJECT` format is correct
- Check project exists: `gh project list`
- Command continues with warning
</error_handling>

<success_criteria>
Command completes successfully when:

1. All Epic issues are created with "Epic" label
2. Each Epic body contains required sections: PRD link, Objective, Scope, Acceptance Criteria
3. Each Epic references the PRD at the top of the body
4. All Epics are linked as sub-issues of the PRD (or warnings issued)
5. Summary comment is posted to PRD
6. If `GHPM_PROJECT` set, Epics are added to project (or warnings issued)
7. Optional sections (Dependencies) only included when populated with meaningful content

**Verification:**

```bash
# View created Epics
gh issue list -l Epic --json number,title,url

# Verify sub-issues are linked to PRD
gh api "repos/$OWNER/$REPO_NAME/issues/$PRD/sub_issues" --jq '.[] | "#\(.number) \(.title)"'

# View PRD comments
gh issue view "$PRD" --comments
```

</success_criteria>

<output>
After completion, report:

1. **PRD:** #<number> - <URL>
2. **Epics Created:**
   - #<number> Epic: <Name> - <URL>
   - #<number> Epic: <Name> - <URL>
   - ...
3. **Sub-Issue Linking:**
   - Success count / Total count
   - Any warnings
4. **Project Association:**
   - Success: "Added to project '<GHPM_PROJECT>'"
   - Failure: "WARNING: Could not add to project"
   - N/A: "No project specified"
5. **Next Step:** "Run `/ghpm:create-tasks epic=#<number>` to break an Epic into Tasks"

**Example Output (Minimal PRD - single epic):**

```
Epics Created Successfully

PRD: #42 - https://github.com/owner/repo/issues/42

Epics Created:
- #43 Epic: Update README Documentation - https://github.com/owner/repo/issues/43

Sub-Issue Linking: 1/1 successful
Project Association: No project specified

Next Step: Run `/ghpm:create-tasks epic=#43` to break an Epic into Tasks
```

**Example Output (Large PRD - multiple epics):**

```
Epics Created Successfully

PRD: #42 - https://github.com/owner/repo/issues/42

Epics Created:
- #43 Epic: User Authentication - https://github.com/owner/repo/issues/43
- #44 Epic: Database Schema - https://github.com/owner/repo/issues/44
- #45 Epic: API Endpoints - https://github.com/owner/repo/issues/45
- #46 Epic: Frontend Integration - https://github.com/owner/repo/issues/46
- #47 Epic: Testing & QA - https://github.com/owner/repo/issues/47

Sub-Issue Linking: 5/5 successful
Project Association: Added to project 'Q1 Roadmap'

Next Step: Run `/ghpm:create-tasks epic=#43` to break an Epic into Tasks
```

</output>

<related_commands>
**GHPM Workflow:**

1. **Previous:** `/ghpm:create-prd` - Create PRD from user input
2. **Current:** `/ghpm:create-epics` - Break PRD into Epics
3. **Next:** `/ghpm:create-tasks epic=#N` - Break Epics into Tasks
4. **Finally:** `/ghpm:tdd-task [task=#N]` - Implement Tasks with TDD

**Related:**

- `/ghpm:execute epic=#N` - Execute all tasks in an Epic
- `/ghpm:qa-create` - Create QA issue for testing
</related_commands>

Now proceed:

- Resolve PRD number from $ARGUMENTS or find most recent.
- Fetch PRD content and analyze scope.
- Determine appropriate Epic count based on scope complexity (1 Epic for narrow PRDs, more for larger scope).
- Generate Epics covering the entire PRD without artificial subdivision.
- Create each Epic issue via `gh issue create`.
- Link Epics as sub-issues of the PRD.
- Post summary comment to PRD.
