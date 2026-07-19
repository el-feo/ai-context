# fowler

A refactoring advisor grounded in Martin Fowler's *Refactoring: Improving the
Design of Existing Code* (2nd edition). It diagnoses code smells, applies
catalog refactorings using their step-by-step mechanics — small
behavior-preserving steps with tests between them — and teaches when and why to
use each of the 64 catalog techniques. Language-agnostic: the discipline applies
to Ruby, JavaScript, Python, or anything else with functions and objects.

## Installation

```bash
# Add the marketplace (from GitHub)
/plugin marketplace add el-feo/ai-context

# Install the plugin
/plugin install fowler@jebs-dev-tools

# Or use the plugin directory directly
cc --plugin-dir /path/to/ai-context/plugins/fowler
```

## Usage

### Command

```text
/fowler [diagnose|refactor|advise] <code, file paths, a refactoring name, or a question>
```

The mode keyword is optional — the skill auto-detects intent:

```text
/fowler app/services/invoice_builder.rb            # diagnose smells
/fowler extract class on app/models/user.rb        # guided refactoring
/fowler when should I use Split Phase?             # advice/teaching
```

### Skill trigger

The skill also activates without the command whenever you ask to refactor,
clean up, or restructure code, mention a code smell or a catalog refactoring by
name, or wrestle with code that's hard to read or change.

## The three modes

| Mode | What it does |
| --- | --- |
| **DIAGNOSE** | Finds code smells by their catalog names and prescribes the refactorings that cure them, ranked by payoff |
| **REFACTOR** | Applies a refactoring following its catalog mechanics — one small step at a time, tests between steps, never mixing behavior change with structure change |
| **ADVISE** | Explains and compares techniques: motivation, trade-offs, inverses, and when *not* to refactor |

## What's inside

```text
fowler/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   └── fowler.md                # /fowler — thin wrapper that engages the skill
└── skills/
    └── fowler/
        ├── SKILL.md             # Modes, discipline, and catalog index
        └── references/
            ├── principles.md    # Two hats, when (not) to refactor, testing discipline
            ├── smells.md        # All 24 code smells → curing refactorings
            ├── first-set.md     # Extract Function, Rename Variable, Split Phase…
            ├── encapsulation.md # Encapsulate Record, Extract Class, Hide Delegate…
            ├── moving-features.md # Move Function, Split Loop, Replace Loop with Pipeline…
            ├── organizing-data.md # Split Variable, Change Reference to Value…
            ├── conditional-logic.md # Guard Clauses, Replace Conditional with Polymorphism…
            ├── apis.md          # Remove Flag Argument, Preserve Whole Object…
            └── inheritance.md   # Pull Up Method, Replace Subclass with Delegate…
```

The reference files are original distillations of the catalog — condensed
motivations, mechanics, and pitfalls in this plugin's own words and examples —
not reproductions of the book. Buy the book; it's worth it.
