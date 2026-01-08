# Shared Workflows Repository Setup Guide

## Step-by-Step Implementation

### Step 1: Create GitHub Repository

**On GitHub:**
1. Go to: https://github.com/organizations/project-poc-org
2. Click **"New repository"**
3. Configure:
   ```
   Repository name: shared-workflows
   Description: Centralized reusable GitHub Actions workflows for all projects
   Visibility: Internal (✅ Visible to all org repos)
   Initialize: ✅ Add README
   .gitignore: None
   License: MIT (or your org standard)
   ```
4. Click **"Create repository"**

### Step 2: Clone and Setup Local Repository

```bash
cd /home/ubuntu
git clone https://github.com/project-poc-org/shared-workflows.git
cd shared-workflows
```

### Step 3: Create Directory Structure

```bash
# Create directory structure
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p docs

# Create VERSION file
echo "1.0.0" > VERSION
```

### Step 4: Copy Docker Workflow

```bash
# Copy the Docker workflow from api-backend
cp /home/ubuntu/api-backend/.github/workflows/docker-build-push.yml \
   /home/ubuntu/shared-workflows/.github/workflows/docker-build-push.yml
```

### Step 5: Create README.md

```bash
cat > README.md << 'EOF'
# Shared Workflows

Centralized reusable GitHub Actions workflows for project-poc-org.

## Available Workflows

### docker-build-push.yml

Builds and pushes Docker images to AWS ECR with semantic versioning.

**Usage:**

```yaml
jobs:
  docker:
    uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0
    with:
      app-name: api-backend
      app-version: 1.0.0
    secrets:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ secrets.AWS_REGION }}
```

## Versioning

We use semantic versioning for workflows:

- **v1.0.0** - Initial stable release
- **v1.1.0** - New features (backward compatible)
- **v2.0.0** - Breaking changes

**Always pin to a specific version** (e.g., `@v1.0.0`) in production.

## Contributing

Changes to workflows require review from DevOps team.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
EOF
```

### Step 6: Create CODEOWNERS

```bash
cat > .github/CODEOWNERS << 'EOF'
# Shared Workflows - DevOps/SRE Team Ownership

# Default: DevOps Lead approves all changes
* @jonathangarciaes

# Workflows require senior SRE approval
/.github/workflows/ @jonathangarciaes

# Scripts require DevOps team approval
/scripts/ @jonathangarciaes

# Documentation can be updated by anyone
*.md
/docs/
EOF
```

### Step 7: Commit Initial Version

```bash
cd /home/ubuntu/shared-workflows

git add -A
git commit -m "feat: initial shared workflows repository

- Add docker-build-push.yml reusable workflow
- Add README with usage documentation
- Add CODEOWNERS for governance
- Set VERSION to 1.0.0"

git push origin main
```

### Step 8: Create Version Tag

```bash
# Create and push version tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial stable release

- Docker build and push to ECR
- Trivy security scanning
- Semantic versioning support"

git push origin v1.0.0
```

### Step 9: Update api-backend to Use Shared Workflow

**Edit:** `/home/ubuntu/api-backend/.github/workflows/pipeline.yml`

**Change:**
```yaml
# OLD (local workflow)
uses: ./.github/workflows/docker-build-push.yml

# NEW (shared workflow)
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0
```

**Full example:**
```yaml
docker:
  name: Docker Build & Push
  needs: [build, code-quality]
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0
  with:
    app-name: api-backend
    app-version: ${{ needs.build.outputs.version }}
    dockerfile-path: ./Dockerfile
    build-context: .
  secrets:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_REGION: ${{ secrets.AWS_REGION }}
```

### Step 10: Test with api-backend

```bash
cd /home/ubuntu/api-backend

# Update pipeline to use shared workflow
# (see step 9 above)

# Commit and push
git add .github/workflows/pipeline.yml
git commit -m "feat(ci): migrate to shared workflows repository

Use centralized docker-build-push.yml from shared-workflows@v1.0.0
for better maintainability and consistency across projects."

git push origin main
```

**Watch the pipeline run and verify it works!**

### Step 11: Remove Local Workflow (After Testing)

```bash
cd /home/ubuntu/api-backend

# Once confirmed working, delete local copy
git rm .github/workflows/docker-build-push.yml

git commit -m "chore: remove local docker-build-push.yml

Now using shared workflow from project-poc-org/shared-workflows@v1.0.0"

git push origin main
```

### Step 12: Roll Out to Other Repos

Repeat steps 9-11 for:
- worker-service
- website-frontend
- desktop-app

---

## Updating Shared Workflows

### Making Changes

```bash
cd /home/ubuntu/shared-workflows

# Create feature branch
git checkout -b feature/add-multi-arch-builds

# Make changes to workflow
vim .github/workflows/docker-build-push.yml

# Commit
git commit -m "feat(docker): add multi-architecture build support

Support building for linux/amd64 and linux/arm64"

git push origin feature/add-multi-arch-builds
```

### Testing Changes

**Test in one repo first:**

```yaml
# In api-backend/.github/workflows/pipeline.yml
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@feature/add-multi-arch-builds
#                                                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ test branch
```

### Releasing New Version

```bash
cd /home/ubuntu/shared-workflows

# Merge feature branch
git checkout main
git merge feature/add-multi-arch-builds

# Bump VERSION
echo "1.1.0" > VERSION

# Commit version bump
git commit -am "chore(release): bump version to 1.1.0"

# Create tag
git tag -a v1.1.0 -m "Release v1.1.0: Multi-architecture support"

git push origin main --tags
```

### Rolling Out to All Repos

Update each repo to use new version:

```yaml
# Change from
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0

# To
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.1.0
```

---

## Branch Protection

**GitHub Settings → Branches → Add Rule for `main`:**

```
Branch name pattern: main

✅ Require pull request reviews before merging
   └─ Required approvals: 2
   └─ Require review from Code Owners: Yes

✅ Require status checks to pass before merging

✅ Require conversation resolution

✅ Require signed commits

❌ Allow force pushes

❌ Allow deletions
```

---

## Quick Reference

### Directory Structure

```
shared-workflows/
├── .github/
│   ├── CODEOWNERS
│   └── workflows/
│       ├── docker-build-push.yml      ← Main workflow
│       ├── security-scan.yml          ← Future
│       └── k8s-deploy.yml             ← Future
├── scripts/
│   └── version-bump.sh                ← Helper scripts
├── docs/
│   └── docker-workflow.md             ← Detailed docs
├── README.md
├── VERSION
└── CHANGELOG.md
```

### Version Tags

```bash
# List all versions
git tag -l

# Check current version
cat VERSION

# Create new version
echo "1.2.0" > VERSION
git commit -am "chore(release): bump to v1.2.0"
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin main --tags
```

### Usage in Application Repos

```yaml
# Always use tagged version in production
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@v1.0.0

# Use branch for testing only
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@feature-branch

# Never use @main in production (unpredictable)
uses: project-poc-org/shared-workflows/.github/workflows/docker-build-push.yml@main  # ❌ Don't do this
```

---

## Benefits Recap

✅ **Single Source of Truth** - One workflow, used by all repos
✅ **Versioned** - Safe rollouts with semver
✅ **Tested** - Test in one repo before rolling out
✅ **Governed** - CODEOWNERS ensures proper review
✅ **Scalable** - Works for 4 repos or 400 repos
✅ **Auditable** - Clear change history
✅ **Maintainable** - Update once, affects all

---

## Next Steps

1. ✅ Create `shared-workflows` repository on GitHub
2. ✅ Copy docker-build-push.yml and commit
3. ✅ Tag as v1.0.0
4. ✅ Update api-backend to reference @v1.0.0
5. ✅ Test api-backend pipeline
6. ✅ Roll out to other 3 repos
7. ✅ Delete local workflow copies
8. ⏭️ Add more shared workflows (security, k8s-deploy, etc)

**You're implementing production-grade DevOps! 🚀**
EOF
