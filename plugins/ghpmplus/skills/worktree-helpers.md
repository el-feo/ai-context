# Git Worktree Helpers for GHPMplus

This skill provides documented patterns and shell functions for git worktree creation and cleanup, enabling parallel task execution in the GHPMplus workflow.

## Overview

Git worktrees allow multiple working directories to be attached to a single repository, each with its own branch. GHPMplus uses worktrees to enable parallel task execution - multiple sub-agents can work on different tasks simultaneously without conflicts.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GHPMPLUS_WORKTREE_DIR` | `.worktrees` | Directory for worktree storage |
| `GHPMPLUS_MAX_PARALLEL` | `3` | Maximum concurrent worktrees |

## Naming Conventions

### Worktree Directory Naming

```
.worktrees/task-<issue_number>
```

Examples:
- `.worktrees/task-42`
- `.worktrees/task-101`

### Branch Naming

```
ghpm/task-<issue_number>-<slug>
```

Where `<slug>` is:
- Lowercase
- Spaces replaced with hyphens
- Truncated to 30 characters
- Special characters removed

Examples:
- `ghpm/task-42-implement-user-login`
- `ghpm/task-101-add-oauth-support`

## Shell Functions

### Create Worktree

```bash
# ghpmplus_worktree_create <task_number> <task_title>
#
# Creates a worktree for parallel task execution.
# Handles edge cases: existing worktree, existing branch, stale references.
#
# Returns:
#   0 - Success, worktree created
#   1 - Failure, error message printed to stderr

ghpmplus_worktree_create() {
  local task_number="$1"
  local task_title="$2"
  local worktree_dir="${GHPMPLUS_WORKTREE_DIR:-.worktrees}"
  local worktree_path="${worktree_dir}/task-${task_number}"

  # Generate branch name
  local slug=$(echo "$task_title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-30)
  local branch_name="ghpm/task-${task_number}-${slug}"

  # Ensure worktree directory exists
  mkdir -p "$worktree_dir"

  # Check if worktree already exists
  if [ -d "$worktree_path" ]; then
    echo "Worktree already exists: $worktree_path" >&2
    # Verify it's valid
    if git worktree list | grep -q "$worktree_path"; then
      echo "Using existing worktree" >&2
      echo "$worktree_path"
      return 0
    else
      # Stale directory, clean it up
      echo "Cleaning stale worktree directory" >&2
      rm -rf "$worktree_path"
    fi
  fi

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    # Branch exists, create worktree from existing branch
    git worktree add "$worktree_path" "$branch_name" 2>/dev/null || {
      echo "ERROR: Failed to create worktree from existing branch" >&2
      return 1
    }
  else
    # Create new branch and worktree
    git worktree add "$worktree_path" -b "$branch_name" 2>/dev/null || {
      echo "ERROR: Failed to create new worktree" >&2
      return 1
    }
  fi

  echo "$worktree_path"
  return 0
}
```

### Remove Worktree

```bash
# ghpmplus_worktree_remove <task_number>
#
# Removes a worktree and optionally its branch.
# Handles edge cases: worktree not found, dirty working directory.
#
# Returns:
#   0 - Success, worktree removed
#   1 - Failure, error message printed to stderr

ghpmplus_worktree_remove() {
  local task_number="$1"
  local force="${2:-false}"
  local worktree_dir="${GHPMPLUS_WORKTREE_DIR:-.worktrees}"
  local worktree_path="${worktree_dir}/task-${task_number}"

  # Check if worktree exists
  if [ ! -d "$worktree_path" ]; then
    echo "Worktree not found: $worktree_path" >&2
    return 0  # Not an error, already removed
  fi

  # Check for uncommitted changes
  if [ "$force" != "true" ]; then
    if [ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]; then
      echo "ERROR: Worktree has uncommitted changes. Use force=true to override." >&2
      return 1
    fi
  fi

  # Remove worktree
  git worktree remove "$worktree_path" --force 2>/dev/null || {
    # Manual cleanup if git worktree remove fails
    rm -rf "$worktree_path"
    git worktree prune
  }

  echo "Removed worktree: $worktree_path"
  return 0
}
```

### Cleanup All Worktrees

```bash
# ghpmplus_worktree_cleanup
#
# Removes all GHPMplus worktrees and prunes stale references.
#
# Returns:
#   0 - Success, all worktrees cleaned

ghpmplus_worktree_cleanup() {
  local worktree_dir="${GHPMPLUS_WORKTREE_DIR:-.worktrees}"

  echo "Cleaning up all GHPMplus worktrees..."

  # Remove each worktree
  for worktree in "$worktree_dir"/task-*; do
    if [ -d "$worktree" ]; then
      local task_num=$(basename "$worktree" | sed 's/task-//')
      ghpmplus_worktree_remove "$task_num" "true"
    fi
  done

  # Prune any stale worktree references
  git worktree prune

  # Remove empty worktree directory
  if [ -d "$worktree_dir" ] && [ -z "$(ls -A "$worktree_dir")" ]; then
    rmdir "$worktree_dir"
  fi

  echo "Cleanup complete"
  return 0
}
```

### List Active Worktrees

```bash
# ghpmplus_worktree_list
#
# Lists all active GHPMplus worktrees with their status.

ghpmplus_worktree_list() {
  local worktree_dir="${GHPMPLUS_WORKTREE_DIR:-.worktrees}"

  echo "Active GHPMplus Worktrees:"
  echo ""

  local count=0
  for worktree in "$worktree_dir"/task-*; do
    if [ -d "$worktree" ]; then
      local task_num=$(basename "$worktree" | sed 's/task-//')
      local branch=$(git -C "$worktree" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      local status=$(git -C "$worktree" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

      echo "  Task #${task_num}"
      echo "    Path:   $worktree"
      echo "    Branch: $branch"
      echo "    Changes: $status files"
      echo ""

      count=$((count + 1))
    fi
  done

  if [ $count -eq 0 ]; then
    echo "  (no active worktrees)"
  fi

  echo "Total: $count worktree(s)"
}
```

## Usage Examples

### Creating a Worktree for a Task

```bash
# Set up environment (optional)
export GHPMPLUS_WORKTREE_DIR=".worktrees"

# Create worktree for task #42
WORKTREE_PATH=$(ghpmplus_worktree_create 42 "Implement user login")

# Navigate to worktree
cd "$WORKTREE_PATH"

# Do work...
git add .
git commit -m "feat(auth): implement user login (#42)"
git push -u origin HEAD
```

### Cleanup After Task Completion

```bash
# Return to main repo
cd /path/to/repo

# Remove specific worktree
ghpmplus_worktree_remove 42

# Or cleanup all worktrees
ghpmplus_worktree_cleanup
```

### Checking Worktree Count Before Creating

```bash
# Check if we're at max parallel limit
MAX=${GHPMPLUS_MAX_PARALLEL:-3}
CURRENT=$(ls -d .worktrees/task-* 2>/dev/null | wc -l | tr -d ' ')

if [ "$CURRENT" -ge "$MAX" ]; then
  echo "At maximum parallel worktrees ($MAX). Wait for completion or increase limit."
  exit 1
fi
```

## Edge Case Handling

| Scenario | Behavior |
|----------|----------|
| Worktree already exists | Use existing if valid, clean and recreate if stale |
| Branch already exists | Create worktree from existing branch |
| Dirty working directory | Fail unless force=true |
| Stale git references | Auto-prune during cleanup |
| Missing worktree directory | Auto-create on first worktree |

## Integration with Orchestrator

The orchestrator uses these helpers during Phase 4 (Parallel Execution Setup):

```bash
# In orchestrator context
for task in $TASKS; do
  TASK_NUM=$(echo "$task" | cut -f1)
  TASK_TITLE=$(echo "$task" | cut -f2)

  # Create worktree
  WORKTREE=$(ghpmplus_worktree_create "$TASK_NUM" "$TASK_TITLE")

  # Spawn sub-agent to work in worktree
  # (via Task tool delegation)
done
```

And during Phase 7 (Cleanup):

```bash
# After all tasks complete
ghpmplus_worktree_cleanup
```

## Best Practices

1. **Always clean up** - Remove worktrees after PR is merged
2. **Respect limits** - Don't exceed `GHPMPLUS_MAX_PARALLEL`
3. **Check status** - Use `ghpmplus_worktree_list` to monitor active worktrees
4. **Handle failures** - If a task fails, clean its worktree before retry
5. **Don't share worktrees** - Each task should have its own worktree
