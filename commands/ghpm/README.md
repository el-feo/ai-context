# GHPM for Claude Code

This zip includes the **actual Claude Code command files** under `.claude/commands/` plus an optional install helper.

## What you get

```
.claude/commands/
  ghpm:create-prd.md
  ghpm:create-epics.md
  ghpm:create-tasks.md
  ghpm:tdd-task.md
scripts/
  install-ghpm-claude-commands.sh
README.md
```

## Install

From your repository root, copy the `.claude/` folder into your repo, or run:

```bash
chmod +x scripts/install-ghpm-claude-commands.sh
./scripts/install-ghpm-claude-commands.sh
```

## Commands

- `/ghpm:create-prd <prompt>`
- `/ghpm:create-epics [prd=#N]`
- `/ghpm:create-tasks epic=#N` or `prd=#N`
- `/ghpm:tdd-task [task=#N] [focus=unit|integration|e2e]`

## Optional: add created issues to a GitHub Project

Set:

```bash
export GHPM_PROJECT="Your Project Name"
```

## Recommended labels (one-time)

```bash
gh label create PRD  --description "Product Requirements Document" --color 0E8A16 || true
gh label create Epic --description "Epic-level work"               --color 1D76DB || true
gh label create Task --description "Atomic unit of work"           --color FBCA04 || true
```


## If you don't see `.claude/` after unzipping

Some file browsers hide dotfolders by default. This package includes a *visible mirror* at:

```
claude/commands/
```

Those files are identical, except the filenames use `ghpm_...` (underscore) to avoid colon/visibility issues in some environments.

For Claude Code, you ultimately want:

```
.claude/commands/ghpm:create-prd.md
.claude/commands/ghpm:create-epics.md
.claude/commands/ghpm:create-tasks.md
.claude/commands/ghpm:tdd-task.md
```

If your system stripped or hid these, run the installer script from your repo root; it will (re)create the correct `.claude/commands/*` files:

```bash
chmod +x scripts/install-ghpm-claude-commands.sh
./scripts/install-ghpm-claude-commands.sh
```
