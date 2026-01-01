# devops

DevOps and infrastructure toolkit for Claude Code.

## Installation

```bash
# From GitHub
/plugin marketplace add el-feo/ai-context
/plugin install devops@jebs-dev-tools

# Or use directly
cc --plugin-dir /path/to/plugins/devops
```

## Features

### Skills (3)
- **github-actions** - CI/CD workflow creation and optimization
- **kamal** - Docker deployment configuration with Kamal
- **tailscale** - VPN setup and configuration

### Commands (1)
- `/github-actions` - Create or evaluate GitHub Actions workflows

## Usage

Skills trigger automatically when working on deployment, CI/CD, or VPN topics. Use the github-actions command for workflow creation:

```
/github-actions
```
