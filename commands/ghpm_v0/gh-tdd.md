---
description: TDD red-green-refactor cycle with execution agent integration - reads task context if available
allowed-tools: [Read, Edit, Write, Bash, Skill(ruby), Skill(javascript), Skill(rubycritic), Skill(simplecov), Skill(rubocop)]
---

<objective>
Practice TDD using the red-green-refactor cycle. When integrated with the execution agent, implement acceptance criteria from `.current-task.md`.
</objective>

<context_loading>
**First, check for task context from execution agent:**

```bash
# Check if context file exists
if [ -f .current-task.md ]; then
  cat .current-task.md
fi
```

**If `.current-task.md` exists:**

1. Read the file to understand the assigned task
2. Extract acceptance criteria to implement
3. Note the test commands specified
4. Reference affected files for patterns
5. Acknowledge the task before starting:

"Found task context: #{number} - {title}

Acceptance Criteria:

1. {AC1}
2. {AC2}
3. {AC3}

Which AC should we tackle first?"

**If `.current-task.md` does NOT exist:**

1. This is a standalone TDD session
2. Ask the human what functionality to implement
3. Proceed with standard TDD process
</context_loading>

<process>
1. **Red Phase**: Write a test for the smallest possible unit of functionality. Run the test and it should fail.
2. **Green Phase**: Write the minimal code to make the test pass.
3. **Refactor Phase**: Once the test passes, refactor the code to be more readable and maintainable.
4. **Commit Phase**: After refactor, commit changes with descriptive message.
</process>

<commit_pattern>
After each successful refactor phase:

```bash
# If working on a task from execution agent (has .current-task.md)
git add {test_file} {implementation_file}
git commit -m "feat: {what was implemented}

- Added test for {functionality}
- Implemented {approach}

Part of #{issue_number}"

# If standalone TDD session
git add {files}
git commit -m "feat: {description}"
```

</commit_pattern>

<rules>
- If more than one test fails, focus on the most important test to fix first
- During a fix phase, only run the failing test until it passes
- Do NOT use the TODO tool to track tasks during this session
- Rely on the human user to tell you what the next step is
- Keep the human informed of progress, especially for task-based work
- When an AC is satisfied, mark it complete and announce progress
</rules>

<ac_tracking>
When working from `.current-task.md`, track AC completion:

After completing an AC:
"✓ AC1 complete: {description}
   Test: {test_file}:{line}
   Commit: {hash}

Remaining ACs:

- [ ] AC2: {description}
- [ ] AC3: {description}

Ready for next AC. Which one?"
</ac_tracking>

<success_criteria>
**Each cycle completes when:**

- A single failing test exists (red)
- Minimal code is written to pass that test (green)
- Code is cleaned up without changing behavior (refactor)
- Changes are committed

**For task-based work, session completes when:**

- All acceptance criteria have passing tests
- All tests pass when run together
- Code is refactored and clean
- Human confirms ready for PR
</success_criteria>

<handoff>
**When all ACs are satisfied (task-based work):**

"## Implementation Complete

All acceptance criteria satisfied:

- [x] AC1: {description}
- [x] AC2: {description}
- [x] AC3: {description}

Tests: All passing
Commits: {n} commits on branch

Ready to create PR. Use `/gh-finish-task` to create PR and update the issue."

**When ending standalone session:**
"TDD session complete. {X} tests written, {Y} features implemented."
</handoff>
