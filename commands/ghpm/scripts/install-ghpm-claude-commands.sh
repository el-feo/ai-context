#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"

ROOT="${1:-.}"
mkdir -p "$ROOT/.claude/commands"

cp -f "$SOURCE_DIR/ghpm:create-prd.md"   "$ROOT/.claude/commands/ghpm:create-prd.md"
cp -f "$SOURCE_DIR/ghpm:create-epics.md" "$ROOT/.claude/commands/ghpm:create-epics.md"
cp -f "$SOURCE_DIR/ghpm:create-tasks.md" "$ROOT/.claude/commands/ghpm:create-tasks.md"
cp -f "$SOURCE_DIR/ghpm:execute.md"      "$ROOT/.claude/commands/ghpm:execute.md"
cp -f "$SOURCE_DIR/ghpm:tdd-task.md"     "$ROOT/.claude/commands/ghpm:tdd-task.md"
cp -f "$SOURCE_DIR/ghpm:changelog.md"    "$ROOT/.claude/commands/ghpm:changelog.md"

echo "Installed GHPM Claude Code commands into: $ROOT/.claude/commands"
