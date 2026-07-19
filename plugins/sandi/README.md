# sandi

An object-oriented design advisor for Claude Code, channeling Sandi Metz's
philosophy (from *Practical Object-Oriented Design in Ruby* and *99 Bottles of
OOP*). The north star is always **code that is easy to change.**

The skill is language-agnostic — the principles come from Ruby books but apply to
any OO language (JavaScript/TypeScript, Python, Java, C#, Swift, etc.).

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install sandi@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/sandi
```

## Usage

### Command

```text
/sandi [plan|review|audit|refactor|advise (optional)] <your request, code, PRD, or question>
```

`/sandi` auto-detects which of five modes fits your request and responds in that
mode. You can prefix an explicit mode word to force one.

```text
/sandi:install-review [path glob(s) (optional)]
```

`/sandi:install-review` installs an automated PR-review GitHub workflow into the
current repository (see below).

### Skill (1)

- **sandi** — Triggers on the `/sandi` command, or whenever you ask about
  object-oriented design, software architecture, how to structure or plan a
  feature, refactoring, code review of classes/objects, dependency management,
  code smells, SOLID, design patterns, duck typing, or mention Sandi Metz,
  POODR, "99 Bottles", "shameless green", "flocking rules", the "squint test",
  the "Law of Demeter", or "tell don't ask".

## The five modes

| Your request is about… | Mode | Example |
|---|---|---|
| Planning/architecting a feature from a PRD or spec, greenfield design | **PLAN** | "How should I structure a notifications system?" |
| Reviewing a PR, a class, or existing code | **REVIEW** | "Is this service object any good?" |
| Auditing a whole codebase's OO health, ranked by leverage | **AUDIT** | "Audit this repo — where's the design debt?" |
| Improving code that already works | **REFACTOR** | "DRY up this duplicated logic" |
| Understanding a concept or tradeoff | **ADVISE** | "When should I use duck typing?" |

Modes compose — audit a codebase, review a hotspot it surfaces, then flow into refactoring.

PLAN mode also **enhances Claude Code's built-in plan mode**: invoke it during a plan-mode
session and it contributes an `## Object Design (Sandi)` layer — objects, responsibilities, the
message conversation, seams, and what *not* to build — into the plan file alongside the
implementation steps.

## Automated PR reviews (GitHub Actions)

The plugin ships a generic `sandi-review.yml` workflow template that runs a
Sandi review on every PR via [claude-code-action](https://github.com/anthropics/claude-code-action).
Install it into any GitHub repo with:

```text
/sandi:install-review            # review all changed files in each PR
/sandi:install-review app/** lib/**   # scope the review to specific paths
```

How it works:

- Fires automatically when a PR is opened or reopened; comment `/sandi` on a PR
  (owners/members/collaborators only) to request a re-review.
- Installs the `sandi` plugin from this marketplace into the CI runner, so the
  target repo needs no vendored skill files — updates to the plugin flow
  through automatically.
- Delivers the review like a human reviewer — in the tone of a teacher/coach,
  explaining the why behind each finding: inline comments anchored to the diff
  (with one-click ```suggestion blocks where the fix is small), plus a single
  summary comment covering cross-cutting themes and priorities.

### Requirements

- A repository hosted on **GitHub** (the workflow uses GitHub Actions and the
  `gh` CLI).
- **Claude Code** installed locally with this plugin installed (to run the
  installer command; the workflow file itself is plain YAML you could also
  copy by hand from `templates/sandi-review.yml`).
- The **`gh` CLI** authenticated against the repo (`gh auth login`) — the
  installer uses it to check/set the repo secret.
- A **Claude subscription (Pro/Max) or Claude Console account** to generate an
  OAuth token — the CI review runs on your Claude account.
- **Admin access** to the repo (setting Actions secrets requires it).

### First-time setup

```bash
# 1. In Claude Code, install the plugin (once per machine)
/plugin marketplace add el-feo/ai-context
/plugin install sandi@jebs-dev-tools

# 2. From the repo you want reviewed, run the installer
/sandi:install-review              # or: /sandi:install-review app/** lib/**

# 3. Create the token and store it as a repo secret
#    (the installer checks for this and walks you through it if missing)
claude setup-token
gh secret set CLAUDE_CODE_OAUTH_TOKEN

# 4. Commit the workflow and open a PR — the first review fires automatically
git add .github/workflows/sandi-review.yml && git commit -m "ci: add Sandi Metz PR review"
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
sandi/
├── commands/sandi.md          # /sandi slash command
├── commands/install-review.md # /sandi:install-review — install the PR-review workflow
├── templates/sandi-review.yml # generic GitHub Actions workflow template
└── skills/sandi/
    ├── SKILL.md               # shared foundation + mode selection
    └── references/
        ├── planning.md        # PLAN mode procedure + plan-mode design layer
        ├── review.md          # REVIEW mode procedure
        ├── audit.md           # AUDIT mode: whole-codebase OO health, ranked by leverage
        ├── refactoring.md     # flocking rules, 99 Bottles, code-smell catalog
        ├── principles.md      # deep treatment of every core principle
        └── teaching.md        # ADVISE mode: Socratic explanation of tradeoffs
```
