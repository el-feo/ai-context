---
description: Create a new GitHub Project from template (or blank) and link it to the current repository
argument-hint: [project title]
allowed-tools: [Read, Bash, Grep, AskUserQuestion]
---

<objective>
You are GHPM (GitHub Project Manager). Create a new GitHub Project, optionally from a template, and link it to the current repository. This command helps bootstrap project management for repositories that don't yet have an associated project.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- User has permission to create projects for the repository owner
- Token has `project` scope (`gh auth refresh -s project` if needed)
- Optional: A template project marked with `gh project mark-template`
</prerequisites>

<arguments>
**Optional:**
- Project title (captured from $ARGUMENTS). If not provided, user will be prompted.

**Optional environment variables:**

- `GHPM_TEMPLATE_PROJECT` - Project number to use as template (e.g., "7")
- `GHPM_TEMPLATE_OWNER` - Owner of the template project (defaults to current repo owner)
</arguments>

<usage_examples>

**With title argument:**

```
/ghpm:create-project Q1 Roadmap
```

→ Creates project titled "Q1 Roadmap", links to current repo

**Without title (prompts):**

```
/ghpm:create-project
```

→ Prompts: "What should the project be called?" → Creates and links project

**With template pre-configured:**

```bash
export GHPM_TEMPLATE_PROJECT="7"
/ghpm:create-project Feature Development
```

→ Copies from template project #7, links to current repo

</usage_examples>

<operating_rules>

- Always prompt for project title if not provided via $ARGUMENTS
- Check for template projects before creating blank project
- Link the project to the current repository after creation
- Set `GHPM_PROJECT` to the new project title for use in subsequent commands
- Report the project URL so user can configure views manually if needed

</operating_rules>

<input_validation>

## Validation Checks

Before proceeding, verify:

```bash
# 1. Verify gh CLI authentication
gh auth status || { echo "ERROR: Not authenticated. Run 'gh auth login'"; exit 1; }

# 2. Verify project scope
gh auth status 2>&1 | grep -q "project" || echo "WARNING: Token may not have 'project' scope. Run 'gh auth refresh -s project' if project creation fails."

# 3. Verify in git repository
git rev-parse --git-dir > /dev/null 2>&1 || { echo "ERROR: Not in a git repository"; exit 1; }

# 4. Verify GitHub remote exists
gh repo view --json nameWithOwner -q .nameWithOwner || { echo "ERROR: No GitHub remote found"; exit 1; }
```

</input_validation>

<workflow>

## Step 1: Validate Environment

Run input validation checks from previous section.

## Step 2: Determine Repository and Owner

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=$(gh repo view --json owner -q .owner.login)
```

## Step 3: Get Project Title

**If $ARGUMENTS contains a title:** Use it directly.

```bash
TITLE="$ARGUMENTS"
```

**If $ARGUMENTS is empty:** Use `AskUserQuestion` to prompt for the title.

```json
{
  "question": "What should the new GitHub Project be called?",
  "header": "Title",
  "multiSelect": false,
  "options": [
    {"label": "Roadmap", "description": "General product roadmap"},
    {"label": "Sprint Board", "description": "Agile sprint tracking"},
    {"label": "Feature Development", "description": "Feature work tracking"}
  ]
}
```

- If user selects an option, use that as `TITLE`
- If user selects "Other" and provides custom text, use that as `TITLE`

## Step 4: Check for Template Project

**If `GHPM_TEMPLATE_PROJECT` is set:**

```bash
TEMPLATE_OWNER="${GHPM_TEMPLATE_OWNER:-$OWNER}"
TEMPLATE_NUMBER="$GHPM_TEMPLATE_PROJECT"

# Verify template exists
gh project view "$TEMPLATE_NUMBER" --owner "$TEMPLATE_OWNER" --format json > /dev/null 2>&1
```

**If not set:** Check if owner has any template projects available:

```bash
# Query for template projects
TEMPLATES=$(gh api graphql -f query="
{
  user(login: \"$OWNER\") {
    projectsV2(first: 10) {
      nodes {
        number
        title
        template
      }
    }
  }
}" --jq '.data.user.projectsV2.nodes | map(select(.template == true))')

# For organizations, use:
# gh api graphql -f query="{ organization(login: \"$OWNER\") { ... } }"
```

**If templates found:** Use `AskUserQuestion` to let user choose:

```json
{
  "question": "Would you like to create from a template project?",
  "header": "Template",
  "multiSelect": false,
  "options": [
    {"label": "<Template Name 1>", "description": "Project #<number> - includes pre-configured views"},
    {"label": "<Template Name 2>", "description": "Project #<number> - includes pre-configured views"},
    {"label": "Blank project", "description": "Start fresh with default Table view only"}
  ]
}
```

## Step 5: Create the Project

**Option A: Copy from template**

```bash
PROJECT_DATA=$(gh project copy "$TEMPLATE_NUMBER" \
  --source-owner "$TEMPLATE_OWNER" \
  --target-owner "$OWNER" \
  --title "$TITLE" \
  --format json)

PROJECT_NUMBER=$(echo "$PROJECT_DATA" | jq -r '.number')
PROJECT_URL=$(echo "$PROJECT_DATA" | jq -r '.url')
```

**Option B: Create blank project**

```bash
PROJECT_DATA=$(gh project create \
  --owner "$OWNER" \
  --title "$TITLE" \
  --format json)

PROJECT_NUMBER=$(echo "$PROJECT_DATA" | jq -r '.number')
PROJECT_URL=$(echo "$PROJECT_DATA" | jq -r '.url')
```

## Step 6: Link Project to Repository

```bash
gh project link "$PROJECT_NUMBER" --owner "$OWNER" --repo "$REPO"
```

## Step 7: Set GHPM_PROJECT Variable

Report the command to set the environment variable:

```bash
export GHPM_PROJECT="$TITLE"
```

</workflow>

<error_handling>

**If gh CLI not authenticated:**

- Check: `gh auth status`
- Fix: `gh auth login`

**If missing project scope:**

- Check: `gh auth status` (look for "project" in scopes)
- Fix: `gh auth refresh -s project`

**If template project not found:**

- Verify template number: `gh project view <number> --owner <owner>`
- Fall back to creating blank project

**If project creation fails:**

- Check rate limits: `gh api rate_limit`
- Verify owner permissions
- Check if project with same name already exists

**If linking fails:**

- Verify repository exists: `gh repo view`
- Project may already be linked (not an error)

</error_handling>

<success_criteria>

Command completes successfully when:

1. Project is created (from template or blank)
2. Project is linked to current repository
3. Project number and URL are captured
4. User is informed how to set `GHPM_PROJECT`

**Verification:**

```bash
# View the created project
gh project view <project_number> --owner <owner>

# Verify link to repository
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    projectsV2(first: 5) {
      nodes { title number }
    }
  }
}'
```

</success_criteria>

<output>

After completion, report:

1. **Project Created:** "<TITLE>" (#<number>)
2. **URL:** <project_url>
3. **Repository:** <owner>/<repo>
4. **Created From:** "Template: <template_name>" or "Blank project"
5. **Linked:** Yes/No

**Example Output:**

```
Project Created Successfully

Project: "Q1 Roadmap" (#8)
URL: https://github.com/users/el-feo/projects/8
Repository: el-feo/ai-context
Created From: Template "GHPM Template" (#7)
Linked: Yes

To use this project with GHPM commands, run:
  export GHPM_PROJECT="Q1 Roadmap"

Or add to your shell profile for persistence.

Next Steps:
- Configure views in the project UI if needed: <project_url>
- Run `/ghpm:create-prd <description>` to create your first PRD
```

**If created from blank project, add:**

```
Note: This project was created without a template.
Visit the project URL to add custom views (Board, Roadmap, etc.)
```

</output>

<template_setup>

## Creating a Template Project (One-Time Setup)

To enable the "copy from template" feature, create a template project:

1. **Create a project manually** with your desired configuration:
   - Add views (Board, Table, Roadmap)
   - Configure fields (Status, Priority, Sprint, etc.)
   - Set up filters and groupings

2. **Mark it as a template:**

   ```bash
   gh project mark-template <project_number> --owner <owner>
   ```

3. **Optionally set as default template:**

   ```bash
   export GHPM_TEMPLATE_PROJECT="<project_number>"
   export GHPM_TEMPLATE_OWNER="<owner>"
   ```

**Recommended Template Configuration:**

- **Views:**
  - Table (default) - All items
  - Board - Grouped by Status
  - Roadmap - Timeline view

- **Fields:**
  - Status: Todo, In Progress, In Review, Done
  - Priority: High, Medium, Low
  - Type: PRD, Epic, Task
  - Sprint/Iteration (optional)

</template_setup>

<related_commands>

**GHPM Workflow:**

1. **Current:** `/ghpm:create-project` - Create and link a GitHub Project
2. **Next:** `/ghpm:create-prd <description>` - Create PRD in the project
3. **Then:** `/ghpm:create-epics prd=#N` - Break PRD into Epics
4. **Then:** `/ghpm:create-tasks epic=#N` - Break Epics into Tasks
5. **Finally:** `/ghpm:tdd-task task=#N` - Implement Tasks with TDD

</related_commands>

Now proceed:

1. Validate environment prerequisites.
2. Determine repository and owner.
3. Get project title from $ARGUMENTS or prompt user.
4. Check for available template projects.
5. If templates available, ask user to choose template or blank.
6. Create the project (copy from template or create blank).
7. Link the project to the current repository.
8. Report success and next steps.
