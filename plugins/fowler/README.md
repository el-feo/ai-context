# fowler

A refactoring advisor grounded in Martin Fowler's *Refactoring: Improving the
Design of Existing Code* (2nd edition). It diagnoses code smells, applies
catalog refactorings using their step-by-step mechanics — small
behavior-preserving steps with tests between them — and teaches when and why to
use each of the 64 catalog techniques. Language-agnostic: the discipline applies
to Ruby, JavaScript, Python, or anything else with functions and objects.

## Installation

```bash
# Add the marketplace (from GitHub)
/plugin marketplace add el-feo/ai-context

# Install the plugin
/plugin install fowler@jebs-dev-tools

# Or use the plugin directory directly
cc --plugin-dir /path/to/ai-context/plugins/fowler
```

## Usage

### Command

```text
/fowler [diagnose|refactor|advise] <code, file paths, a refactoring name, or a question>
```

The mode keyword is optional — the skill auto-detects intent:

```text
/fowler app/services/invoice_builder.rb            # diagnose smells
/fowler extract class on app/models/user.rb        # guided refactoring
/fowler when should I use Split Phase?             # advice/teaching
```

```text
/fowler:install-review [path glob(s) (optional)]
```

`/fowler:install-review` installs an automated PR-review GitHub workflow into
the current repository (see below).

### Skill trigger

The skill also activates without the command whenever you ask to refactor,
clean up, or restructure code, mention a code smell or a catalog refactoring by
name, or wrestle with code that's hard to read or change.

## The three modes

| Mode | What it does |
| --- | --- |
| **DIAGNOSE** | Finds code smells by their catalog names and prescribes the refactorings that cure them, ranked by payoff |
| **REFACTOR** | Applies a refactoring following its catalog mechanics — one small step at a time, tests between steps, never mixing behavior change with structure change |
| **ADVISE** | Explains and compares techniques: motivation, trade-offs, inverses, and when *not* to refactor |

## Automated PR reviews (GitHub Actions)

The plugin ships a generic `fowler-review.yml` workflow template that runs a
refactoring review on every PR via [claude-code-action](https://github.com/anthropics/claude-code-action).
Install it into any GitHub repo with:

```text
/fowler:install-review           # review all changed files in each PR
/fowler:install-review app/** lib/**   # scope the review to specific paths
```

How it works:

- Fires automatically when a PR is opened or reopened; comment `/fowler` on a
  PR (owners/members/collaborators only) to request a re-review.
- Installs the `fowler` plugin from this marketplace into the CI runner, so the
  target repo needs no vendored skill files — updates to the plugin flow
  through automatically.
- Delivers the review like a human reviewer — in the tone of a teacher/coach,
  explaining why each smell hurts: inline comments that name each smell by its
  catalog name and prescribe the curing refactoring (with one-click
  ```suggestion blocks where the fix is small), plus a single summary comment
  with a prioritized refactoring order.

### Requirements

- A repository hosted on **GitHub** (the workflow uses GitHub Actions and the
  `gh` CLI).
- **Claude Code** installed locally with this plugin installed (to run the
  installer command; the workflow file itself is plain YAML you could also
  copy by hand from `templates/fowler-review.yml`).
- The **`gh` CLI** authenticated against the repo (`gh auth login`) — the
  installer uses it to check/set the repo secret.
- A **Claude subscription (Pro/Max) or Claude Console account** to generate an
  OAuth token — the CI review runs on your Claude account.
- **Admin access** to the repo (setting Actions secrets requires it).

### First-time setup

```bash
# 1. In Claude Code, install the plugin (once per machine)
/plugin marketplace add el-feo/ai-context
/plugin install fowler@jebs-dev-tools

# 2. From the repo you want reviewed, run the installer
/fowler:install-review             # or: /fowler:install-review app/** lib/**

# 3. Create the token and store it as a repo secret
#    (the installer checks for this and walks you through it if missing)
claude setup-token
gh secret set CLAUDE_CODE_OAUTH_TOKEN

# 4. Commit the workflow and open a PR — the first review fires automatically
git add .github/workflows/fowler-review.yml && git commit -m "ci: add Fowler refactoring review"
```

### Using Amazon Bedrock instead

The template authenticates against Anthropic's hosted API with an OAuth token.
To run the review through Amazon Bedrock — billing via AWS, no Claude
subscription or `CLAUDE_CODE_OAUTH_TOKEN` needed — swap the auth wiring; the
plugin install, security gating, and review prompt all carry over unchanged.

Two things differ:

- **AWS auth via GitHub OIDC** (recommended — no long-lived AWS keys): the
  workflow's existing `id-token: write` permission lets
  `aws-actions/configure-aws-credentials` assume an IAM role.
- **Bring your own GitHub App**: the Anthropic-hosted flow gets its GitHub
  credentials from an OIDC exchange with Anthropic's backend. With Bedrock
  there is no Anthropic backend, so you must create a GitHub App and mint a
  token with `actions/create-github-app-token`, passing it as both the
  `github_token` input and the `GH_TOKEN` env var.

Replace the `claude-code-action` step (and its `claude_code_oauth_token`
input) with:

```yaml
- name: Generate GitHub App token
  id: app-token
  uses: actions/create-github-app-token@v2
  with:
    app-id: ${{ secrets.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}

- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
    aws-region: us-west-2

- uses: anthropics/claude-code-action@v1
  env:
    GH_TOKEN: ${{ steps.app-token.outputs.token }}
  with:
    github_token: ${{ steps.app-token.outputs.token }}
    use_bedrock: "true"
    # plugin_marketplaces, plugins, prompt, use_sticky_comment: unchanged
    claude_args: |
      --model us.anthropic.claude-sonnet-5-v1:0   # Bedrock model ID, not the API name
      # --allowedTools and --max-turns: unchanged
```

One-time AWS setup:

1. Create an IAM **OIDC identity provider** for
   `token.actions.githubusercontent.com`.
2. Create an **IAM role** trusting that provider, scoped to your repo
   (`repo:org/repo:*` in the `sub` condition), with `bedrock:InvokeModel` and
   `bedrock:InvokeModelWithResponseStream` on the Claude model ARNs.
3. Grant **model access in the Bedrock console** — in every region the
   cross-region inference profile spans, not just the one you call.

See the [claude-code-action cloud providers docs](https://github.com/anthropics/claude-code-action/blob/main/docs/cloud-providers.md)
for details (Google Vertex AI follows the same pattern).

## What's inside

```text
fowler/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   ├── fowler.md                # /fowler — thin wrapper that engages the skill
│   └── install-review.md        # /fowler:install-review — install the PR-review workflow
├── templates/
│   └── fowler-review.yml        # generic GitHub Actions workflow template
└── skills/
    └── fowler/
        ├── SKILL.md             # Modes, discipline, and catalog index
        └── references/
            ├── principles.md    # Two hats, when (not) to refactor, testing discipline
            ├── smells.md        # All 24 code smells → curing refactorings
            ├── first-set.md     # Extract Function, Rename Variable, Split Phase…
            ├── encapsulation.md # Encapsulate Record, Extract Class, Hide Delegate…
            ├── moving-features.md # Move Function, Split Loop, Replace Loop with Pipeline…
            ├── organizing-data.md # Split Variable, Change Reference to Value…
            ├── conditional-logic.md # Guard Clauses, Replace Conditional with Polymorphism…
            ├── apis.md          # Remove Flag Argument, Preserve Whole Object…
            └── inheritance.md   # Pull Up Method, Replace Subclass with Delegate…
```

The reference files are original distillations of the catalog — condensed
motivations, mechanics, and pitfalls in this plugin's own words and examples —
not reproductions of the book. Buy the book; it's worth it.
