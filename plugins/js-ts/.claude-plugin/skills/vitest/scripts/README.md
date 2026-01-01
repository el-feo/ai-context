# Vitest Migration Scripts

Automated scripts for migrating from Jest to Vitest.

## Available Scripts

### quick-migrate.sh

Fast, simple migration for straightforward projects.

**Usage:**
```bash
chmod +x quick-migrate.sh
./quick-migrate.sh
```

**Time:** ~30 seconds

**Best for:**
- Simple projects
- Learning Vitest
- Quick experiments

### comprehensive-migrate.sh

Full-featured migration with validation and project detection.

**Usage:**
```bash
chmod +x comprehensive-migrate.sh
./comprehensive-migrate.sh
```

**Time:** 5-10 minutes

**Best for:**
- Production projects
- Complex setups
- Team migrations

## Documentation

Full documentation available in:
- [MIGRATION_SCRIPT.md](../references/MIGRATION_SCRIPT.md) - Usage guide
- [MIGRATION.md](../references/MIGRATION.md) - Complete migration reference
- [SKILL.md](../SKILL.md) - Main skill documentation

## Requirements

- Git initialized
- Node.js and npm
- Jest currently installed
- Tests passing

## Quick Start

```bash
# 1. Copy script to your project
cp comprehensive-migrate.sh /path/to/your/project/

# 2. Make executable
chmod +x comprehensive-migrate.sh

# 3. Run migration
./comprehensive-migrate.sh
```

## Support

For issues, see troubleshooting in [MIGRATION_SCRIPT.md](../references/MIGRATION_SCRIPT.md).
