---
description: Generate a changelog from merged PRs using conventional commits format.
allowed-tools: [Bash, Read, Write]
arguments:
  from:
    description: "Starting reference (tag, commit, or date): from=v1.0.0 or from=2024-01-01"
    required: false
  to:
    description: "Ending reference (default: HEAD): to=v1.1.0 or to=main"
    required: false
  output:
    description: "Output file path (default: CHANGELOG.md): output=docs/CHANGELOG.md"
    required: false
---

<objective>
Generate a changelog from merged PRs and commits that follow Conventional Commits format. Group changes by type (Features, Bug Fixes, etc.) and include PR/issue references.
</objective>

<prerequisites>
- `gh` CLI installed and authenticated (`gh auth status`)
- Working directory is a git repository with GitHub remote
- Repository uses Conventional Commits format for PR titles
</prerequisites>

<arguments>
**Optional arguments:**
- `from=<ref>` - Starting reference (tag, commit SHA, or date like `2024-01-01`)
- `to=<ref>` - Ending reference (default: `HEAD`)
- `output=<path>` - Output file path (default: `CHANGELOG.md`)

**Default behavior:**

- If no `from` provided, uses the most recent tag
- If no tags exist, uses the first commit
</arguments>

<usage_examples>
**Generate changelog since last tag:**

```bash
/ghpm:changelog
```

**Generate changelog between versions:**

```bash
/ghpm:changelog from=v1.0.0 to=v1.1.0
```

**Generate changelog to specific file:**

```bash
/ghpm:changelog output=docs/CHANGELOG.md
```

**Generate changelog from date:**

```bash
/ghpm:changelog from=2024-01-01
```

</usage_examples>

<operating_rules>

- Parse PR titles and commit messages for conventional commit format
- Group changes by type (feat, fix, refactor, etc.)
- Include PR numbers and links
- Include contributor attribution
- Handle breaking changes specially (highlight at top)
- Preserve existing changelog content when appending
</operating_rules>

<changelog_format>

## Output Format

```markdown
# Changelog

## [Unreleased] OR [vX.Y.Z] - YYYY-MM-DD

### Breaking Changes
- **scope:** description (#PR) @contributor

### Features
- **scope:** description (#PR) @contributor

### Bug Fixes
- **scope:** description (#PR) @contributor

### Performance
- **scope:** description (#PR) @contributor

### Code Refactoring
- **scope:** description (#PR) @contributor

### Documentation
- **scope:** description (#PR) @contributor

### Testing
- **scope:** description (#PR) @contributor

### Maintenance
- **scope:** description (#PR) @contributor
```

### Section Mapping

| Commit Type | Changelog Section |
| ----------- | ----------------- |
| `feat`      | Features          |
| `fix`       | Bug Fixes         |
| `perf`      | Performance       |
| `refactor`  | Code Refactoring  |
| `docs`      | Documentation     |
| `test`      | Testing           |
| `chore`     | Maintenance       |
| `build`     | Maintenance       |
| `ci`        | Maintenance       |
| `style`     | (excluded)        |
| `revert`    | Reverts           |

</changelog_format>

<workflow>

## Step 1: Determine Range

```bash
# Get most recent tag if from not specified
FROM_REF="${FROM:-$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)}"
TO_REF="${TO:-HEAD}"

echo "Generating changelog from $FROM_REF to $TO_REF"
```

## Step 2: Fetch Merged PRs

```bash
# Get merged PRs in range
gh pr list \
  --state merged \
  --base main \
  --json number,title,author,mergedAt,labels \
  --jq '.[] | select(.mergedAt >= "'$FROM_DATE'")' \
  > /tmp/prs.json
```

Alternatively, parse git log:

```bash
git log "$FROM_REF".."$TO_REF" --oneline --format="%s|%h|%an" > /tmp/commits.txt
```

## Step 3: Parse Conventional Commits

For each PR title or commit message, extract:

1. **Type**: `feat`, `fix`, `refactor`, etc.
2. **Scope**: Optional scope in parentheses
3. **Breaking**: `!` after type or `BREAKING CHANGE:` in body
4. **Description**: The commit description
5. **PR number**: `(#123)` reference

**Regex pattern:**

```
^(feat|fix|refactor|perf|test|docs|chore|build|ci|style|revert)(\(.+\))?(!)?:\s*(.+?)(?:\s*\(#(\d+)\))?$
```

## Step 4: Group by Type

Organize parsed commits into sections:

```
breaking_changes = []
features = []
fixes = []
performance = []
refactoring = []
documentation = []
testing = []
maintenance = []
reverts = []
```

## Step 5: Generate Changelog Content

Build markdown content with:

1. Version header (from `to` ref or "Unreleased")
2. Date (today or tag date)
3. Sections in order (Breaking Changes first, then Features, etc.)
4. Only include sections that have entries
5. Each entry: `- **scope:** description (#PR) @author`

## Step 6: Write Output

```bash
OUTPUT_FILE="${OUTPUT:-CHANGELOG.md}"

# If file exists, insert new content after header
# Otherwise create new file

# Write content
cat > "$OUTPUT_FILE" << 'EOF'
# Changelog

<generated content>
EOF
```

If prepending to existing changelog:

```bash
# Read existing content (skip header)
EXISTING=$(tail -n +3 "$OUTPUT_FILE")

# Write new content + existing
cat > "$OUTPUT_FILE" << EOF
# Changelog

<new version content>

$EXISTING
EOF
```

</workflow>

<error_handling>
**If no conventional commits found:**

- Warn user that commits don't follow conventional format
- Offer to list all commits without categorization

**If no PRs in range:**

- Check if range is valid
- Suggest alternative range
- Fall back to commit-based changelog

**If output file not writable:**

- Check permissions
- Suggest alternative path
- Output to stdout as fallback
</error_handling>

<success_criteria>
Command completes successfully when:

1. Changelog content is generated
2. Changes are properly grouped by type
3. PR numbers and authors are included
4. Breaking changes are highlighted
5. Output file is written (or content displayed)

**Output summary:**

```
Changelog generated:
- Range: v1.0.0..HEAD
- PRs processed: 15
- Features: 5
- Bug Fixes: 3
- Refactoring: 4
- Other: 3
- Output: CHANGELOG.md
```

</success_criteria>

Proceed now.

<!-- Test change to trigger version check workflow -->
