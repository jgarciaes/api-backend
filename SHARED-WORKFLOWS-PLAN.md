# Shared Workflows Repository - Implementation Plan

## Problem Statement

Currently, each repository has its own copy of the reusable Docker workflow (`.github/workflows/docker-build-push.yml`). This creates maintenance overhead:

- Changes must be replicated across 4+ repositories
- Version drift between repositories
- Difficult to enforce standards
- No single source of truth

## Solution: Shared Workflows Repository

Create a **centralized GitHub repository** that contains reusable workflows used across all projects.

---

## Repository Structure

```
project-poc-org/shared-workflows/
├── .github/workflows/
│   ├── docker-build-push.yml        # Reusable Docker build/push
│   ├── security-scan.yml             # Reusable security scanning
│   ├── sonarqube-scan.yml            # Reusable SonarQube
│   ├── semantic-release.yml          # Reusable semantic versioning
│   └── deploy-k8s.yml                # Reusable Kubernetes deployment
├── scripts/
│   ├── version-bump.sh
│   └── changelog-generator.sh
├── README.md
├── CHANGELOG.md
└── VERSION
```

---

## Implementation Steps

### Step 1: Create Shared Repository

```bash
# On GitHub: Create new repository
Organization: project-poc-org
Name: shared-workflows
Description: Centralized reusable GitHub Actions workflows
Visibility: Internal (visible to all org repos)

# Clone locally
git clone https://github.com/project-poc-org/shared-workflows.git
cd shared-workflows
```

### Step 2: Move Docker Workflow

Move `.github/workflows/docker-build-push.yml` to shared repo:

```yaml
# shared-workflows/.github/workflows/docker-build-push.yml
name: Reusable Docker Build & Push

on:
  workflow_call:
    inputs:
      app-name:
        required: true
        type: string
      app-version:
        required: true
        type: string
      dockerfile-path:
        required: false
        type: string
        default: './Dockerfile'
      build-context:
        required: false
        type: string
        default: '.'
    secrets:
      AWS_ACCESS_KEY_ID:
        required: true
      AWS_SECRET_ACCESS_KEY:
        required: true
      AWS_REGION:
        required: true

jobs:
  docker:
    name: Build & Push Docker Image
    runs-on:
      group: projects-poc
    steps:
      - uses: actions/checkout@v4
      # ... rest of workflow
```

### Step 3: Reference from Application Repos

In each application repo (api-backend, worker-service, etc):

```yaml
# api-backend/.github/workflows/pipeline.yml

jobs:
  docker:
    name: Docker Build & Push
    needs: [build, code-quality]
    if: github.ref == 'refs/heads/main'
    uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0
    #    ^^^^^^^^^^^^^^^^^^^^^^^^^^ org/repo
    #                                                                            ^^^^^^^^^ version tag
    with:
      app-name: api-backend
      app-version: ${{ needs.build.outputs.version }}
    secrets:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ secrets.AWS_REGION }}
```

**Key Points:**
- Use `@v1.0.0` tag for versioning (or `@main` for latest)
- No local `.github/workflows/docker-build-push.yml` needed
- Single source of truth

---

## Benefits

### 1. **Single Source of Truth**
- Update once, applies everywhere
- No version drift
- Consistent behavior

### 2. **Versioning**
```
@v1.0.0 - Stable production version
@v1.1.0 - New features
@main - Latest (use with caution)
```

### 3. **Easier Testing**
```
# Test changes in one repo first
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@feature-branch

# Roll out to all repos after validation
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.1.0
```

### 4. **Compliance & Auditing**
- Centralized audit logs
- Easier to enforce policies
- Clear change history

### 5. **Reusability**
```
# Same workflow used by
- api-backend
- worker-service
- website-frontend
- desktop-app
- future-service-1
- future-service-2
```

---

## Workflow Versioning Strategy

### Semantic Versioning for Workflows

```
v1.0.0 - Initial stable release
v1.1.0 - Add Trivy scanning (backward compatible)
v1.2.0 - Add multi-arch builds (backward compatible)
v2.0.0 - Change input parameters (BREAKING CHANGE)
```

### Tagging Workflow

```bash
cd shared-workflows

# Make changes
git commit -m "feat(docker): add multi-arch support"

# Create version tag
git tag -a v1.1.0 -m "Add multi-arch Docker builds"
git push origin v1.1.0

# Update all application repos to use v1.1.0
```

### Migration Strategy

```
Phase 1: api-backend uses @v1.1.0 (test)
Phase 2: worker-service uses @v1.1.0 (validate)
Phase 3: All repos upgraded to @v1.1.0
```

---

## Example: Complete Shared Workflows Setup

### Shared Workflows Repo

```yaml
# shared-workflows/.github/workflows/docker-build-push.yml
name: Docker Build & Push
on:
  workflow_call:
    inputs:
      app-name:
        required: true
        type: string
      app-version:
        required: true
        type: string
    secrets:
      AWS_ACCESS_KEY_ID:
        required: true
      AWS_SECRET_ACCESS_KEY:
        required: true
      AWS_REGION:
        required: true
jobs:
  docker:
    runs-on:
      group: projects-poc
    steps:
      - uses: actions/checkout@v4
      - name: Build & Push
        # ... implementation
```

```yaml
# shared-workflows/.github/workflows/security-scan.yml
name: Security Scan
on:
  workflow_call:
    inputs:
      scan-type:
        required: false
        type: string
        default: 'full'
jobs:
  security:
    runs-on:
      group: projects-poc
    steps:
      - uses: actions/checkout@v4
      - name: TruffleHog
        # ... implementation
      - name: Semgrep
        # ... implementation
      - name: Trivy
        # ... implementation
```

### Application Repo (api-backend)

```yaml
# api-backend/.github/workflows/pipeline.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build:
    name: Build & Test
    runs-on:
      group: projects-poc
    outputs:
      version: ${{ steps.get-version.outputs.version }}
    steps:
      - uses: actions/checkout@v4
      - name: Get version
        id: get-version
        run: echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT
      - name: Build
        run: |
          pip install -r requirements.txt
          echo "Tests pass"

  docker:
    name: Docker
    needs: build
    uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0
    with:
      app-name: api-backend
      app-version: ${{ needs.build.outputs.version }}
    secrets:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ secrets.AWS_REGION }}

  security:
    name: Security
    uses: project-poc-org/shared-workflows/.github/workflows/security-scan.yml@v1.0.0
    with:
      scan-type: 'full'
```

---

## Governance

### Who Can Modify Shared Workflows?

**CODEOWNERS** for shared-workflows repo:

```
# shared-workflows/.github/CODEOWNERS

* @jonathangarciaes @project-poc-org/sre-leads

/.github/workflows/ @jonathangarciaes @project-poc-org/devops-team
```

**Branch Protection:**
- Require 2 approvals from SRE team
- All CI checks must pass
- No force-push
- Require signed commits

### Testing Changes

1. **Create feature branch** in shared-workflows
2. **Test in one app repo** using `@feature-branch`
3. **Create PR** in shared-workflows with test results
4. **After approval, tag** as new version
5. **Roll out** to all repos gradually

---

## Migration Plan

### Current State

```
api-backend/.github/workflows/docker-build-push.yml       (copy 1)
worker-service/.github/workflows/docker-build-push.yml    (copy 2)
website-frontend/.github/workflows/docker-build-push.yml  (copy 3)
desktop-app/.github/workflows/docker-build-push.yml       (copy 4)
```

### Target State

```
shared-workflows/.github/workflows/docker-build-push.yml  (single source of truth)

api-backend/.github/workflows/pipeline.yml                (references shared)
worker-service/.github/workflows/pipeline.yml             (references shared)
website-frontend/.github/workflows/pipeline.yml           (references shared)
desktop-app/.github/workflows/pipeline.yml                (references shared)
```

### Steps

```bash
# 1. Create shared-workflows repo
# 2. Copy docker-build-push.yml to shared-workflows
# 3. Tag as v1.0.0
# 4. Update api-backend to reference @v1.0.0
# 5. Test api-backend pipeline
# 6. Update other 3 repos
# 7. Delete local copies of docker-build-push.yml
```

---

## Cost/Benefit Analysis

### Current Approach (Local Copies)

**Pros:**
- ✅ No external dependencies
- ✅ Each repo fully self-contained

**Cons:**
- ❌ Maintenance overhead (4x copies)
- ❌ Version drift
- ❌ Difficult to enforce standards
- ❌ Changes require 4 PRs

### Shared Workflows Approach

**Pros:**
- ✅ Single source of truth
- ✅ Version controlled
- ✅ Easy to update (1 PR affects all repos)
- ✅ Consistent behavior
- ✅ Easier governance

**Cons:**
- ❌ External dependency (mitigated by versioning)
- ❌ Breaking changes affect all repos (mitigated by semver)

**Recommendation:** ✅ Use shared workflows for production

---

## Real-World Examples

### Google (Monorepo)
- Uses Bazel with shared build rules
- Single source of truth for all builds

### Netflix
- Shared "Spinnaker pipelines"
- Reusable deployment workflows across 1000s of services

### Spotify
- "Golden Path" templates
- Shared workflows for all microservices

### GitHub Itself
- Uses shared workflows for internal projects
- `github/reusable-workflows` repository

---

## Next Steps

1. ✅ Fix ECR repository structure (DONE)
2. ✅ Add CODEOWNERS and governance docs (DONE)
3. ⏭️ Create `shared-workflows` repository
4. ⏭️ Move docker-build-push.yml to shared repo
5. ⏭️ Tag v1.0.0
6. ⏭️ Update all 4 app repos to reference shared workflow
7. ⏭️ Test end-to-end
8. ⏭️ Add more shared workflows (security, sonarqube, etc)

---

**This is how big tech scales DevOps to 1000s of repositories!**
