#!/bin/bash
# Pre-commit hook to validate commit messages follow Conventional Commits
# Install: ln -s ../../scripts/commit-msg.sh .git/hooks/commit-msg

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Conventional Commits regex pattern
PATTERN="^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\(.+\))?(!)?: .{1,}$"

# Skip for merge commits, revert commits, and [skip ci] commits
if [[ "$COMMIT_MSG" =~ ^Merge|^Revert|^\[skip\ ci\] ]]; then
    exit 0
fi

# Validate commit message
if [[ ! "$COMMIT_MSG" =~ $PATTERN ]]; then
    echo "❌ ERROR: Commit message does not follow Conventional Commits format!"
    echo ""
    echo "Expected format: <type>(<scope>): <subject>"
    echo ""
    echo "Valid types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert"
    echo ""
    echo "Examples:"
    echo "  feat(auth): add OAuth2 support"
    echo "  fix(api): handle null pointer exception"
    echo "  docs: update API documentation"
    echo "  feat(api)!: breaking change with exclamation"
    echo ""
    echo "Your commit message:"
    echo "  $COMMIT_MSG"
    echo ""
    echo "See CONTRIBUTING.md for full specification."
    exit 1
fi

# Check for breaking changes
if [[ "$COMMIT_MSG" =~ BREAKING[[:space:]]CHANGE ]] || [[ "$COMMIT_MSG" =~ ! ]]; then
    echo "⚠️  WARNING: This commit contains BREAKING CHANGES"
    echo "This will trigger a MAJOR version bump (X.0.0)"
fi

exit 0
