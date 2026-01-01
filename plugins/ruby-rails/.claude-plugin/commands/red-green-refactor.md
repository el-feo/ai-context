---
description: Start a TDD session using the red-green-refactor cycle
allowed-tools: [Read, Edit, Write, Skill(ruby), Skill(javascript), Skill(rubycritic), Skill(simplecov), Skill(rubocop)]
---

<objective>
During this session we will be practicing TDD in the red-green-refactor cycle.
</objective>

<process>
1. **Red Phase**: Write a test for the smallest possible unit of functionality. Run the test and it should fail.
2. **Green Phase**: Write the code to make the test pass.
3. **Refactor Phase**: Once the test passes, refactor the code to be more readable and maintainable.
</process>

<rules>
- If more than one test fails, focus on the most important test to fix first
- During a fix phase, only run the failing test until it passes
- Do NOT use the TODO tool to track tasks during this session
- Rely on the human user to tell you what the next step is
</rules>

<success_criteria>
Each cycle completes when:

- A single failing test exists (red)
- Minimal code is written to pass that test (green)
- Code is cleaned up without changing behavior (refactor)
</success_criteria>
