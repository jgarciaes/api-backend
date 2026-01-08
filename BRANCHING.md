# Git Branching Strategy

## Overview

We follow a **hybrid Git Flow + Trunk-Based Development** strategy optimized for CI/CD and high-velocity releases.

```
main (production)
  │
  ├─── v1.0.0 ────┬──── v1.0.1 (hotfix)
  │               │
  ├─── v1.1.0 ────┴──── v1.1.1 (hotfix)
  │
  └─── v2.0.0 (breaking change)

develop (integration/staging)
  │
  ├─ feature/oauth-support  (feat: commits → minor bump)
  ├─ feature/user-dashboard (feat: commits → minor bump)
  ├─ bugfix/null-check      (fix: commits → patch bump)
  └─ refactor/api-cleanup   (refactor: no version bump)

release/1.1.0 (release candidate)
  │
  └─ Final testing, bug fixes only

hotfix/security-patch (emergency fixes)
  │
  └─ Critical production fixes
```

## Branch Types

### 1. `main` (Protected)
- **Purpose:** Production-ready code
- **Triggers:** Docker builds, ECR pushes, deployments
- **Protection:** Requires PR approval, CI passing, no force-push
- **Version:** Always tagged (v1.0.0, v1.1.0, v2.0.0)

### 2. `develop` (Integration)
- **Purpose:** Integration branch for features
- **Triggers:** Integration tests, staging deployments
- **Protection:** Requires PR approval, CI passing
- **Version:** Pre-release tags (1.1.0-beta.1)

### 3. `feature/*` (Short-lived)
- **Purpose:** New features, enhancements
- **Naming:** `feature/oauth-support`, `feature/user-dashboard`
- **Merges to:** `develop`
- **Commits:** Use `feat:` prefix
- **Lifespan:** 1-7 days (delete after merge)

**Example:**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/oauth-support
# Work on feature
git commit -m "feat(auth): add OAuth2 Google provider"
git commit -m "test(auth): add OAuth2 integration tests"
git push origin feature/oauth-support
# Create PR to develop
```

### 4. `bugfix/*` (Short-lived)
- **Purpose:** Bug fixes for develop branch
- **Naming:** `bugfix/null-pointer-fix`, `bugfix/login-timeout`
- **Merges to:** `develop`
- **Commits:** Use `fix:` prefix
- **Lifespan:** 1-3 days

**Example:**
```bash
git checkout develop
git checkout -b bugfix/null-pointer-fix
git commit -m "fix(api): handle null user profile in /me endpoint

Added null check before accessing user.profile.
Returns 404 if profile doesn't exist.

Closes #123"
git push origin bugfix/null-pointer-fix
```

### 5. `release/*` (Temporary)
- **Purpose:** Release preparation and final testing
- **Naming:** `release/1.1.0`
- **Created from:** `develop`
- **Merges to:** `main` AND `develop`
- **Commits:** Only `fix:`, `docs:`, `chore:` (no new features)
- **Lifespan:** 1-3 days

**Workflow:**
```bash
# Create release branch
git checkout develop
git checkout -b release/1.1.0

# Pipeline auto-bumps VERSION to 1.1.0
# Deploy to staging for final testing

# Bug fixes only
git commit -m "fix(auth): increase token expiry for mobile clients"
git commit -m "docs: update API changelog for v1.1.0"

# Merge to main (creates tag v1.1.0)
git checkout main
git merge --no-ff release/1.1.0
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge --no-ff release/1.1.0
git push origin develop

# Delete release branch
git branch -d release/1.1.0
git push origin --delete release/1.1.0
```

### 6. `hotfix/*` (Emergency)
- **Purpose:** Critical production fixes
- **Naming:** `hotfix/security-patch`, `hotfix/data-corruption`
- **Created from:** `main`
- **Merges to:** `main` AND `develop`
- **Commits:** Use `fix:` with severity in description
- **Lifespan:** Hours (urgent)

**Workflow:**
```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/security-patch

# Fix the issue
git commit -m "fix(auth)!: patch SQL injection in login endpoint

SECURITY: Critical SQL injection vulnerability in username field.
Added parameterized queries and input validation.

CVSS Score: 9.8
Closes #456"

# Merge to main (triggers patch bump: 1.1.0 → 1.1.1)
git checkout main
git merge --no-ff hotfix/security-patch
git tag -a v1.1.1 -m "Hotfix: Security patch"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge --no-ff hotfix/security-patch
git push origin develop

# Delete hotfix branch
git branch -d hotfix/security-patch
```

## Version Bumping Rules

| Branch | Commit Type | Version Change | Example |
|--------|-------------|----------------|---------|
| `feature/*` → `develop` | `feat:` | None (on develop) | - |
| `develop` → `main` | `feat:` | MINOR | 1.0.0 → 1.1.0 |
| `develop` → `main` | `fix:` | PATCH | 1.0.0 → 1.0.1 |
| `develop` → `main` | `feat!:` or `BREAKING CHANGE` | MAJOR | 1.0.0 → 2.0.0 |
| `hotfix/*` → `main` | `fix:` | PATCH | 1.1.0 → 1.1.1 |
| `hotfix/*` → `main` | `fix!:` | MAJOR | 1.1.0 → 2.0.0 |

## Pre-release Versions

For testing before production:

```bash
# Alpha (early development, unstable)
git checkout develop
git tag 1.1.0-alpha.1
# Docker: api-backend:1.1.0-alpha.1

# Beta (feature complete, testing)
git tag 1.1.0-beta.1
# Docker: api-backend:1.1.0-beta.1

# Release Candidate (production-ready candidate)
git checkout release/1.1.0
git tag 1.1.0-rc.1
# Docker: api-backend:1.1.0-rc.1

# Production
git checkout main
git merge release/1.1.0
git tag v1.1.0
# Docker: api-backend:1.1.0
```

## Pull Request Requirements

### To `develop`
- [x] Conventional commits
- [x] CI passing (tests, linting, security)
- [x] Code review (1 approval)
- [x] Branch up-to-date with develop

### To `main` (via `release/*` or `hotfix/*`)
- [x] All requirements for `develop`
- [x] Staging tests passing
- [x] Release notes prepared
- [x] Version bumped correctly
- [x] 2 approvals (senior engineers)
- [x] No direct commits (must use PR)

## Automation

### On PR to `develop`
```yaml
- Run tests
- Run security scans (Semgrep, Trivy, TruffleHog)
- Run SonarQube analysis
- Preview deployment to ephemeral environment
```

### On merge to `develop`
```yaml
- Deploy to staging environment
- Run integration tests
- Build Docker image with `-beta` tag
- Push to ECR with `develop` tag
```

### On merge to `main`
```yaml
- Analyze commits (release.yml workflow)
- Auto-bump VERSION file
- Create Git tag (v1.1.0)
- Generate changelog
- Create GitHub Release
- Build Docker image (version, version-SHA, latest)
- Run Trivy security scan
- Push to ECR
- Trigger production deployment (ArgoCD/FluxCD)
```

### On `hotfix/*` → `main`
```yaml
- Same as regular main merge
- Auto-bump to patch version
- Tag as hotfix (v1.1.1)
- Alert on-call team
- Generate incident report
```

## Real-World Example: Feature → Production

```bash
# Day 1: Start feature
git checkout develop
git pull origin develop
git checkout -b feature/oauth-support
git commit -m "feat(auth): add OAuth2 configuration"
git commit -m "feat(auth): implement Google OAuth2 flow"
git commit -m "test(auth): add OAuth2 unit tests"
git push origin feature/oauth-support
# Create PR to develop

# Day 2: Merge to develop (after review)
# CI runs, staging deploys

# Day 5: Create release
git checkout develop
git pull origin develop
git checkout -b release/1.1.0
# VERSION auto-updated to 1.1.0
git push origin release/1.1.0

# Day 6: Final testing on staging
git commit -m "fix(auth): adjust OAuth2 redirect URL"
git commit -m "docs: update OAuth2 setup guide"

# Day 7: Release to production
git checkout main
git merge --no-ff release/1.1.0
git tag -a v1.1.0 -m "Release v1.1.0: OAuth2 support"
git push origin main --tags

# CI triggers:
# → Bumps VERSION to 1.1.0
# → Creates GitHub Release
# → Builds Docker: api-backend:1.1.0
# → Pushes to ECR
# → ArgoCD deploys to production

# Merge back to develop
git checkout develop
git merge --no-ff release/1.1.0
git push origin develop

# Cleanup
git branch -d release/1.1.0
git push origin --delete release/1.1.0
```

## Emergency Hotfix Example

```bash
# Critical bug discovered in production
git checkout main
git pull origin main
git checkout -b hotfix/security-patch

# Fix and commit
git commit -m "fix(auth)!: patch critical SQL injection

SECURITY: SQL injection in login endpoint.
CVSS: 9.8 (Critical)
Affected versions: 1.0.0 - 1.1.0
Fix: Parameterized queries

Closes #789
BREAKING CHANGE: Login endpoint now requires Content-Type: application/json"

# Merge to main
git checkout main
git merge --no-ff hotfix/security-patch
git tag -a v2.0.0 -m "HOTFIX: Critical security patch"
git push origin main --tags

# CI triggers immediate deployment

# Merge to develop
git checkout develop
git merge --no-ff hotfix/security-patch
git push origin develop

# Cleanup
git branch -d hotfix/security-patch
```

## Tips for Scalability

1. **Keep branches short-lived**: Max 7 days for features
2. **Rebase before merge**: `git pull --rebase origin develop`
3. **Squash feature commits**: Clean history in develop
4. **Never commit to main directly**: Always use PRs
5. **Tag every production release**: `v1.0.0`, `v1.1.0`
6. **Delete merged branches**: Keep repository clean
7. **Use draft PRs**: For work-in-progress
8. **Link PRs to issues**: Traceability

## Tools

- **Git Flow CLI**: `git flow feature start oauth-support`
- **GitHub Actions**: Automated version bumping
- **semantic-release**: Automated releases
- **commitlint**: Enforce commit messages
- **Husky**: Pre-commit hooks
