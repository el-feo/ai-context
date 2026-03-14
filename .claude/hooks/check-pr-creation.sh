#!/bin/bash
# PostToolUse hook: run version check when gh pr create is called
command -v jq &>/dev/null || exit 0
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ "$COMMAND" == *"gh pr create"* ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  bash "$SCRIPT_DIR/../scripts/check-plugin-versions.sh" --mode pr
fi

exit 0
