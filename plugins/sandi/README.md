# sandi

An object-oriented design advisor for Claude Code, channeling Sandi Metz's
philosophy (from *Practical Object-Oriented Design in Ruby* and *99 Bottles of
OOP*). The north star is always **code that is easy to change.**

The skill is language-agnostic — the principles come from Ruby books but apply to
any OO language (JavaScript/TypeScript, Python, Java, C#, Swift, etc.).

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install sandi@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/sandi
```

## Usage

### Command

```text
/sandi [plan|review|refactor|advise (optional)] <your request, code, PRD, or question>
```

`/sandi` auto-detects which of four modes fits your request and responds in that
mode. You can prefix an explicit mode word to force one.

### Skill (1)

- **sandi** — Triggers on the `/sandi` command, or whenever you ask about
  object-oriented design, software architecture, how to structure or plan a
  feature, refactoring, code review of classes/objects, dependency management,
  code smells, SOLID, design patterns, duck typing, or mention Sandi Metz,
  POODR, "99 Bottles", "shameless green", "flocking rules", the "squint test",
  the "Law of Demeter", or "tell don't ask".

## The four modes

| Your request is about… | Mode | Example |
|---|---|---|
| Planning/architecting a feature from a PRD or spec, greenfield design | **PLAN** | "How should I structure a notifications system?" |
| Reviewing a PR, a class, or existing code | **REVIEW** | "Is this service object any good?" |
| Improving code that already works | **REFACTOR** | "DRY up this duplicated logic" |
| Understanding a concept or tradeoff | **ADVISE** | "When should I use duck typing?" |

Modes compose — it's fine to review and then flow into refactoring.

## What's inside

```text
sandi/
├── commands/sandi.md          # /sandi slash command
└── skills/sandi/
    ├── SKILL.md               # shared foundation + mode selection
    └── references/
        ├── planning.md        # PLAN mode procedure
        ├── review.md          # REVIEW mode procedure
        ├── refactoring.md     # flocking rules, 99 Bottles, code-smell catalog
        ├── principles.md      # deep treatment of every core principle
        └── teaching.md        # ADVISE mode: Socratic explanation of tradeoffs
```
