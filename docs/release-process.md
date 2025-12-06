# Release Process Guide

This document describes the release process for the Chatwoot-BR fork.

## Version Numbering

We follow [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH):

- **MAJOR** (v5.0.0): Breaking changes that require user intervention
- **MINOR** (v4.9.0): New features, backward compatible changes
- **PATCH** (v4.8.1): Bug fixes, security patches, backward compatible

### When to Bump Each Version

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Breaking API changes | MAJOR | Removing endpoints, changing request/response format |
| New features | MINOR | New API endpoints, new functionality |
| Bug fixes | PATCH | Fixing crashes, correcting behavior |
| Security fixes | PATCH | Vulnerability patches |
| Dependency updates (breaking) | MAJOR | New Ruby/Node version requirement |
| Dependency updates (non-breaking) | PATCH | Library updates without API changes |

## Fork Versioning

This repository is a fork of [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot). We use a versioning scheme that tracks both upstream versions and our fork-specific changes.

### Version Format

```
v{MAJOR}.{MINOR}.{PATCH}+{FORK_REV}
```

Where:
- `{MAJOR}.{MINOR}.{PATCH}` - The upstream version we're based on
- `+{FORK_REV}` - Our fork revision number (1, 2, 3, ...)

### Examples

| Version | Meaning |
|---------|---------|
| `v4.8.0+1` | First fork release based on upstream v4.8.0 |
| `v4.8.0+2` | Second fork release (our changes on top of v4.8.0) |
| `v4.9.0+1` | First fork release after syncing to upstream v4.9.0 |

### Release Types

**Fork-only Release** (increment fork revision):
- Making our own bug fixes, features, or improvements
- `v4.8.0+1` → `v4.8.0+2`

**Upstream Sync Release** (reset fork revision to 1):
- Merging changes from upstream repository
- `v4.8.0+2` → `v4.9.0+1` (after syncing to upstream v4.9.0)

### Version Precedence

Per [SemVer 2.0](https://semver.org/), build metadata (`+...`) is ignored for precedence comparison. This means `v4.8.0` and `v4.8.0+1` are considered equal for dependency resolution. This is acceptable since we control our own deployments.

### Docker Tag Conversion

Docker tags don't support the `+` character, so GitHub Actions automatically converts `+` to `-`:

| Git Tag | Docker Tag |
|---------|------------|
| `v4.8.0+1` | `v4.8.0-1` |
| `v4.8.0+2` | `v4.8.0-2` |

When pulling Docker images, use the `-` format:
```bash
docker pull ghcr.io/chatwoot-br/chatwoot:v4.8.0-1
```

## Files to Update

When releasing a new version, you must update these files:

### 1. Application Version (`VERSION_CW`)

Plain version with fork revision using `+`:
```
4.8.0+1
```

**Location**: Line 1

### 2. Control Tool Version (`VERSION_CWCTL`)

Plain version with fork revision using `+`:
```
4.8.0+1
```

**Location**: Line 1

### 3. Package Version (`package.json`)

Base version only (npm doesn't support `+`):
```json
{
  "version": "4.8.0"
}
```

**Location**: Line 3

### 4. Helm Chart Version (`charts/chatwoot/Chart.yaml`)

```yaml
# Chart version (upstream version)
version: 4.8.0

# Application version (fork version with - for Docker)
appVersion: "v4.8.0-1"
```

**Locations**: Lines 32 and 35

**Note**: The `version` field uses the upstream version (for Helm chart compatibility). The `appVersion` field uses the fork version format with `-` (for Docker tag compatibility).

### 5. Helm Values (`charts/chatwoot/values.yaml`)

```yaml
image:
  tag: v4.8.0-1
```

**Location**: Line 7

### 6. Changelog (`CHANGELOG.md`)

Add a new section at the top following the format:

```markdown
## [v4.8.0+1] - 2025-12-06 (Based on upstream v4.8.0)

### Fork Changes
- Description of fork-specific changes

### Upstream Changes
- Changes inherited from upstream (if syncing)
```

For fork-only releases:

```markdown
## [v4.8.0+2] - 2025-12-07

### Fork Changes
- Description of fork-specific changes
```

## Release Steps

### Prerequisites

- Clean working directory (commit all changes)
- All tests passing: `bundle exec rspec` and `pnpm test`
- Linting clean: `pnpm eslint` and `bundle exec rubocop -a`
- Updated dependencies: `bundle install && pnpm install`

### Step-by-Step Process

#### 1. Determine Version Number

First, identify what type of release this is:

```bash
# Check current version
git describe --tags --abbrev=0

# Review changes since last release
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Check if upstream has new releases
git fetch upstream
git log upstream/master --oneline -5
```

**Determine release type:**
- **Upstream sync**: If merging upstream changes → use upstream version + reset fork rev to 1
- **Fork-only**: If only our changes → keep upstream version + increment fork rev

**Examples:**
- Current: `v4.8.0+1`, upstream sync to v4.9.0 → New: `v4.9.0+1`
- Current: `v4.8.0+1`, our own changes → New: `v4.8.0+2`

#### 2. Update Version Files

```bash
# Update VERSION_CW (line 1)
echo "4.8.0+1" > VERSION_CW

# Update VERSION_CWCTL (line 1)
echo "4.8.0+1" > VERSION_CWCTL

# Update package.json version (line 3) - base version only
# Edit manually or use: npm version 4.8.0 --no-git-tag-version

# Update charts/chatwoot/Chart.yaml
# Line 32: version: 4.8.0
# Line 35: appVersion: "v4.8.0-1"

# Update charts/chatwoot/values.yaml
# Line 7: tag: v4.8.0-1

# Update CHANGELOG.md
# Add new version section at the top
```

#### 3. Commit Version Bump

```bash
# Stage the version files
git add VERSION_CW VERSION_CWCTL package.json charts/chatwoot/Chart.yaml charts/chatwoot/values.yaml CHANGELOG.md

# Commit with conventional commit message
# For fork-only release:
git commit -m "chore: bump version to v4.8.0+2"

# For upstream sync release:
git commit -m "chore: sync upstream v4.9.0 and bump to v4.9.0+1"
```

#### 4. Create and Push Git Tag

```bash
# Create annotated tag (use + in tag)
git tag -a v4.8.0+1 -m "Release v4.8.0+1"

# Push commits and tags
git push origin main
git push origin v4.8.0+1
```

#### 5. Verify Automated Builds

After pushing the tag, GitHub Actions will automatically:

1. **Build Docker Images** (`.github/workflows/build-docker-image.yaml`):
   - Monitor: https://github.com/chatwoot-br/chatwoot/actions
   - Creates AMD64 and ARM64 images
   - Pushes to `ghcr.io/chatwoot-br/chatwoot:v4.8.0-1` (note: `+` converted to `-`)
   - Updates `latest` tag

2. **Release Helm Chart** (`.github/workflows/chart-releaser.yaml`):
   - Monitor: https://github.com/chatwoot-br/chatwoot/actions
   - Packages Helm chart
   - Creates GitHub release

Wait for both workflows to complete successfully (green checkmarks).

#### 6. Verify Release

```bash
# Check Docker image (note: + becomes - in Docker tags)
docker pull ghcr.io/chatwoot-br/chatwoot:v4.8.0-1

# Check GitHub release
# Visit: https://github.com/chatwoot-br/chatwoot/releases
```

#### 7. Update Release Notes (Optional)

Visit the GitHub release page and enhance the auto-generated release notes:

1. Go to https://github.com/chatwoot-br/chatwoot/releases
2. Find your release
3. Click "Edit release"
4. Add detailed notes from CHANGELOG.md
5. Highlight breaking changes (if any)
6. Add migration instructions (if needed)

## Quick Reference Commands

```bash
# One-command release (after updating files) - fork-only release
git add VERSION_CW VERSION_CWCTL package.json charts/chatwoot/Chart.yaml charts/chatwoot/values.yaml CHANGELOG.md && \
git commit -m "chore: bump version to v4.8.0+2" && \
git tag -a v4.8.0+2 -m "Release v4.8.0+2" && \
git push origin main && \
git push origin v4.8.0+2

# One-command release - upstream sync release
git add VERSION_CW VERSION_CWCTL package.json charts/chatwoot/Chart.yaml charts/chatwoot/values.yaml CHANGELOG.md && \
git commit -m "chore: sync upstream v4.9.0 and bump to v4.9.0+1" && \
git tag -a v4.9.0+1 -m "Release v4.9.0+1" && \
git push origin main && \
git push origin v4.9.0+1
```

## Troubleshooting

### Build Failures

If GitHub Actions workflows fail:

1. **Check workflow logs**: Click on the failed workflow in Actions tab
2. **Common issues**:
   - Missing secrets (HCLOUD_TOKEN, PERSONAL_ACCESS_TOKEN)
   - Syntax errors in Chart.yaml
   - Docker build failures
3. **Fix and retry**:
   ```bash
   # Delete the tag locally and remotely
   git tag -d v4.8.0+1
   git push origin :refs/tags/v4.8.0+1

   # Fix the issue
   # Commit the fix

   # Recreate the tag
   git tag -a v4.8.0+1 -m "Release v4.8.0+1"
   git push origin main
   git push origin v4.8.0+1
   ```

### Version Mismatch

If version numbers don't match across files:

```bash
# Search for version references
grep -r "4.8.0" VERSION_CW VERSION_CWCTL package.json charts/chatwoot/Chart.yaml charts/chatwoot/values.yaml

# Ensure consistency
# All files must have the same base version
```

### Helm Chart Issues

If Helm chart release fails:

```bash
# Validate Chart.yaml
helm lint charts/chatwoot

# Check for syntax errors
yamllint charts/chatwoot/Chart.yaml
```

## Release Checklist

Before releasing, ensure:

- [ ] All code changes are committed
- [ ] Ruby tests pass: `bundle exec rspec`
- [ ] JS tests pass: `pnpm test`
- [ ] Linting passes: `pnpm eslint && bundle exec rubocop -a`
- [ ] Dependencies updated: `bundle install && pnpm install`
- [ ] Version updated in `VERSION_CW`
- [ ] Version updated in `VERSION_CWCTL`
- [ ] Version updated in `package.json`
- [ ] Version updated in `charts/chatwoot/Chart.yaml` (both `version` and `appVersion`)
- [ ] Version updated in `charts/chatwoot/values.yaml`
- [ ] CHANGELOG.md updated with changes
- [ ] Commit message follows format: `chore: bump version to vX.Y.Z+N`
- [ ] Git tag created and pushed
- [ ] GitHub Actions workflows completed successfully
- [ ] Docker image pulled and tested
- [ ] GitHub release notes updated (optional)

## Rolling Back a Release

If you need to rollback a release:

```bash
# Delete the tag
git tag -d v4.8.0+1
git push origin :refs/tags/v4.8.0+1

# Delete the GitHub release
# Visit: https://github.com/chatwoot-br/chatwoot/releases
# Click "Delete" on the release

# Revert the version bump commit
git revert HEAD
git push origin main
```

Note: Docker images and Helm charts cannot be automatically deleted. You'll need to manually deprecate them if necessary.

## Upstream Sync Process

When the upstream repository releases a new version:

### 1. Fetch and Review Upstream Changes

```bash
# Add upstream remote if not already added
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Fetch upstream changes
git fetch upstream

# Review upstream changes
git log upstream/master --oneline -20

# Check upstream tags
git tag -l --sort=-v:refname | head -10
```

### 2. Merge Upstream Changes

```bash
# Create a sync branch
git checkout -b sync/upstream-v4.9.0

# Merge upstream master or specific tag
git merge upstream/master
# OR merge specific tag:
git merge v4.9.0

# Resolve any conflicts
# Test the merged changes
bundle exec rspec
pnpm test
```

### 3. Update Version for Sync Release

Reset fork revision to 1 with the new upstream version:

- `VERSION_CW`: `4.9.0+1`
- `VERSION_CWCTL`: `4.9.0+1`
- `package.json`: `"version": "4.9.0"`
- `charts/chatwoot/Chart.yaml` line 32: `version: 4.9.0`
- `charts/chatwoot/Chart.yaml` line 35: `appVersion: "v4.9.0-1"`
- `charts/chatwoot/values.yaml` line 7: `tag: v4.9.0-1`

### 4. Create Release

```bash
# Commit and tag
git add VERSION_CW VERSION_CWCTL package.json charts/chatwoot/Chart.yaml charts/chatwoot/values.yaml CHANGELOG.md
git commit -m "chore: sync upstream v4.9.0 and bump to v4.9.0+1"
git tag -a v4.9.0+1 -m "Release v4.9.0+1"

# Push
git push origin sync/upstream-v4.9.0
git push origin v4.9.0+1

# Create PR to merge sync branch to main (recommended)
```

## Hotfix Process

For urgent fixes that need immediate release:

1. **Create hotfix from latest tag**:
   ```bash
   git checkout -b hotfix/v4.8.0+2 v4.8.0+1
   ```

2. **Make the fix and commit**

3. **Follow normal release process**:
   - Increment fork revision: `v4.8.0+1` → `v4.8.0+2`
   - Update CHANGELOG.md
   - Commit, tag, and push

4. **Merge back to main**:
   ```bash
   git checkout main
   git merge hotfix/v4.8.0+2
   git push origin main
   ```

## Related Documentation

- [CHANGELOG.md](../CHANGELOG.md) - Version history
- [GitHub Actions](.github/workflows/) - Automated build workflows
- [Helm Chart](charts/chatwoot/) - Kubernetes deployment chart
- [Fork Versioning Strategy](plans/0001-fork-versioning-strategy.md) - Detailed versioning plan

---

**Last Updated**: 2025-12-06
**Upstream**: chatwoot/chatwoot
**Fork**: chatwoot-br/chatwoot
**Version Format**: `v{MAJOR}.{MINOR}.{PATCH}+{FORK_REV}`
