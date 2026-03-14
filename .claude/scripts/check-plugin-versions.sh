#!/bin/bash
# Check if modified plugins need version bumps.
# Compatible with macOS bash 3.2 (no associative arrays).
#
# Usage:
#   check-plugin-versions.sh [--mode stop|pr]
#     stop  = check uncommitted/staged changes (default)
#     pr    = check branch changes vs origin/main

set -e

MODE="stop"
if [ "$1" = "--mode" ] && [ -n "$2" ]; then
  MODE="$2"
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$REPO_ROOT"

# Collect changed files based on mode
if [ "$MODE" = "pr" ]; then
  CHANGED_FILES=$(git diff --name-only origin/main...HEAD 2>/dev/null)
else
  # Combine staged + unstaged + untracked under plugins/
  CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null)
fi

[ -z "$CHANGED_FILES" ] && exit 0

# Extract unique plugin names from changed files (skip plugin.json and ignored files)
PLUGINS=""
for file in $CHANGED_FILES; do
  # Must be under plugins/
  case "$file" in
    plugins/*)
      # Skip plugin.json itself, README.md, *.txt, LICENSE
      basename=$(basename "$file")
      case "$basename" in
        plugin.json|README.md|LICENSE|*.txt) continue ;;
      esac
      # Extract plugin name
      plugin=$(echo "$file" | sed 's|^plugins/\([^/]*\)/.*|\1|')
      # Add to list if not already there
      case " $PLUGINS " in
        *" $plugin "*) ;;
        *) PLUGINS="$PLUGINS $plugin" ;;
      esac
      ;;
  esac
done

[ -z "$PLUGINS" ] && exit 0

# Check each plugin for version bump
WARNINGS=""
for plugin in $PLUGINS; do
  plugin_json="plugins/$plugin/.claude-plugin/plugin.json"
  [ ! -f "$plugin_json" ] && continue

  if [ "$MODE" = "pr" ]; then
    VERSION_CHANGED=$(git diff origin/main...HEAD -- "$plugin_json" 2>/dev/null | grep '"version"' || true)
  else
    VERSION_CHANGED=$(git diff HEAD -- "$plugin_json" 2>/dev/null | grep '"version"' || true)
    if [ -z "$VERSION_CHANGED" ]; then
      VERSION_CHANGED=$(git diff --cached -- "$plugin_json" 2>/dev/null | grep '"version"' || true)
    fi
  fi

  if [ -z "$VERSION_CHANGED" ]; then
    WARNINGS="${WARNINGS}Plugin '${plugin}' has changes but no version bump. Run: .github/scripts/bump-version.sh ${plugin} patch\n"
  fi
done

if [ -n "$WARNINGS" ]; then
  echo ""
  echo "=== Version Bump Reminder ==="
  printf "$WARNINGS"
  echo ""
  echo "Guide: fix->patch, feat->minor, breaking->major"
  echo "==============================="
fi
