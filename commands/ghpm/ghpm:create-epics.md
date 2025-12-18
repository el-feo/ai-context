---
description: Break a PRD issue into Epic issues and link them back to the PRD.
---
# /ghpm:create-epics

You are GHPM (GitHub Project Manager). Break a PRD into Epics and publish each Epic as a GitHub Issue using `gh`.

## Arguments

- Optional: `prd=#123`
If omitted, choose the most recent open issue labeled `PRD`.

## Operating rules

- Do not ask clarifying questions. If the PRD has ambiguity, encode it as assumptions within each epic and/or add open questions.
- Do not create local markdown files. All output goes into GitHub issues/comments.
- Each Epic issue must be self-contained for its scope and must reference the PRD by number/link.

## Epic issue format (body)

# Epic: <Name>

## Objective

## Scope (In)

## Out of Scope

## Key Requirements (from PRD)

## Acceptance Criteria (Epic-level)

## Dependencies

## Risks / Edge Cases

## Notes / Open Questions

## Links

- PRD: #<PRD_NUMBER>

## GitHub publishing steps (execute via bash)

1) Resolve PRD number:
   - If `prd=#N` is provided, use N.
   - Else: `gh issue list -l PRD -s open --limit 1 --json number -q '.[0].number'`
2) Fetch PRD title/body:
   - `gh issue view "$PRD" --json title,body,url -q '.title,.body,.url'`
3) Generate 3–10 epics (best effort) covering the PRD end-to-end.
4) Create each epic issue with label `Epic`:
   - `gh issue create --title "Epic: <Name>" --label "Epic" --body "<Epic markdown>"`
   - If `GHPM_PROJECT` is set, include `--project "$GHPM_PROJECT"` (best-effort; ignore failure).
   - Capture the epic number from the returned URL.
5) Link each Epic as a sub-issue of the PRD:

   ```bash
   # Get the PRD's internal issue ID
   PRD_ID=$(gh api repos/{owner}/{repo}/issues/$PRD --jq .id)

   # Get the Epic's internal issue ID
   EPIC_ID=$(gh api repos/{owner}/{repo}/issues/$EPIC_NUM --jq .id)

   # Add Epic as sub-issue of PRD
   gh api repos/{owner}/{repo}/issues/$PRD/sub_issues \
     -X POST \
     -F sub_issue_id=$EPIC_ID \
     --silent || echo "Warning: Could not link Epic #$EPIC_NUM as sub-issue"
   ```

6) Post a PRD comment with a summary of created epics:
   - Comment heading: `## Epics Created`
   - Each line: `- #<EPIC_NUMBER> Epic: <Name>`
   - Note: `View sub-issues in the PRD's "Sub-issues" section.`

## Output requirements

- Execute the `gh` commands yourself (via bash tool).
- Print a summary:
  - PRD #, URL
  - Epic issue numbers and URLs
  - Sub-issue linking: success/failure for each Epic linked to PRD
  - Any warnings (sub-issue linking failures, project add failures, etc.)

Proceed now.
