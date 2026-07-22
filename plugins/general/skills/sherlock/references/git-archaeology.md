# Git Archaeology — Command Reference

A toolkit for extracting history-based evidence about a codebase before (or during) reading its code. Inspired by Drew Piechowski's "5 Git Commands I Run Before Reading Any Code", expanded with commands specifically useful for bug investigation.

Not every command belongs in every investigation. Pick the ones that answer a question you actually have. Running commands for their own sake is noise.

---

## Table of contents

1. [Scoped-to-the-bug commands](#scoped-to-the-bug-commands) — the ones you'll reach for most during an investigation
2. [Repo-health commands](#repo-health-commands) — the five from the original article, useful for broader context
3. [Reading git output](#reading-git-output) — what the signals actually mean

---

## Scoped-to-the-bug commands

These answer questions about the specific files, functions, and code paths implicated in the issue.

### Recent changes to the scope

Anything touched recently is suspect, especially if the issue's first-seen timestamp is recent.

```bash
git log --since="3 months ago" --oneline -- <candidate-files>
git log --since="3 months ago" --stat -- <candidate-files>   # with file change sizes
git log -p --since="3 months ago" -- <single-file>           # full diffs
```

Adjust the `--since` window to match when the bug started appearing. If the issue says "started Tuesday", use `--since="1 week ago"`.

### Pickaxe: when did this exact string appear or disappear

Finds commits that *added or removed* the given string. Excellent for locating the commit that introduced an error message, config key, function name, or SQL snippet.

```bash
git log -S "<exact-string>" --oneline --all
git log -S "<exact-string>" -p --all            # with the diffs showing context
git log -S "<exact-string>" -p -- <file-glob>   # scoped to files
```

`-G "<regex>"` is the regex variant — use it for patterns (`-G "class\s+FooBar"`).

**Common uses in bug investigation:**
- Error message from a stack trace → when/where it was introduced
- Config flag name → when it was added, last changed
- Function that shouldn't exist anymore → when it was removed (try with `--all`)

### Line-range history

Follows a specific function (or line range) through its full history, including renames.

```bash
git log -L :<functionName>:<path/to/file>
git log -L <start>,<end>:<path/to/file>
```

Shows every commit that modified the named function with the diff. Especially useful when you know *which function* is suspicious but not *when* it last changed meaningfully.

### Blame with move- and whitespace-tracking

Default `git blame` is naive — it attributes lines to the commit that last touched them, even if that was a whitespace reformat or a code move. This variant is much more informative:

```bash
git blame -w -C -C -C <path/to/file>
```

- `-w` ignores whitespace changes
- `-C -C -C` tracks code movement within the file, between files in the same commit, and across any commits (progressively more aggressive)

For a specific line range: `git blame -L 45,80 -w -C -C -C <file>`.

### Churn inside the scope

Files that churn a lot often contain bugs (the Microsoft Research result cited in the Piechowski article). Inside your candidate set, a file with disproportionate churn deserves extra attention.

```bash
git log --format=format: --name-only --since="1 year ago" -- <candidate-files> | sort | uniq -c | sort -nr
```

### Bug-message hotspots in the scope

Has this area been patched for bugs before? What kind?

```bash
git log -i -E --grep='fix|bug|broken|regression|patch' --oneline -- <candidate-files>
git log -i -E --grep='fix|bug|broken|regression|patch' -p -- <candidate-file>  # with diffs
```

Read the commit messages — if you see "fix null check in X" appearing three times on different years, that area has a known pattern of defects.

### Firefighting signals

Reverts and hotfixes near the scope indicate an unstable area.

```bash
git log --oneline -i -E --grep='revert|hotfix|emergency|rollback' -- <candidate-files>
```

A revert near your scope is a direct lead — read both the revert commit and the commit it reverted.

### Related commits across the whole repo

Search commit messages for concepts from the issue. Useful when the scope is fuzzy or when similar bugs may have been fixed elsewhere.

```bash
git log -i --grep="<concept-word-from-issue>" --oneline
git log -i --grep="<concept-word>" --since="1 year ago" --stat
```

Examples of useful concept words: the feature name, the name of the user-facing object, the symptom ("timeout", "duplicate", "encoding"), the environment ("staging", "prod").

### Regression origin via bisect

If the issue says "worked before, broke after date/version X", bisect narrows the introducing commit.

```bash
git bisect start
git bisect bad <known-bad-commit>      # often HEAD
git bisect good <known-good-commit>    # the last version where it worked
# Then for each commit git checks out, either run an automated test
# or manually reproduce and run:
git bisect good   # or: git bisect bad
git bisect reset  # when done
```

Automation with `git bisect run <script>` is powerful — the script should exit 0 for good, non-zero for bad, and 125 to skip a commit that can't be tested. In practice, writing a reliable reproducer script is often the hard part of a bisect.

If a bisect is impractical (no reproducer, too expensive to test each commit), note in the report that bisect is a recommended next step and provide the candidate range.

### Merge commits in the scope

Sometimes a bug is introduced not by a direct commit but by a bad merge.

```bash
git log --merges --oneline --since="3 months ago" -- <candidate-files>
git log --first-parent --oneline --since="3 months ago" -- <candidate-files>  # main-branch view
```

### Show a specific commit in full

```bash
git show <sha>              # message + diff
git show --stat <sha>       # message + file list
git show <sha> -- <file>    # just the diff for one file
```

---

## Repo-health commands

The five commands from the Piechowski article. These give a broader picture of the codebase's condition. Useful for context but less directly tied to a specific bug — include them in the investigation only when relevant.

### 1. Highest-churn files (last year)

```bash
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```

The top 20 most-changed files. Cited Microsoft Research finding: churn predicts defects more reliably than complexity alone. If a candidate file is in this top-20, that's meaningful context.

### 2. Contributor concentration (bus factor)

```bash
git shortlog -sn --no-merges
git shortlog -sn --no-merges --since="6 months ago"   # recent activity only
```

Red flags: one person >60% of commits, key contributors absent for 6+ months, many historical contributors but only a handful recently active. Relevant for investigation when the suspect code has a narrow set of authors who may or may not still be around to consult.

### 3. Bug hotspots (repo-wide)

```bash
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

The files that appear most often in bug-fix commits. Cross-reference with the churn list — files that are both high-churn *and* high-bug are "the risky ones".

### 4. Project velocity

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

Commit counts per month. Steady rhythm suggests a healthy team; sharp drops or cliffs may explain why an area feels neglected.

### 5. Firefighting across the repo

```bash
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```

High counts indicate deploys lack confidence. Zero counts may mean stability *or* poor commit-message discipline — interpret alongside other signals.

---

## Reading git output

A few interpretation notes that tend to trip people up:

**Churn alone doesn't mean bad code.** Configuration files, dependency manifests, and translation files churn legitimately. The signal is churn *combined with* complexity, bug-fix density, or recent incidents.

**Blame is provenance, not blame.** `git blame` answers *when* and *by whom* a line was last changed — not whether that change caused the bug. A line untouched for five years can still be where the bug manifests.

**Absence of bug-fix commits doesn't mean no bugs.** It may mean commit messages don't use words like "fix" or "bug". Look at the actual diffs of recent commits, not only the messages.

**Commit messages lie (or at least flatter).** Engineers (and AI assistants) write commit messages after the fact; they describe what the author *thinks* they did. For load-bearing claims, read the diff, not the message.

**The first-plausible commit is rarely the root.** Pickaxe may show a suspicious commit that introduced the string — but the bug might predate it and the commit merely exposed it. Treat every archaeological finding as a hypothesis to verify against the code's actual behavior.

**Don't trust tags/releases alone for "when did this break".** A user saying "it broke on Tuesday" may mean "I noticed on Tuesday". The actual regression may be older. Cross-reference with Sentry/Honeybadger first-seen timestamps when available.
