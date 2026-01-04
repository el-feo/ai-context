#!/bin/bash
set -e

PLUGIN=$1
BUMP_TYPE=$2

if [[ -z "$PLUGIN" || -z "$BUMP_TYPE" ]]; then
  echo "Usage: $0 <plugin-name> <patch|minor|major>"
  exit 1
fi

PLUGIN_JSON="plugins/$PLUGIN/.claude-plugin/plugin.json"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"

if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "Error: Plugin '$PLUGIN' not found at $PLUGIN_JSON"
  exit 1
fi

# Get current version
CURRENT_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_JSON" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')

echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version based on type
case $BUMP_TYPE in
  patch)
    PATCH=$((PATCH + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  *)
    echo "Error: Invalid bump type '$BUMP_TYPE'. Use patch, minor, or major."
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version: $NEW_VERSION"

# Update plugin.json
sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" "$PLUGIN_JSON"
rm -f "$PLUGIN_JSON.bak"

# Update marketplace.json
# This is trickier - need to update the version for the specific plugin
if command -v jq &> /dev/null; then
  # Use jq for precise JSON manipulation
  jq "(.plugins[] | select(.name == \"$PLUGIN\") | .version) = \"$NEW_VERSION\"" "$MARKETPLACE_JSON" > "${MARKETPLACE_JSON}.tmp"
  mv "${MARKETPLACE_JSON}.tmp" "$MARKETPLACE_JSON"
else
  # Fallback: use sed (less precise but works for simple cases)
  # Find the plugin block and update its version
  # This assumes the JSON is formatted with each field on its own line
  python3 << EOF
import json

with open("$MARKETPLACE_JSON", 'r') as f:
    data = json.load(f)

for plugin in data.get('plugins', []):
    if plugin.get('name') == "$PLUGIN":
        plugin['version'] = "$NEW_VERSION"
        break

with open("$MARKETPLACE_JSON", 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
EOF
fi

echo "Updated $PLUGIN_JSON and $MARKETPLACE_JSON to version $NEW_VERSION"

# Save new version for commit message
echo "$NEW_VERSION" > .new-version
