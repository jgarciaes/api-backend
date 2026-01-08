# Git Commit Message Validation

This directory contains Git hooks for enforcing Conventional Commits.

## Installation

To enable commit message validation, install the hook:

```bash
# From repository root
ln -sf ../../scripts/commit-msg.sh .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
```

## What it does

- Validates commit messages against Conventional Commits format
- Warns about breaking changes
- Provides helpful error messages with examples
- Skips validation for merge commits and reverts

## Bypass (emergency only)

If you absolutely must bypass validation:

```bash
git commit --no-verify -m "emergency fix"
```

**Note:** CI will still enforce conventional commits, so bypassing locally may cause pipeline failures.
