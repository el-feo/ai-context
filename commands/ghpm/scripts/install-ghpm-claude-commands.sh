#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
mkdir -p "$ROOT/.claude/commands"
cp -f .claude/commands/ghpm\:create-prd.md   "$ROOT/.claude/commands/ghpm:create-prd.md"
cp -f .claude/commands/ghpm\:create-epics.md "$ROOT/.claude/commands/ghpm:create-epics.md"
cp -f .claude/commands/ghpm\:create-tasks.md "$ROOT/.claude/commands/ghpm:create-tasks.md"
cp -f .claude/commands/ghpm\:tdd-task.md     "$ROOT/.claude/commands/ghpm:tdd-task.md"
cp -f .claude/commands/ghpm\:changelog.md    "$ROOT/.claude/commands/ghpm:changelog.md"
echo "Installed GHPM Claude Code commands into: $ROOT/.claude/commands"
