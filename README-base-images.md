# Chatwoot Base Images - Build & Maintenance Guide

This document explains the base image strategy for optimizing Docker builds in CircleCI.

## Architecture Overview

We use a **3-tier image architecture** to drastically reduce build times:

### Tier 1: System Base (`chatwoot-base:v4.0.4-base1-system`)
- **Contains:** Ruby 3.3.3, Node.js 23.7.0, system packages, build tools
- **Size:** ~340MB
- **Rebuild frequency:** Rarely (when upgrading Ruby/Node or system dependencies)
- **Build time:** ~1 minute
- **Dockerfile:** `Dockerfile.base-system`

### Tier 2: Dependencies Base (`chatwoot-base:v4.0.4-base1-deps`)
- **Contains:** All Ruby gems and npm packages installed
- **Built FROM:** Tier 1 system base
- **Size:** ~990MB (includes gems + node_modules)
- **Rebuild frequency:** When `Gemfile.lock` or `pnpm-lock.yaml` changes
- **Build time:** ~12 minutes
- **Dockerfile:** `Dockerfile.base-deps`

### Tier 3: Application Images (rails/sidekiq)
- **Rails images:** ~530MB (gems + app code + compiled assets + Node.js runtime)
- **Sidekiq images:** ~410MB (gems + app code + Node.js runtime)
- **Build time:** **~1-2 minutes** (Rails and Sidekiq)
- **Rebuild:** Every code push (automatic)
- **Dockerfiles:** `Dockerfile-staging-rails`, `Dockerfile-staging-sidekiq`, etc.

## Performance Benefits

| Build Type | Old Approach | New Approach | Time Saved |
|------------|--------------|--------------|------------|
| First build (cold cache) | 8-9 minutes | 8-9 minutes | 0% |
| Code change only | 8-9 minutes | **1-2 minutes** | **75-87%** ✅ |
| Dependency change | 8-9 minutes | 12-13 minutes | -35% (rebuild base) |
| System package change | 8-9 minutes | 1 minute | **88%** |

**Image size reduction:**
- Rails: 4.5GB → **530MB** (88% smaller)
- Sidekiq: 4.9GB → **410MB** (92% smaller)

**Monthly savings:**
- ~560 minutes (9+ hours) of build time saved per day
- Faster deployments = faster iteration
- Reduced ECR storage costs

## Base Image Versioning

### Version Format

Base images use semantic versioning: `v{CHATWOOT_VERSION}-base{N}-{TIER}`

**Examples:**
- `v4.0.4-base1-system` - Initial system base for Chatwoot 4.0.4
- `v4.0.4-base1-deps` - Initial dependencies base for Chatwoot 4.0.4
- `v4.0.4-base2-system` - Ruby 3.3.4 upgrade
- `v4.0.4-base2-deps` - Updated with new gems after Ruby upgrade
- `v4.1.0-base1-system` - Fresh base for Chatwoot 4.1.0

### Current Version

Check the `BASE_IMAGE_VERSION` file in the repository root:
```bash
cat BASE_IMAGE_VERSION
# v4.0.4-base1
```

### Why Versioning?

- ✅ **Immutable base images** - Old versions never overwritten
- ✅ **Easy rollback** - Revert to previous base version if issues occur
- ✅ **Safe testing** - Test new base versions without affecting production
- ✅ **Independent updates** - Staging can use `base2` while production uses `base1`
- ✅ **Clear history** - Know exactly what changed between versions

## When to Rebuild Base Images

### ✅ Increment Version & Rebuild System Base (Tier 1) When:
- Upgrading Ruby version (e.g., 3.3.3 → 3.4.0)
- Upgrading Node.js version (e.g., 23.7.0 → 24.0.0)
- Adding new system packages (e.g., new image processing library)
- Changing Alpine Linux version

### ✅ Increment Version & Rebuild Dependencies Base (Tier 2) When:
- `Gemfile.lock` changes (new gems or version updates)
- `pnpm-lock.yaml` changes (new npm packages or version updates)
- `package.json` changes significantly
- System base version incremented (rebuild deps with new system base)

### ❌ DO NOT Increment or Rebuild Base Images When:
- Application code changes (Ruby/JS/Vue files in `app/`)
- Configuration changes
- Kubernetes deployment changes
- CircleCI config changes (unless affecting base image builds)

## How to Rebuild Base Images

### Option 1: Via CircleCI UI (Recommended)

**When rebuilding with version increment:**

1. Update `BASE_IMAGE_VERSION` file:
   ```bash
   echo "v4.0.4-base2" > BASE_IMAGE_VERSION
   git add BASE_IMAGE_VERSION
   git commit -m "chore: increment base image version to base2"
   git push
   ```

2. Go to CircleCI project: https://app.circleci.com/pipelines/github/delta-exchange/chatwoot
3. Click "Trigger Pipeline" button
4. Add parameters:
   ```json
   {
     "workflow": "build-base",
     "base_image_version": "base2"
   }
   ```
5. Click "Trigger Pipeline"

This will build **versioned** base images for both **staging** (Tokyo) and **production India** regions:
- `chatwoot-base:v4.0.4-base2-system`
- `chatwoot-base:v4.0.4-base2-deps`

**Build order:**
1. `build-base-system-staging` (~1 min)
2. `build-base-deps-staging` (~12 min) - requires system base
3. `build-base-system-prod-india` (~1 min)
4. `build-base-deps-prod-india` (~12 min) - requires system base

**Total time:** ~13 minutes (system builds run in parallel, then deps builds run in parallel)

**After base images are built, update application Dockerfiles:**

6. Update all 4 application Dockerfiles to use new base version:
   ```bash
   # Update BASE_IMAGE_TAG in all Dockerfiles
   sed -i '' 's/v4.0.4-base1-deps/v4.0.4-base2-deps/g' Dockerfile-staging-rails
   sed -i '' 's/v4.0.4-base1-deps/v4.0.4-base2-deps/g' Dockerfile-staging-sidekiq
   sed -i '' 's/v4.0.4-base1-deps/v4.0.4-base2-deps/g' Dockerfile-prod-ind-rails
   sed -i '' 's/v4.0.4-base1-deps/v4.0.4-base2-deps/g' Dockerfile-prod-ind-sidekiq

   git add Dockerfile-*
   git commit -m "chore: update application images to use base2"
   git push
   ```

7. Test application builds to ensure they work with new base version

### Option 2: Via CircleCI CLI

```bash
# Install CircleCI CLI if not installed
curl -fLSs https://circle.ci/cli | bash

# Trigger base image rebuild with version
circleci run workflow build-base-images \
  --param workflow=build-base \
  --param base_image_version=base2
```

### Option 3: Manual Local Build (Testing Only)

**For testing changes before pushing to CircleCI:**

```bash
# 1. Build system base
DOCKER_BUILDKIT=1 docker build \
  -f Dockerfile.base-system \
  -t chatwoot-base:v4.0.4-system \
  .

# 2. Build dependencies base
DOCKER_BUILDKIT=1 docker build \
  -f Dockerfile.base-deps \
  --build-arg ECR_URL=localhost \
  --build-arg BASE_IMAGE_TAG=v4.0.4-system \
  -t chatwoot-base:v4.0.4-deps \
  .

# 3. Test building application image
DOCKER_BUILDKIT=1 docker build \
  -f Dockerfile-staging-rails \
  --build-arg ECR_URL=localhost \
  --build-arg BASE_IMAGE_TAG=v4.0.4-deps \
  --build-arg CIRCLE_SHA1=test-local \
  -t chatwoot:rails-test \
  .
```

## Verification

After rebuilding base images, verify they exist in ECR:

### Staging (Tokyo Region)
```bash
aws ecr describe-images \
  --repository-name chatwoot-base \
  --region ap-northeast-1 \
  --registry-id ${AWS_ACCOUNT_ID}
```

### Production India
```bash
aws ecr describe-images \
  --repository-name chatwoot-base \
  --region ap-south-1 \
  --registry-id ${AWS_IND_ACCOUNT}
```

Expected images (with versioning):
- `chatwoot-base:v4.0.4-base1-system`
- `chatwoot-base:v4.0.4-base1-deps`
- `chatwoot-base:v4.0.4-base2-system` (if base2 built)
- `chatwoot-base:v4.0.4-base2-deps` (if base2 built)

## Troubleshooting

### Issue: Application build fails with "base image not found"

**Cause:** Base images haven't been built yet in ECR.

**Solution:**
```bash
# Trigger base image build workflow
circleci run workflow build-base-images --param workflow=build-base
```

Wait for completion (~18 minutes), then retry application build.

### Issue: Build takes 8+ minutes even with base images

**Cause:** Base image tag mismatch or not pulling from ECR.

**Check:**
1. Verify `BASE_IMAGE_TAG` in `.circleci/config.yml` matches ECR tag
2. Verify `ECR_URL` environment variable is set correctly
3. Check CircleCI logs for "FROM ${ECR_URL}/chatwoot-base:v4.0.4-deps"

### Issue: Gem version conflict after dependency change

**Cause:** Base image has old `Gemfile.lock`.

**Solution:** Increment base version and rebuild Tier 2 (dependencies base):
```bash
# Update version
echo "v4.0.4-base3" > BASE_IMAGE_VERSION

# Rebuild with new version
circleci run workflow build-base-images \
  --param workflow=build-base \
  --param base_image_version=base3

# Update Dockerfiles to use base3
```

### Issue: Version mismatch between BASE_IMAGE_VERSION and Dockerfiles

**Cause:** BASE_IMAGE_VERSION file says `base2` but Dockerfiles still reference `base1-deps`.

**Solution:** Update all Dockerfiles to match:
```bash
# Check current version
cat BASE_IMAGE_VERSION

# Update all Dockerfiles
grep "BASE_IMAGE_TAG=v4.0.4-" Dockerfile-* | cut -d: -f1 | sort -u | while read file; do
  sed -i '' "s/v4.0.4-base[0-9]-deps/v4.0.4-base2-deps/g" "$file"
done
```

## Maintenance Schedule

### Recommended Schedule:
- **Tier 1 (System):** Review quarterly, rebuild only if upgrading Ruby/Node
- **Tier 2 (Dependencies):** Rebuild whenever `Gemfile.lock` or `pnpm-lock.yaml` changes
- **Tier 3 (Application):** Automatic on every push

### Version Tracking:

When you update base images, consider updating tags:

| Change | New Tag Example |
|--------|-----------------|
| Ruby 3.3.3 → 3.4.0 | `v4.1.0-system` |
| Major gem updates | `v4.0.5-deps` |
| Chatwoot upgrade | `v4.1.0-system` and `v4.1.0-deps` |

Update `BASE_IMAGE_TAG` in `.circleci/config.yml` accordingly.

## Cost Analysis

### Old Approach (No Base Images)
- Build time per deployment: 8-9 minutes (per image)
- Images built per push: 2 (staging rails + sidekiq)
- Total: ~18 minutes per deployment
- Frequent rebuilds = high CI/CD costs

### New Approach (With Base Images)
- Build time per deployment: 1-2 minutes (per image)
- Images built per push: 2 (staging rails + sidekiq)
- Total: ~2-4 minutes per deployment
- **Base image rebuilds:** ~2x/month × 13 minutes = 26 minutes/month
- **Time saved per deployment:** 14-17 minutes (75-87% faster)

**Additional benefits:**
- Reduced ECR storage costs (88-92% smaller images)
- Faster deployment rollbacks
- Better developer experience with faster iteration

## Reference

### ECR Repositories:
- Application images: `chatwoot` (rails-*, sidekiq-*)
- Base images: `chatwoot-base` (v4.0.4-system, v4.0.4-deps)

### CircleCI Workflows:
- `build-base-images` - Manual trigger to rebuild base images
- `build-and-deploy` - Automatic build and deploy on push

### Key Files:
- `Dockerfile.base-system` - Tier 1 system base
- `Dockerfile.base-deps` - Tier 2 dependencies base
- `Dockerfile-staging-rails` - Application Rails image
- `Dockerfile-staging-sidekiq` - Application Sidekiq image
- `Dockerfile-prod-ind-rails` - Production Rails image
- `Dockerfile-prod-ind-sidekiq` - Production Sidekiq image
- `.circleci/config.yml` - CI/CD configuration

## Additional Resources

### Chatwoot Documentation:
- **Docker Deployment Guide:** https://developers.chatwoot.com/self-hosted/deployment/docker
  - Official Chatwoot Docker deployment instructions

- **Building Custom Images:** https://developers.chatwoot.com/self-hosted/deployment/docker#steps-to-build-images-yourself
  - Chatwoot's approach to building custom Docker images
  - **Note:** We adapted this concept but use a 3-tier base image strategy instead of the official chatwoot/chatwoot base images, since we have custom code modifications

### CircleCI Documentation:
- **Docker Layer Caching:** https://circleci.com/docs/guides/optimize/docker-layer-caching/
  - Understanding how DLC works with multi-stage builds
  - Best practices for layer optimization

- **Custom Docker Images:** https://circleci.com/docs/guides/execution-managed/custom-images/#creating-a-custom-image-manually
  - Creating and managing custom base images
  - Registry integration with AWS ECR

- **Data Persistence Strategies:** https://circleci.com/docs/guides/optimize/persist-data/
  - Caching dependencies between builds
  - Workspace and artifact management

- **Build Optimization Guide:** https://circleci.com/docs/guides/optimize/optimizations/
  - Complete optimization techniques
  - Resource class configuration
  - Parallelism strategies

### AWS ECR Documentation:
- **ECR User Guide:** https://docs.aws.amazon.com/ecr/
- **Docker Registry Cache:** https://docs.docker.com/build/cache/backends/registry/

### Docker BuildKit:
- **BuildKit Documentation:** https://docs.docker.com/build/buildkit/
- **Cache Mounts:** https://docs.docker.com/build/guide/mounts/

## Questions?

Contact the DevOps team or check CircleCI build logs for detailed output.

---

**Last Updated:** 2025-01-04
**Chatwoot Version:** 4.0.4
**Base Image Version:** v4.0.4-base1
