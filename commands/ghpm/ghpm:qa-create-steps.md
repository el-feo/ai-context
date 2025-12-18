---
description: Create QA Step issues as sub-issues of a QA Issue
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  qa:
    description: "QA issue number (format: qa=#123)"
    required: false
---

<qa_step_issue_template>

## QA Step Issue Body Template

```markdown
# QA Step: <Brief Description>

## Scenario

As a <role>,
Given <precondition>,
When <action>,
Then <expected outcome>

## Parent QA Issue

- QA: #<QA_NUMBER>

## Test Details

- **URL/Page:** <starting URL or page>
- **Prerequisites:** <any setup needed>
- **Test Data:** <if applicable>

## Execution Log

- [ ] Pass / Fail
- **Executed by:** (not yet executed)
- **Timestamp:** (pending)
- **Notes:** (none)

## Bugs Found

(None)
```

### Template Field Descriptions

| Field | Description |
|-------|-------------|
| `<Brief Description>` | Concise 3-8 word summary of what is being tested |
| `<role>` | User role or persona (e.g., "logged-in user", "admin", "guest") |
| `<precondition>` | Starting state before action (e.g., "I am on the dashboard page") |
| `<action>` | Single user action being tested (e.g., "I click the Submit button") |
| `<expected outcome>` | Observable result (e.g., "I should see a success message") |
| `<QA_NUMBER>` | Parent QA Issue number |
| `<URL/Page>` | Starting URL or page name |
| `<Prerequisites>` | Any setup required before testing |
| `<Test Data>` | Specific test data needed (if any) |

### Given/When/Then Format Guidelines

- **Given** describes the initial state or preconditions
- **When** describes a single, atomic user action
- **Then** describes the expected observable outcome
- Keep each step atomic (one action per QA Step)
- Use clear, specific language that is machine-parseable

</qa_step_issue_template>
