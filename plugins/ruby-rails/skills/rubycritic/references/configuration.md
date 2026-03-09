# RubyCritic Configuration

## Configuration File

Create `.rubycritic.yml` in project root:

```yaml
minimum_score: 95
formats:
  - console
paths:
  - 'app/'
  - 'lib/'
exclude_paths:
  - 'db/migrate/**/*'
  - 'config/**/*'
  - 'vendor/**/*'
no_browser: true
```

## Key Options

| Option | Description |
|--------|-------------|
| `minimum_score` | Fail if score below threshold (0-100) |
| `formats` | Output: `console`, `html`, `json` |
| `paths` | Directories to analyze |
| `exclude_paths` | Glob patterns to skip |
| `no_browser` | Don't auto-open HTML report |
| `mode` | `default` or `ci` (compare against branch) |
| `branch` | Branch to compare in CI mode |

## Common Configurations

**Strict (new projects)**:
```yaml
minimum_score: 95
```

**CI/CD**:
```yaml
minimum_score: 90
mode: ci
branch: main
formats: [json, console]
```

**Legacy codebase**:
```yaml
minimum_score: 70
exclude_paths:
  - 'lib/legacy/**/*'
```

## CLI Options

```bash
rubycritic --minimum-score 90 app/
rubycritic --format html app/
rubycritic --mode-ci --branch main app/
rubycritic --no-browser app/
```

## Score Calculation

RubyCritic combines three tools:
- **Reek** - code smell detection (40% weight)
- **Flog** - complexity analysis (30% weight)
- **Flay** - duplication detection (30% weight)

Recommended thresholds by project maturity:
- New projects: 95+
- Active development: 90+
- Established: 85+
- Legacy: 70+ (with improvement plan)

## Permanent Exclusions

Paths that typically shouldn't be analyzed:

```yaml
exclude_paths:
  - 'db/migrate/**/*'
  - 'db/schema.rb'
  - 'config/**/*'
  - 'vendor/**/*'
  - 'bin/**/*'
  - 'spec/fixtures/**/*'
```
