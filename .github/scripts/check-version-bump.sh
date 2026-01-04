#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Files/directories that don't require version bumps
IGNORED_PATTERNS=(
  "README.md"
  "*.txt"
  "LICENSE"
)

# Check if a file should be ignored for version bump purposes
should_ignore_file() {
  local file=$1
  local basename=$(basename "$file")

  for pattern in "${IGNORED_PATTERNS[@]}"; do
    if [[ "$basename" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# Extract plugin name from file path
get_plugin_name() {
  local file=$1
  echo "$file" | sed -n 's|^plugins/\([^/]*\)/.*|\1|p'
}

# Get version from plugin.json
get_plugin_version() {
  local plugin=$1
  local plugin_json="plugins/$plugin/.claude-plugin/plugin.json"

  if [[ -f "$plugin_json" ]]; then
    grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$plugin_json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
  else
    echo ""
  fi
}

# Get version from marketplace.json for a specific plugin
get_marketplace_version() {
  local plugin=$1
  local marketplace_json=".claude-plugin/marketplace.json"

  if [[ -f "$marketplace_json" ]]; then
    # Use jq if available, otherwise use grep/sed
    if command -v jq &> /dev/null; then
      jq -r ".plugins[] | select(.name == \"$plugin\") | .version" "$marketplace_json"
    else
      # Fallback: extract version after finding plugin name (basic parsing)
      awk -v plugin="$plugin" '
        /"name"[[:space:]]*:[[:space:]]*"'"$plugin"'"/ { found=1 }
        found && /"version"[[:space:]]*:/ {
          gsub(/.*"version"[[:space:]]*:[[:space:]]*"/, "")
          gsub(/".*/, "")
          print
          exit
        }
      ' "$marketplace_json"
    fi
  else
    echo ""
  fi
}

# Check if version was bumped in this PR
check_version_changed() {
  local file=$1
  git diff origin/main...HEAD -- "$file" | grep -q '"version"'
}

echo "=========================================="
echo "Plugin Version Bump Checker"
echo "=========================================="
echo ""

# Parse changed files to find affected plugins
declare -A PLUGINS_WITH_CHANGES
declare -A PLUGINS_NEED_BUMP

for file in $CHANGED_FILES; do
  plugin=$(get_plugin_name "$file")

  if [[ -z "$plugin" ]]; then
    continue
  fi

  # Skip if file should be ignored
  if should_ignore_file "$file"; then
    echo -e "${YELLOW}Ignoring:${NC} $file (documentation)"
    continue
  fi

  # Skip if the change is to plugin.json itself (version bump file)
  if [[ "$file" == *"plugin.json" ]]; then
    continue
  fi

  PLUGINS_WITH_CHANGES[$plugin]=1
done

# Check marketplace.json changes
MARKETPLACE_CHANGED=false
if echo "$CHANGED_FILES" | grep -q "marketplace.json"; then
  MARKETPLACE_CHANGED=true
fi

echo ""
echo "Plugins with changes: ${!PLUGINS_WITH_CHANGES[*]}"
echo ""

# Check each plugin for version bumps
ERRORS=()

for plugin in "${!PLUGINS_WITH_CHANGES[@]}"; do
  plugin_json="plugins/$plugin/.claude-plugin/plugin.json"

  echo "----------------------------------------"
  echo -e "Checking plugin: ${YELLOW}$plugin${NC}"

  # Check if plugin.json version was changed
  if ! check_version_changed "$plugin_json"; then
    ERRORS+=("Plugin '$plugin' has changes but version was not bumped in $plugin_json")
    echo -e "  ${RED}✗${NC} Version not bumped in plugin.json"
    PLUGINS_NEED_BUMP[$plugin]=1
  else
    echo -e "  ${GREEN}✓${NC} Version bumped in plugin.json"

    # Check if marketplace.json matches
    plugin_version=$(get_plugin_version "$plugin")
    marketplace_version=$(get_marketplace_version "$plugin")

    if [[ "$plugin_version" != "$marketplace_version" ]]; then
      ERRORS+=("Plugin '$plugin' version ($plugin_version) does not match marketplace.json ($marketplace_version)")
      echo -e "  ${RED}✗${NC} marketplace.json version mismatch (plugin: $plugin_version, marketplace: $marketplace_version)"
    else
      echo -e "  ${GREEN}✓${NC} marketplace.json version matches ($plugin_version)"
    fi
  fi
done

echo ""
echo "=========================================="

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo -e "${RED}VERSION CHECK FAILED${NC}"
  echo ""
  echo "The following issues were found:"
  echo ""
  for error in "${ERRORS[@]}"; do
    echo -e "  ${RED}•${NC} $error"
  done
  echo ""
  echo "Please bump the version in:"
  for plugin in "${!PLUGINS_NEED_BUMP[@]}"; do
    echo "  - plugins/$plugin/.claude-plugin/plugin.json"
  done
  echo "  - .claude-plugin/marketplace.json"
  echo ""
  echo "Version bump guide:"
  echo "  - fix: commits → patch bump (0.1.0 → 0.1.1)"
  echo "  - feat: commits → minor bump (0.1.0 → 0.2.0)"
  echo "  - breaking changes → major bump (0.1.0 → 1.0.0)"
  echo ""
  exit 1
else
  echo -e "${GREEN}VERSION CHECK PASSED${NC}"
  echo "All modified plugins have appropriate version bumps."
fi
