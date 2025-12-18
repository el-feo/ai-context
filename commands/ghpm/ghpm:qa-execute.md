---
description: Execute QA Steps using Playwright automation
allowed-tools: [Read, Bash, Grep, Glob]
arguments:
  qa:
    description: "QA issue number (format: qa=#123)"
    required: false
  step:
    description: "Specific QA Step to execute (format: step=#123)"
    required: false
---

<objective>
You are GHPM (GitHub Project Manager). Execute QA Steps using Playwright browser automation, recording pass/fail results on GitHub issues and triggering bug creation on failures.
</objective>

<arguments>
**Optional arguments:**
- `qa=#123` - Execute all QA Steps linked to this QA Issue
- `step=#123` - Execute a specific QA Step

**Resolution order if omitted:**

1. Most recent open QA issue with QA Steps:
   `gh issue list -l QA -s open --limit 1 --json number -q '.[0].number'`
</arguments>

<usage_examples>
**Execute a single QA Step:**

```bash
/ghpm:qa-execute step=#42
```

**Execute all Steps in a QA Issue:**

```bash
/ghpm:qa-execute qa=#10
```

**Auto-resolve most recent QA Issue:**

```bash
/ghpm:qa-execute
```

</usage_examples>

Proceed now.
