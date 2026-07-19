---
description: Install the Sandi Metz automated PR-review GitHub workflow into the current repository.
argument-hint: [path glob(s) to scope the review to (optional), e.g. app/** lib/**]
---

Install the Sandi Metz automated PR review workflow into this repository. The
workflow runs `claude-code-action` on every opened/reopened PR (and on `/sandi`
PR comments), installs the `sandi` plugin from the jebs-dev-tools marketplace
into the CI runner, and delivers the review as inline PR comments plus one
summary comment.

The generic template lives at `${CLAUDE_PLUGIN_ROOT}/templates/sandi-review.yml`.

Follow these steps:

1. **Verify the repo.** Confirm the current directory is a git repository with
   a GitHub remote (`git remote -v`). If not, stop and explain that the
   workflow only works on GitHub-hosted repos.

2. **Check for an existing install.** If `.github/workflows/sandi-review.yml`
   already exists, show the user how it differs from the template and ask
   before overwriting.

3. **Copy the template** to `.github/workflows/sandi-review.yml` (create the
   directory if needed).

4. **Scope the review (optional).** If the user passed path globs as arguments,
   or asks to limit the review to part of the codebase:
   - Add a `paths:` filter under the `pull_request` trigger with those globs
     (replace the commented example).
   - Update the `Scope:` paragraph in the prompt to say the review covers ONLY
     changed files matching those paths and ignores changes elsewhere.

   If no scope was given, leave the template as-is — it reviews all changed
   files in the PR.

5. **Verify the secret.** Run `gh secret list` and check for
   `CLAUDE_CODE_OAUTH_TOKEN`. If it's missing, tell the user to create one:

   ```bash
   claude setup-token   # generates an OAuth token (requires a Claude subscription)
   gh secret set CLAUDE_CODE_OAUTH_TOKEN
   ```

6. **Summarize.** Tell the user: the workflow file installed, how it triggers
   (auto on PR open/reopen; `/sandi` comment from an owner/member/collaborator
   for a re-review), any scoping applied, and whether the secret is in place.
   Offer to commit the workflow file — but do not commit without their say-so.

$ARGUMENTS
