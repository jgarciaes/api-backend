# Conventional Commits Specification

This project follows [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat:` - New feature (triggers MINOR version bump: 1.0.0 → 1.1.0)
- `fix:` - Bug fix (triggers PATCH version bump: 1.0.0 → 1.0.1)
- `docs:` - Documentation only changes
- `style:` - Code style changes (formatting, missing semi-colons, etc)
- `refactor:` - Code change that neither fixes a bug nor adds a feature
- `perf:` - Performance improvements
- `test:` - Adding or correcting tests
- `chore:` - Changes to build process, auxiliary tools, libraries
- `ci:` - CI/CD pipeline changes

### Breaking Changes

Add `BREAKING CHANGE:` in footer or `!` after type to trigger MAJOR version bump (1.0.0 → 2.0.0)

```bash
feat!: redesign API authentication

BREAKING CHANGE: JWT tokens now require 'aud' claim
```

## Examples

### Feature (Minor bump)
```bash
git commit -m "feat(auth): add OAuth2 support

Implement OAuth2 authentication flow with Google provider.
Includes token refresh and revocation endpoints."
```

### Bug Fix (Patch bump)
```bash
git commit -m "fix(api): handle null pointer in user profile endpoint

Closes #123"
```

### Breaking Change (Major bump)
```bash
git commit -m "feat(api)!: change response format to JSON:API spec

BREAKING CHANGE: All API responses now follow JSON:API specification.
Clients must update to parse new response structure.

Closes #456"
```

### Non-versioned commits
```bash
git commit -m "docs: update API documentation"
git commit -m "ci: add caching to Docker builds"
git commit -m "chore: update dependencies"
```

## Versioning Rules

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `feat:` | MINOR | 1.0.0 → 1.1.0 |
| `fix:` | PATCH | 1.0.0 → 1.0.1 |
| `BREAKING CHANGE:` | MAJOR | 1.0.0 → 2.0.0 |
| `docs:`, `chore:`, `ci:` | NONE | No version change |

## Pre-release Versions

For development and staging:

```bash
# Alpha release (early testing)
1.1.0-alpha.1
1.1.0-alpha.2

# Beta release (feature complete, testing)
1.1.0-beta.1
1.1.0-beta.2

# Release Candidate (production-ready testing)
1.1.0-rc.1
1.1.0-rc.2

# Production release
1.1.0
```

## Branch Strategy

```
main (production)
  ├─ develop (integration)
  │   ├─ feature/oauth-support
  │   ├─ feature/user-dashboard
  │   └─ bugfix/null-pointer-fix
  └─ release/1.1.0 (release preparation)
  └─ hotfix/critical-security-fix (emergency fixes)
```

### Workflow

1. **Feature Development**: Branch from `develop`
   ```bash
   git checkout -b feature/oauth-support develop
   git commit -m "feat(auth): add OAuth2 support"
   git push origin feature/oauth-support
   # Create PR to develop
   ```

2. **Release Preparation**: Branch from `develop`
   ```bash
   git checkout -b release/1.1.0 develop
   # Pipeline auto-bumps version to 1.1.0
   # Test, fix bugs (fix: commits only)
   git checkout main
   git merge release/1.1.0
   git tag v1.1.0
   ```

3. **Hotfix**: Branch from `main`
   ```bash
   git checkout -b hotfix/security-patch main
   git commit -m "fix(auth)!: patch SQL injection vulnerability"
   # Pipeline auto-bumps to 1.1.1
   git checkout main
   git merge hotfix/security-patch
   git tag v1.1.1
   git checkout develop
   git merge hotfix/security-patch
   ```

## Tooling

- **commitlint**: Enforce commit message format
- **semantic-release**: Automated versioning and releases
- **conventional-changelog**: Generate CHANGELOG.md
- **husky**: Git hooks for pre-commit validation

## GitHub Protection Rules

- `main`: Requires PR approval, CI passing, no force-push
- `develop`: Requires PR approval, CI passing
- `feature/*`: No restrictions
- `release/*`: Requires PR approval
- `hotfix/*`: Requires PR approval

## Release Process

1. Merge to `main` branch
2. CI analyzes commits since last release
3. Determines version bump (major/minor/patch)
4. Updates VERSION file
5. Creates Git tag (v1.1.0)
6. Builds Docker image (1.1.0, 1.1.0-commitSHA, latest)
7. Generates CHANGELOG.md
8. Creates GitHub Release with notes
9. Pushes to ECR
10. Triggers deployment pipeline

## Tools Integration

```yaml
# .github/workflows/release.yml
- Analyze commits
- Bump VERSION
- Create Git tag
- Build Docker image
- Push to ECR
- Create GitHub Release
- Update CHANGELOG.md
```
