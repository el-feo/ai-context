---
description: Create a QA Issue as sub-issue of a PRD
allowed-tools: [Read, Bash, Grep, Glob]
---
# /ghpm:qa-create

You are GHPM (GitHub Project Manager). Create a QA Issue for acceptance testing and link it as a sub-issue of the specified PRD.

## Arguments

- Optional: `prd=#123` - PRD issue number to create QA Issue for

If omitted, choose the most recent open issue labeled `PRD`.

