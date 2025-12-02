# CommMate Image Release Process

**Purpose**: Build and publish CommMate Docker images from release branches  
**Tools**: Podman (local), Docker Hub (registry)  
**Last Updated**: December 2025  
**Current Version**: v4.8.0

---

## Overview

This guide covers building and publishing CommMate Docker images after completing the downstream process (see `DOWNSTREAM-RELEASE.md`).

**Prerequisites:**
- ✅ Branch `commmate/vX.Y.Z` created and tested
- ✅ All merge conflicts resolved
- ✅ CommMate customizations verified intact
- ✅ Podman installed locally
- ✅ Docker Hub credentials configured in podman

---

## Quick Start

```bash
# Complete release process for v4.8.0
cd /Users/schimuneck/projects/commmmate/chatwoot

# 1. Checkout release branch
git checkout commmate/v4.8.0
git pull origin commmate/v4.8.0

# 2. Build multi-platform image
./custom/script/build_multiplatform.sh v4.8.0

# 3. Push to Docker Hub (credentials already configured)
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:v4.8.0
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:latest
```

**Build Time**: 15-25 minutes (multi-arch)

---

## Phase 1: Pre-Build Verification

### A. Update CommMate Version

**CRITICAL**: Update version BEFORE building each new image.

```bash
# Edit version file
code custom/config/commmate_version.yml

# Update to your new version:
# commmate_version: '4.8.0.1'  # Increment patch for CommMate-only changes
# base_chatwoot_version: '4.8.0'  # Keep base Chatwoot version
```

**Version Numbering Rules:**

| Scenario | CommMate Version | Base Version | Example |
|----------|------------------|--------------|---------|
| New downstream | Match Chatwoot | New Chatwoot | v4.9.0 based on v4.9.0 |
| CommMate patch | Increment patch | Keep same | v4.8.0.1 based on v4.8.0 |
| Second patch | Increment again | Keep same | v4.8.0.2 based on v4.8.0 |

**After updating, verify:**
```bash
cat custom/config/commmate_version.yml
# Expected: Shows your new version numbers

# Verify version will be used in build
grep "commmate_version" custom/config/commmate_version.yml
# Expected: commmate_version: '4.8.0.1' (or your target version)
```

**Expected Outcome:**
- ✅ Version file updated
- ✅ CommMate version incremented correctly
- ✅ Base version matches Chatwoot base

### B. Verify Branch State

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot

# 1. Checkout correct branch
git checkout commmate/v4.8.0
git status
# Expected: "On branch commmate/v4.8.0" + "working tree clean"

# 2. Verify latest code
git pull origin commmate/v4.8.0
# Expected: "Already up to date" or fast-forward

# 3. Check version
git log --oneline -3
# Expected: Shows merge commit with downstream/v4.8.0
```

**Expected Outcome:**
- ✅ On correct branch
- ✅ Working tree clean
- ✅ Latest code pulled
- ✅ Merge commit visible

### B. Verify CommMate Customizations

```bash
# 1. Check version file exists
ls -la custom/config/commmate_version.yml
# Expected: File exists with correct version

# 2. Check critical files exist
ls -la custom/config/initializers/commmate_config_overrides.rb
ls -la custom/config/initializers/commmate_version.rb
ls -la custom/config/installation_config.yml
ls -la db/migrate/*apply_commmate_branding*

# Expected: All files present

# 3. Check assets exist
ls -la custom/assets/logos/*.png | wc -l
# Expected: 3 (logo-full.png, logo-full-dark.png, logo-icon.png)

ls -la custom/assets/favicons/*.png | wc -l
# Expected: 4+ (favicon files)

# 4. Verify custom controllers and views
ls -la custom/controllers/super_admin/instance_statuses_controller.rb
ls -la custom/views/super_admin/application/_navigation.html.erb
# Expected: Both files exist (for admin console branding)

# 5. Verify branding script exists
ls -la custom/script/apply_commmate_branding.sh
# Expected: -rwxr-xr-x (executable)
```

**Expected Outcome:**
- ✅ Version file present
- ✅ All custom files present
- ✅ Admin console overrides exist
- ✅ Assets complete
- ✅ Scripts executable

### C. Verify Dockerfile

```bash
# Check Dockerfile exists
ls -la docker/Dockerfile.commmate
# Expected: File exists

# Verify it has CommMate ENV vars
grep "DISABLE_CHATWOOT_CONNECTIONS" docker/Dockerfile.commmate
grep "APP_NAME.*CommMate" docker/Dockerfile.commmate
# Expected: Both found
```

**Expected Outcome:**
- ✅ Dockerfile present
- ✅ CommMate ENV vars included

---

## Phase 2: Build Multi-Platform Image

### A. Clean Previous Builds (Optional but Recommended)

```bash
# Remove old images to ensure clean build
podman rmi -f commmate/commmate:v4.8.0 2>/dev/null || true
podman rmi -f commmate/commmate:latest 2>/dev/null || true

# Remove old manifests
podman manifest rm commmate/commmate:v4.8.0 2>/dev/null || true

# Expected: Old images removed (or "image not found" - both OK)
```

### B. Run Multi-Platform Build Script

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot

# Build for both AMD64 (production) and ARM64 (development)
./custom/script/build_multiplatform.sh v4.8.0
```

**What the script does:**
1. Builds for `linux/amd64` (Intel/AMD servers - production)
2. Builds for `linux/arm64` (Apple Silicon - development)
3. Creates manifest combining both architectures
4. Tags as both `v4.8.0` and `latest`

**Build Time:**
- First build: 20-25 minutes
- With cache: 10-15 minutes

**Expected Output:**
```
🏗️  Building CommMate v4.8.0 (multi-platform)...
📦 Building for linux/amd64...
✅ AMD64 build complete
📦 Building for linux/arm64...
✅ ARM64 build complete
📦 Creating manifest...
✅ Manifest created: commmate/commmate:v4.8.0

Next steps:
  podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:v4.8.0
  podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:latest
```

**Expected Outcome:**
- ✅ Build completes without errors
- ✅ Two platform images created
- ✅ Manifest created
- ✅ Both version and latest tags applied

### C. Verify Build Success

```bash
# 1. Check manifests exist
podman manifest inspect commmate/commmate:v4.8.0

# Expected: JSON showing both amd64 and arm64 images

# 2. Check image size
podman images | grep "commmate/commmate"
# Expected: ~1.5-2.5GB per architecture

# 3. List all tags
podman images commmate/commmate --format "{{.Tag}}"
# Expected: 
# v4.8.0
# latest
```

**Expected Outcome:**
- ✅ Manifest contains both architectures
- ✅ Image size reasonable (1.5-2.5GB)
- ✅ Both tags present

---

## Phase 3: Test Image Locally

### A. Test Single Container

```bash
# Start test container with minimal config
podman run -it --rm \
  --name commmate-test \
  -e POSTGRES_HOST=host.containers.internal \
  -e POSTGRES_DATABASE=chatwoot \
  -e POSTGRES_USERNAME=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e REDIS_URL=redis://host.containers.internal:6379 \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e FRONTEND_URL=http://localhost:3000 \
  -p 3000:3000 \
  commmate/commmate:v4.8.0
```

**Expected Output (logs):**
```
🎨 Applying CommMate config overrides...
✅ CommMate config overrides applied
Starting Rails server...
Puma starting in single mode...
Listening on http://0.0.0.0:3000
```

### B. Verify Inside Container

```bash
# In another terminal, exec into running container
podman exec -it commmate-test bash

# Check environment variables
env | grep -E "APP_NAME|BRAND_NAME|DISABLE_CHATWOOT"
# Expected:
# APP_NAME=CommMate
# BRAND_NAME=CommMate
# DISABLE_CHATWOOT_CONNECTIONS=true

# Check assets
ls -la /app/public/brand-assets/
# Expected: logo.png, logo_dark.png, logo_thumbnail.png

# Check initializer
ls -la /app/config/initializers/commmate_config_overrides.rb
# Expected: File exists

# Exit container
exit
```

**Expected Outcome:**
- ✅ ENV vars correct
- ✅ Assets present
- ✅ Initializer in place
- ✅ Server starts without errors

### C. Browser Test

```bash
# Access the running container
open http://localhost:3000
```

**Verify:**
- [ ] Page title shows "CommMate"
- [ ] Favicon is CommMate logo (green)
- [ ] Page loads without errors
- [ ] No console errors in browser dev tools

**Stop test container:**
```bash
# Press Ctrl+C in terminal running podman run
# OR
podman stop commmate-test
```

**Expected Outcome:**
- ✅ UI loads correctly
- ✅ Branding visible
- ✅ No JavaScript errors

---

## Phase 4: Publish to Docker Hub

### A. Verify Podman Login

```bash
# Check if already logged in
podman login docker.io --get-login
# Expected: Your Docker Hub username

# If not logged in (should already be configured):
podman login docker.io
# Enter credentials when prompted
```

**Expected Outcome:**
- ✅ Already logged in (credentials stored)
- ✅ Username displays correctly

**Note**: Per user, credentials are already configured, so this should just confirm.

### B. Push Version Tag

```bash
# Push specific version
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:v4.8.0

# Expected output:
# Copying blob sha256:abc123...
# Copying config sha256:def456...
# Writing manifest to image destination
```

**Time**: 3-8 minutes (depending on network speed)

**Expected Outcome:**
- ✅ Both architectures uploaded
- ✅ Manifest pushed successfully
- ✅ No authentication errors

### C. Push Latest Tag

```bash
# Update 'latest' tag to point to v4.8.0
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:latest

# This makes v4.8.0 the default when users pull 'latest'
```

**Expected Outcome:**
- ✅ Latest tag updated on Docker Hub
- ✅ Points to v4.8.0 manifest

### D. Verify on Docker Hub

```bash
# Check images on Docker Hub via podman
podman search commmate/commmate --limit 5

# Expected: Shows commmate/commmate in results

# Or visit Docker Hub in browser:
# https://hub.docker.com/r/commmate/commmate/tags
```

**Expected Outcome:**
- ✅ Image visible on Docker Hub
- ✅ Both v4.8.0 and latest tags present
- ✅ Multi-arch manifest shows both platforms

---

## Phase 5: Tag Git Release

### Create Git Tag

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot

# Create annotated tag
git tag -a v4.8.0-commmate -m "CommMate v4.8.0 based on Chatwoot v4.8.0

Features:
- Based on Chatwoot v4.8.0
- CommMate branding and privacy features
- 4-layer anti-revert branding system
- Disabled Chatwoot Hub connections
- Portuguese (pt_BR) default locale

Image: commmate/commmate:v4.8.0
"

# Push tag to GitHub
git push origin v4.8.0-commmate
```

**Expected Outcome:**
- ✅ Git tag created locally
- ✅ Tag pushed to GitHub
- ✅ Visible in GitHub releases page

---

## Phase 6: Production Deployment (Optional)

**Note**: This section is for deploying to your production server.

### A. Test Pull on Production

```bash
# SSH to production server
ssh root@200.98.72.137

# Navigate to docker-compose directory
cd /opt/evolution-chatwoot

# Pull new image
docker pull commmate/commmate:v4.8.0

# Verify pulled successfully
docker images | grep "commmate/commmate"
# Expected: v4.8.0 and latest both present
```

**Expected Outcome:**
- ✅ Image pulled successfully
- ✅ Both architectures available
- ✅ Correct platform auto-selected (linux/amd64 for production)

### B. Update and Restart Services

```bash
# Still on production server

# Stop app containers (keeps database running)
docker compose stop chatwoot sidekiq

# Update docker-compose to use new version (if needed)
# File: /opt/evolution-chatwoot/docker-compose.yaml
# Change: image: commmate/commmate:latest
# (Or keep as 'latest' to auto-use newest)

# Start with new image
docker compose up -d chatwoot sidekiq

# Watch logs for startup
docker logs -f chatwoot --tail 100
```

**Expected Logs:**
```
🎨 Applying CommMate config overrides...
  ✓ Overrode INSTALLATION_NAME: CommMate
  ✓ Overrode BRAND_NAME: CommMate
  ...
✅ CommMate config overrides applied
Starting Rails server...
Puma starting...
```

**Expected Outcome:**
- ✅ Containers restart successfully
- ✅ Branding initializer runs
- ✅ Server starts without errors
- ✅ Database migrations run (if any)

### C. Verify Production Deployment

```bash
# Check running containers
docker ps | grep chatwoot
# Expected: chatwoot and sidekiq both "Up" and "healthy"

# Check environment
docker exec chatwoot env | grep -E "APP_NAME|BRAND_NAME|DISABLE_CHATWOOT"
# Expected:
# APP_NAME=CommMate
# BRAND_NAME=CommMate
# DISABLE_CHATWOOT_CONNECTIONS=true

# Check database config
docker exec chatwoot bundle exec rails runner "
  puts 'INSTALLATION_NAME: ' + GlobalConfig.get('INSTALLATION_NAME')['INSTALLATION_NAME']
  puts 'BRAND_NAME: ' + GlobalConfig.get('BRAND_NAME')['BRAND_NAME']
"
# Expected:
# INSTALLATION_NAME: CommMate
# BRAND_NAME: CommMate
```

**Browser Test:**
1. Visit your production URL (e.g., https://crm.commmate.com)
2. Verify "CommMate" in browser tab title
3. Verify CommMate logo and green colors
4. Test login and basic functionality

**Expected Outcome:**
- ✅ All containers healthy
- ✅ Branding correct in UI
- ✅ No errors in logs
- ✅ Application functional

---

## Complete Release Example: v4.8.0

This is the complete workflow for releasing CommMate v4.8.0:

```bash
# ============================================
# PREPARATION
# ============================================
cd /Users/schimuneck/projects/commmmate/chatwoot

# Ensure on release branch
git checkout commmate/v4.8.0
git pull origin commmate/v4.8.0

# Verify customizations intact
ls custom/config/initializers/commmate_config_overrides.rb
ls custom/assets/logos/*.png
# ✅ All files present

# ============================================
# BUILD
# ============================================

# Clean old builds (optional)
podman rmi -f commmate/commmate:v4.8.0 2>/dev/null || true
podman manifest rm commmate/commmate:v4.8.0 2>/dev/null || true

# Build multi-platform
./custom/script/build_multiplatform.sh v4.8.0

# Wait 15-25 minutes...
# ✅ Build complete

# ============================================
# VERIFY BUILD
# ============================================

# Check manifest
podman manifest inspect commmate/commmate:v4.8.0 | jq '.manifests[].platform'
# Expected: {"os":"linux","architecture":"amd64"} and arm64

# Test run (quick smoke test)
podman run --rm commmate/commmate:v4.8.0 \
  env | grep "APP_NAME"
# Expected: APP_NAME=CommMate

# Check assets in image
podman run --rm commmate/commmate:v4.8.0 \
  ls -la /app/public/brand-assets/
# Expected: logo.png, logo_dark.png, logo_thumbnail.png

# ✅ Image verified

# ============================================
# PUBLISH
# ============================================

# Verify logged into Docker Hub (already configured)
podman login docker.io --get-login
# Expected: Your username

# Push version tag
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:v4.8.0

# Push latest tag
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:latest

# ✅ Images published to Docker Hub

# ============================================
# GIT TAG
# ============================================

# Create Git release tag
git tag -a v4.8.0-commmate -m "CommMate v4.8.0

Based on Chatwoot v4.8.0 with CommMate customizations:
- 4-layer branding system
- Privacy controls (no Chatwoot Hub connections)
- Brazilian Portuguese default
- CommMate logos and colors

Docker: commmate/commmate:v4.8.0
"

# Push tag
git push origin v4.8.0-commmate

# ✅ Git tag created

# ============================================
# PRODUCTION DEPLOY (Optional)
# ============================================

# SSH to production
ssh root@200.98.72.137

# Update production
cd /opt/evolution-chatwoot
docker compose stop chatwoot sidekiq
docker pull commmate/commmate:v4.8.0
docker compose up -d chatwoot sidekiq

# Verify
docker logs chatwoot --tail 50 | grep "CommMate config"
# Expected: "🎨 Applying CommMate config overrides..."

# ✅ Production updated
```

**Total Time**: ~30-45 minutes (build + push + deploy)

---

## Build Script Details

### build_multiplatform.sh

**Location**: `custom/script/build_multiplatform.sh`

**Usage:**
```bash
./custom/script/build_multiplatform.sh <version>

# Example:
./custom/script/build_multiplatform.sh v4.8.0
```

**What it does:**

1. **Validates inputs**: Checks version format
2. **Builds AMD64**: For production servers (linux/amd64)
3. **Builds ARM64**: For local development (linux/arm64/v8)
4. **Creates manifest**: Combines both into single tag
5. **Shows next steps**: Push commands

**Arguments:**
- `<version>`: Version tag (e.g., `v4.8.0`, `v4.7.0.1`)

**Environment Variables** (optional):
```bash
# Use custom Dockerfile
export DOCKERFILE=docker/Dockerfile.custom

# Use custom image name  
export IMAGE_NAME=myorg/commmate

# Run script
./custom/script/build_multiplatform.sh v4.8.0
```

---

## Manual Build Commands

If you need to build manually (without script):

### Single Architecture (Local Testing)

```bash
# For your local platform only (faster)
podman build \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.8.0-local \
  --build-arg RAILS_ENV=production \
  .
```

**Time**: 8-12 minutes  
**Use**: Local testing only (not for production)

### Multi-Architecture (Production)

```bash
# Build AMD64 (production servers - Intel/AMD)
podman build \
  --platform linux/amd64 \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.8.0-amd64 \
  --build-arg RAILS_ENV=production \
  .

# Build ARM64 (development - Apple Silicon)
podman build \
  --platform linux/arm64 \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.8.0-arm64 \
  --build-arg RAILS_ENV=production \
  .

# Create manifest combining both
podman manifest create commmate/commmate:v4.8.0 \
  commmate/commmate:v4.8.0-amd64 \
  commmate/commmate:v4.8.0-arm64

# Add latest tag
podman tag commmate/commmate:v4.8.0 commmate/commmate:latest
```

**Time**: 15-20 minutes total  
**Use**: When build script unavailable

---

## Image Verification

### Before Publishing

Run these checks BEFORE pushing to Docker Hub:

```bash
# 1. Check image exists
podman images | grep "commmate/commmate.*v4.8.0"
# Expected: Shows v4.8.0 tag

# 2. Inspect manifest
podman manifest inspect commmate/commmate:v4.8.0 | jq -r '.manifests[] | "\(.platform.os)/\(.platform.architecture)"'
# Expected:
# linux/amd64
# linux/arm64

# 3. Test ENV vars in image
podman run --rm commmate/commmate:v4.8.0 env | grep -E "APP_NAME|BRAND|DISABLE"
# Expected:
# APP_NAME=CommMate
# BRAND_NAME=CommMate
# INSTALLATION_NAME=CommMate
# BRAND_URL=https://commmate.com
# DISABLE_CHATWOOT_CONNECTIONS=true
# DISABLE_TELEMETRY=true

# 4. Test assets in image
podman run --rm commmate/commmate:v4.8.0 \
  ls /app/public/brand-assets/
# Expected:
# logo.png
# logo_dark.png
# logo_thumbnail.png
# logo-full.png
# logo-full-dark.png
# (and more)

# 5. Test initializer in image
podman run --rm commmate/commmate:v4.8.0 \
  cat /app/config/initializers/commmate_config_overrides.rb | head -5
# Expected: Shows initializer code

# 6. Test custom config in image
podman run --rm commmate/commmate:v4.8.0 \
  cat /app/custom/config/installation_config.yml | grep "INSTALLATION_NAME" -A1
# Expected:
# - name: INSTALLATION_NAME
#   value: 'CommMate'
```

**All tests pass** = ✅ Ready to publish

---

## Publishing Strategies

### Strategy 1: Version-Specific Only (Conservative)

```bash
# Only push the specific version tag
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:v4.8.0

# Don't update 'latest' yet
# Users must explicitly: docker pull commmate/commmate:v4.8.0
```

**Use When**: Testing in staging first, not ready for all users

### Strategy 2: Version + Latest (Recommended)

```bash
# Push both tags
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:v4.8.0

podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:latest

# Users can use either:
# - commmate/commmate:v4.8.0 (pinned)
# - commmate/commmate:latest (auto-updates)
```

**Use When**: Confident in release, ready for production

### Strategy 3: Canary Release

```bash
# Push with canary tag first
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:v4.8.0-canary

# Test on subset of users/servers
# If successful, promote to stable:
podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:v4.8.0

podman manifest push \
  commmate/commmate:v4.8.0 \
  docker://commmate/commmate:latest
```

**Use When**: Large changes, want gradual rollout

---

## Troubleshooting

### Build Fails: "cannot find Dockerfile"

**Issue**: Wrong directory or Dockerfile path

**Solution**:
```bash
# Ensure you're in chatwoot root
cd /Users/schimuneck/projects/commmmate/chatwoot
pwd
# Expected: /Users/schimuneck/projects/commmmate/chatwoot

# Check Dockerfile exists
ls -la docker/Dockerfile.commmate
# Expected: File exists
```

### Build Fails: "COPY custom/assets/logos: no such file"

**Issue**: Missing asset files

**Solution**:
```bash
# Check assets exist
ls -la custom/assets/logos/
# Expected: logo-full.png, logo-icon.png, logo-full-dark.png

# If missing, you're on wrong branch
git checkout commmate/v4.8.0
git pull origin commmate/v4.8.0
```

### Build Fails: "bundler: command not found"

**Issue**: Bundler not installed in build

**Solution**: Dockerfile should handle this. Verify:
```bash
grep "gem install bundler" docker/Dockerfile.commmate
# Expected: Found

# If missing, Dockerfile is corrupted - restore from git
git checkout docker/Dockerfile.commmate
```

### Push Fails: "unauthorized"

**Issue**: Not logged into Docker Hub

**Solution**:
```bash
# Login to Docker Hub
podman login docker.io
# Enter username and password

# Retry push
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:v4.8.0
```

### Manifest Push Fails: "manifest unknown"

**Issue**: Manifest doesn't exist locally

**Solution**:
```bash
# List manifests
podman manifest ls
# Expected: commmate/commmate:v4.8.0 in list

# If missing, rebuild:
./custom/script/build_multiplatform.sh v4.8.0
```

### Image Size Too Large (>3GB)

**Issue**: Build artifacts not cleaned

**Solution**: Already handled in Dockerfile, but verify:
```bash
podman images | grep commmate/commmate
# Expected: ~1.5-2.5GB

# If larger, check Dockerfile has cleanup:
grep "rm -rf" docker/Dockerfile.commmate
# Expected: Multiple cleanup commands
```

### Production Deploy: Container Won't Start

**Issue**: Usually database or environment config

**Solution**:
```bash
# Check logs
docker logs chatwoot --tail 100

# Common issues:
# - Database not ready: wait 30s and retry
# - Missing SECRET_KEY_BASE: check .env or docker-compose
# - Network issues: check docker network ls
```

---

## Build Performance Tips

### Speed Up Builds

1. **Use BuildKit** (default in podman):
   ```bash
   # Already enabled in podman by default
   podman build ... # Uses BuildKit automatically
   ```

2. **Keep layers cached**:
   ```bash
   # Don't use --no-cache unless necessary
   podman build -f docker/Dockerfile.commmate ...
   ```

3. **Parallel builds**:
   ```bash
   # Build both architectures in parallel (background)
   ./custom/script/build_multiplatform.sh v4.8.0 &
   ```

4. **Local registry cache**:
   ```bash
   # Pull base images first
   podman pull node:23-alpine
   podman pull ruby:3.4.4-alpine3.21
   ```

### Reduce Image Size

Already optimized in Dockerfile:
- ✅ Multi-stage build
- ✅ Alpine base images
- ✅ Cleanup of build artifacts
- ✅ Production gems only

Current size: ~1.5-2.5GB (reasonable for Rails app)

---

## Version Numbering

### CommMate Versions

Follow this pattern:

| Chatwoot Version | CommMate Version | Git Tag | Docker Tag |
|------------------|------------------|---------|------------|
| v4.7.0 | v4.7.0 | v4.7.0-commmate | v4.7.0 |
| v4.7.0 (patch 1) | v4.7.0.1 | v4.7.0.1-commmate | v4.7.0.1 |
| v4.8.0 | v4.8.0 | v4.8.0-commmate | v4.8.0 |

**Rules:**
- Major.Minor matches Chatwoot version
- Patch is incremented for CommMate-only changes
- Git tag has `-commmate` suffix
- Docker tag does NOT have suffix

### When to Increment

**Use Chatwoot version** (e.g., v4.8.0):
- Downstreamed new Chatwoot release
- Contains upstream features + fixes

**Add patch** (e.g., v4.8.0.1):
- CommMate-only changes (no upstream changes)
- Bug fixes in customizations
- Branding updates
- Config changes

---

## Publishing Checklist

Before pushing to Docker Hub:

- [ ] Built from correct branch (`commmate/vX.Y.Z`)
- [ ] All customizations verified present
- [ ] Multi-arch manifest created (amd64 + arm64)
- [ ] Tested locally (container starts, branding visible)
- [ ] ENV vars verified in image
- [ ] Assets verified in image
- [ ] Logged into Docker Hub
- [ ] Git tag created and pushed
- [ ] Changelog/release notes prepared

After pushing:

- [ ] Verify on Docker Hub website
- [ ] Test pull from Docker Hub
- [ ] Update production (if ready)
- [ ] Document in CHANGELOG
- [ ] Notify team

---

## Image Tags Strategy

### Recommended Tagging

```bash
# Always create these tags:
commmate/commmate:v4.8.0          # Specific version (immutable)
commmate/commmate:v4.8            # Minor version (updates with patches)
commmate/commmate:latest          # Latest stable (updates with releases)

# Optional tags:
commmate/commmate:v4.8.0-canary   # Pre-release testing
commmate/commmate:dev             # Development builds
```

### Example Multi-Tag Push

```bash
# Tag locally
podman tag commmate/commmate:v4.8.0 commmate/commmate:v4.8
podman tag commmate/commmate:v4.8.0 commmate/commmate:latest

# Push all tags
podman push commmate/commmate:v4.8.0
podman push commmate/commmate:v4.8
podman push commmate/commmate:latest
```

---

## Rollback Procedures

### Rollback Docker Hub Image

```bash
# If v4.8.0 has issues, rollback 'latest' to previous version

# 1. Re-push previous stable version as 'latest'
podman manifest push \
  commmate/commmate:v4.7.0.1 \
  docker://commmate/commmate:latest

# 2. Optionally delete bad tag (careful!)
# Use Docker Hub UI or API - no podman command for this
```

### Rollback Production

```bash
# SSH to production
ssh root@200.98.72.137

cd /opt/evolution-chatwoot

# Update docker-compose to use specific older version
# Edit: image: commmate/commmate:v4.7.0.1

# Restart
docker compose stop chatwoot sidekiq
docker pull commmate/commmate:v4.7.0.1  # If not present
docker compose up -d chatwoot sidekiq
```

### Rollback Git Tag

```bash
# Delete tag locally
git tag -d v4.8.0-commmate

# Delete tag on remote
git push --delete origin v4.8.0-commmate
```

**Note**: Only rollback if serious issues found. Test thoroughly before publishing!

---

## CI/CD Integration (Future)

### GitHub Actions Example

**File**: `.github/workflows/build-commmate.yml`

```yaml
name: Build CommMate Image

on:
  push:
    tags:
      - 'v*-commmate'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/Dockerfile.commmate
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            commmate/commmate:${{ steps.version.outputs.VERSION }}
            commmate/commmate:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**Triggers**: Automatically builds when you push a tag like `v4.8.0-commmate`

---

## Maintenance

### Cleanup Old Images Locally

```bash
# Remove dangling images
podman image prune -a

# Remove specific old versions
podman rmi commmate/commmate:v4.7.0

# Remove all CommMate images (careful!)
podman images | grep commmate/commmate | awk '{print $3}' | xargs podman rmi -f
```

### Cleanup Old Images on Docker Hub

**Via Web UI:**
1. Visit https://hub.docker.com/r/commmate/commmate/tags
2. Select old tags
3. Click "Delete"

**Keep:**
- Latest 3 major versions
- All minor versions of current major
- `latest` tag

**Remove:**
- Old patch versions (keep latest patch only)
- Canary/dev tags older than 30 days
- Failed/broken builds

---

## Security Best Practices

### Image Scanning

```bash
# Scan for vulnerabilities (if using Docker Desktop)
docker scout cves commmate/commmate:v4.8.0

# Or use Trivy
trivy image commmate/commmate:v4.8.0
```

### Secrets Management

**DO NOT include in image:**
- ❌ Database passwords
- ❌ API keys
- ❌ SECRET_KEY_BASE
- ❌ OAuth credentials

**Should be in image:**
- ✅ Default branding values
- ✅ Feature flags (DISABLE_CHATWOOT_CONNECTIONS)
- ✅ Default locale settings

**All secrets MUST be passed via environment variables at runtime.**

---

## Related Documentation

- **Downstream Process**: `DOWNSTREAM-RELEASE.md` - How to create release branches (PREVIOUS STEP)
- **Branding System**: `REBRANDING.md` - Branding and environment variables
- **Docker Setup**: `DOCKER-SETUP.md` - Running containers for development
- **Upgrade Guide**: `UPGRADE.md` - Upgrading existing installations
- **Development**: `DEVELOPMENT.md` - Local development without Docker

---

## Complete Release Workflow

**Full process for new CommMate version:**

1. **Create Branches** → `DOWNSTREAM-RELEASE.md`
   - Create downstream/vX.Y.Z
   - Create commmate/vX.Y.Z
   - Resolve conflicts
   - Update main

2. **Build Image** → `IMAGE-RELEASE.md` (THIS DOCUMENT)
   - Build multi-platform
   - Test locally
   - Push to Docker Hub
   - Tag Git release

3. **Deploy** → `DOCKER-SETUP.md`
   - Update production
   - Verify deployment
   - Monitor for issues

---

## Quick Reference

### Complete Release Commands

```bash
# 1. Prepare
git checkout commmate/v4.8.0
git pull origin commmate/v4.8.0

# 2. Build
./custom/script/build_multiplatform.sh v4.8.0

# 3. Verify
podman manifest inspect commmate/commmate:v4.8.0
podman run --rm commmate/commmate:v4.8.0 env | grep APP_NAME

# 4. Publish
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:v4.8.0
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:latest

# 5. Tag
git tag -a v4.8.0-commmate -m "CommMate v4.8.0"
git push origin v4.8.0-commmate

# 6. Deploy (optional)
ssh root@200.98.72.137 "cd /opt/evolution-chatwoot && \
  docker compose stop chatwoot sidekiq && \
  docker pull commmate/commmate:v4.8.0 && \
  docker compose up -d chatwoot sidekiq"
```

**Total Time**: ~35-50 minutes

---

**Last Updated**: December 1, 2025  
**Process Version**: 2.0  
**Tested With**: CommMate v4.8.0  
**Maintained By**: CommMate Team

