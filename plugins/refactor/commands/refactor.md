---
description: Martin Fowler refactoring advisor — diagnoses code smells, applies catalog refactorings step-by-step with tests between steps, or explains when and why to use each technique.
argument-hint: [diagnose|refactor|advise (optional)] <code, file paths, a refactoring name, or a question>
---

Engage the `refactor` skill and follow its SKILL.md.

Auto-detect the mode from the request (or honor an explicit leading keyword):

- **diagnose** — review the given code for Fowler's code smells and prescribe
  the catalog refactorings that cure them.
- **refactor** — apply a refactoring (named by the user, or chosen from a
  diagnosis) following the catalog mechanics: small behavior-preserving steps,
  tests run between steps.
- **advise** — answer design questions, compare techniques, or teach a smell or
  refactoring with examples in the user's language.

$ARGUMENTS
