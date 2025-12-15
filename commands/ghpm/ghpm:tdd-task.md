---
description: Execute a Task using a TDD loop; record decisions/progress on the issue; open a PR that closes the Task.
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob, Skill(ruby), Skill(javascript), Skill(rspec), Skill(javascript-unit-testing), Skill(rubycritic), Skill(simplecov)]
---

<objective>
Implement a GitHub Task issue using disciplined TDD (Red -> Green -> Refactor), recording all decisions and progress on the GitHub issue, then opening a PR that closes the Task.
</objective>

<arguments>
**Optional arguments:**
- `task=#123` - Specific task issue number
- `focus=unit|integration|e2e` - Best-effort hint for test focus

**Resolution order if omitted:**

1. If branch name matches `ghpm/task-<N>-*` or `task-<N>-*`, use N
2. Most recent open issue labeled `Task` assigned to @me:
   `gh issue list -l Task -a @me -s open --limit 1 --json number -q '.[0].number'`
3. Most recent open Task:
   `gh issue list -l Task -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**With task number:**

```bash
/ghpm:tdd-task task=#42
```

**With focus hint:**

```bash
/ghpm:tdd-task task=#42 focus=unit
```

**Auto-resolve from branch:**

```bash
# On branch: ghpm/task-42-add-auth
/ghpm:tdd-task
```

**Auto-resolve from GitHub:**

```bash
# No arguments - uses most recent assigned Task
/ghpm:tdd-task
```

</usage_examples>

<operating_rules>

- No local markdown artifacts. Do not write local status files; only code changes + GitHub issue/PR updates.
- Do NOT use the TodoWrite tool to track tasks during this session.
- Do not silently expand scope. If you must, create a new follow-up Task issue and link it.
- Always provide a runnable test command in the final notes.
- Minimize noise: comment at meaningful milestones.
</operating_rules>

<workflow>

## Step 0: Hydrate context

Resolve the task number and fetch context:

```bash
# Resolve task number from arguments, branch, or auto-select
TASK={resolved_task_number}

# Fetch issue details
gh issue view "$TASK" --json title,body,url,labels,comments -q '.'
```

**Extract from issue:**

- Acceptance criteria
- Test plan (or infer if missing)
- Epic/PRD links

## Step 1: Post a TDD Plan comment

Comment on the Task with your implementation plan:

```markdown
## TDD Plan

- **Objective:**
- **Target behavior / acceptance criteria:**
- **Test strategy (focus level + what to cover):**
- **Proposed minimal design (non-binding):**
- **Commands (build/test/lint) you will run:**
- **Milestones (Red/Green/Refactor slices):**
```

Execute:

```bash
gh issue comment "$TASK" --body "<markdown>"
```

## Step 2: Create a working branch

```bash
git checkout -b "ghpm/task-$TASK-<short-slug>"
```

Comment branch name to the issue (same comment or a follow-up).

## Step 3: TDD execution loop

For each slice:

1. **RED:** Add failing test(s)
2. **GREEN:** Implement minimum change to pass
3. **REFACTOR:** Clean up while tests stay green
4. Run tests and capture command + result

After each slice, comment on the Task with:

- What changed
- Tests added/updated
- Test command executed + result
- Any decision/rationale

## Step 4: Update the Task body with a "Task Report" section

Edit the issue body to append:

```markdown
## Task Report (auto)

### Implementation summary

### Files changed

### How to validate locally

### Test command(s) and results

### Decision log

### Follow-ups (if any)
```

Execute:

```bash
gh issue edit "$TASK" --body "<updated markdown>"
```

## Step 5: Open a PR that closes the Task

Push branch and create PR:

```bash
git push -u origin HEAD

gh pr create --title "Task #$TASK: <short title>" --body "$(cat <<'EOF'
Closes #$TASK

## Summary

- ...

## Test Plan

- `<test command>`
EOF
)"
```

Comment the PR URL back onto the Task:

```bash
gh issue comment "$TASK" --body "PR created: <PR_URL>"
```

## Step 6: Final checkpoint

- Ensure all tests pass
- Ensure Task Report is updated in issue body
- Ensure PR references and closes the Task

</workflow>

<success_criteria>
Command completes when:

- All tests pass
- Task Report section is updated in the issue body
- PR is created with `Closes #$TASK` in the body
- PR URL is commented back to the Task
</success_criteria>

<error_handling>
**If tests fail during a cycle:**

- Do not proceed to refactor
- Comment on issue with failure details
- Debug and fix before continuing

**If PR creation fails:**

- Ensure branch is pushed
- Check repository permissions
- Verify issue number exists
- Comment failure details on Task issue
</error_handling>

Proceed now.
