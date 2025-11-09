# CommMate Docker Image Build Guide

**Last Updated**: 09/11/2025  
How to build and deploy CommMate Docker images.

---

## 🚀 **Quick Build (Multi-Platform)**

```bash
# Recommended: Use the multi-platform build script
./custom/script/build_multiplatform.sh v4.7.0.3

# Builds for:
# - linux/amd64 (production servers)
# - linux/arm64 (Mac M1/M2, development)
```

**Build Time:** 15-20 minutes (first time), 5-10 minutes (cached)

---

## 📦 **Build Methods**

## Build Options

### Option 1: Full Build (Recommended)

Builds everything from scratch with CommMate branding baked in.

```bash
cd /path/to/chatwoot

# Build with version tag
docker build \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.7.0 \
  -t commmate/commmate:latest \
  --build-arg RAILS_ENV=production \
  .

# Or use script
./custom/script/build_commmate_image.sh v4.7.0
```

**Dockerfile:** `docker/Dockerfile.commmate`  
**Build Time:** ~15-20 minutes  
**Size:** ~1.5GB

### Option 2: Simple Build (Extends Official)

Builds on top of official Chatwoot image (faster but limited).

```bash
docker build \
  -f docker/Dockerfile.commmate.simple \
  -t commmate/commmate:v4.7.0-simple \
  .
```

**Dockerfile:** `docker/Dockerfile.commmate.simple`  
**Build Time:** ~2-3 minutes  
**Size:** ~1.5GB  
**Note:** Requires official Chatwoot image to exist

## What's Included

### Baked Into Image

**Assets:**
- ✅ CommMate logos (`custom/assets/logos/` → `/app/public/images/`)
- ✅ Favicons (`custom/assets/favicons/` → `/app/public/`)

**Configuration:**
- ✅ Branding config (`custom/config/branding.yml`)
- ✅ Custom translations (`custom/locales/*.yml`)
- ✅ CommMate installation config overrides
- ✅ Automatic branding initializer
- ✅ Custom seeds for CommMate setup

**Entrypoint:**
- ✅ `custom/config/docker-entrypoint.sh`
- ✅ Uses `db:chatwoot_prepare` (Chatwoot's proven method)
- ✅ Automatic database setup on first start
- ✅ Safe for existing installations

**Environment Variables (Built-in Defaults):**
```env
# Branding
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_NAME=CommMate
BRAND_URL=https://commmate.com
HIDE_BRANDING=true
DEFAULT_LOCALE=pt_BR

# Privacy & Security
DISABLE_CHATWOOT_CONNECTIONS=true
DISABLE_TELEMETRY=true
ENABLE_ACCOUNT_SIGNUP=false

# Email
MAILER_SENDER_EMAIL=CommMate <support@commmate.com>
```

### Applied at Runtime

**CSS & JavaScript:**
- Compiled during image build
- Includes all color overrides
- Green branding in all components

**Database Configs:**
- Applied automatically by initializer on startup
- Persistent across restarts
- Safe for existing installations

**Automatic Setup:**
- Uses `db:chatwoot_prepare` task
- Fresh install: schema:load + seeds
- Existing: migrations only
- No manual intervention needed

## Build Script

The `build_commmate_image.sh` script handles:

1. ✅ Validates custom assets exist
2. ✅ Detects current branch/version
3. ✅ Builds with proper tags
4. ✅ Adds metadata labels
5. ✅ Shows next steps

## Pre-Build Checklist

Before building:

```bash
# 1. Ensure you're on correct branch
git checkout commmate/v4.7.0
git status

# 2. Ensure branding is applied
./custom/script/verify_branding.sh

# 3. Ensure assets are present
ls -la custom/assets/favicons/
ls -la custom/assets/logos/

# 4. Test locally first
bin/rails s -p 3000
# Visit http://localhost:3000 and verify branding
```

## Building for Production

### 1. Tag Your Release

```bash
git tag -a v4.7.0-commmate -m "CommMate v4.7.0 based on Chatwoot v4.7.0"
git push origin v4.7.0-commmate
```

### 2. Build Image

```bash
# Using script
./custom/script/build_commmate_image.sh v4.7.0

# Or manually
docker build \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.7.0 \
  -t commmate/commmate:latest \
  --build-arg RAILS_ENV=production \
  --label "version=v4.7.0" \
  --label "build-date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  .
```

### 3. Test Image

```bash
# Run container
docker run -it --rm \
  -e POSTGRES_HOST=host.docker.internal \
  -e POSTGRES_DATABASE=chatwoot \
  -e POSTGRES_USERNAME=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -p 3000:3000 \
  commmate/commmate:v4.7.0

# Visit http://localhost:3000
# Verify:
# - Page title is "CommMate"
# - Logo is CommMate
# - Colors are green
```

### 4. Push to Registry

```bash
# Docker Hub
docker login
docker push commmate/commmate:v4.7.0
docker push commmate/commmate:latest

# Or GitHub Container Registry
docker tag commmate/commmate:v4.7.0 ghcr.io/yourorg/commmate:v4.7.0
docker push ghcr.io/yourorg/commmate:v4.7.0
```

## Multi-Architecture Build

Build for both AMD64 and ARM64:

```bash
# Setup buildx
docker buildx create --name commmate-builder --use

# Build and push multi-arch
docker buildx build \
  -f docker/Dockerfile.commmate \
  --platform linux/amd64,linux/arm64 \
  -t commmate/commmate:v4.7.0 \
  -t commmate/commmate:latest \
  --push \
  .
```

## Build Optimizations

### Use BuildKit

```bash
export DOCKER_BUILDKIT=1

docker build \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.7.0 \
  .
```

### Cache Layers

```bash
# Use cache from previous build
docker build \
  -f docker/Dockerfile.commmate \
  --cache-from commmate/commmate:latest \
  -t commmate/commmate:v4.7.0 \
  .
```

### No Cache (Clean Build)

```bash
docker build \
  -f docker/Dockerfile.commmate \
  --no-cache \
  -t commmate/commmate:v4.7.0 \
  .
```

## Troubleshooting

### Build Fails at Asset Compilation

**Issue:** Vite/Webpack fails during `rails assets:precompile`

**Solution:** The Dockerfile skips asset precompilation and compiles on first boot.

If you need to compile during build:
```dockerfile
# Add before "Remove unnecessary files"
RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile
```

### Missing Custom Files

**Issue:** `COPY custom/assets/` fails

**Solution:** Ensure files exist:
```bash
ls -la custom/assets/favicons/
ls -la custom/assets/logos/
```

### Large Image Size

**Issue:** Image is > 2GB

**Solutions:**
```bash
# Remove build dependencies in Dockerfile
# Use alpine base (already doing this)
# Clean npm/gem caches

# Check image layers
docker history commmate/commmate:v4.7.0
```

### Enterprise Module Bug

**Issue:** Build fails with `const_get_maybe_false` error

**Solution:** The fix is already in `config/initializers/01_inject_enterprise_edition_module.rb`. If building from clean branch:

```bash
# Apply fix before building
./custom/script/apply_commmate_branding.sh
```

## Runtime Configuration

The image needs these environment variables:

### Required

```env
# Database
POSTGRES_HOST=postgres
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=secure_password

# Redis
REDIS_URL=redis://redis:6379

# Rails
SECRET_KEY_BASE=<generate with: openssl rand -hex 64>
FRONTEND_URL=https://yourdomain.com
```

### Optional (Already set in image)

```env
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_NAME=CommMate
BRAND_URL=https://commmate.com
DEFAULT_LOCALE=pt_BR
```

## Docker Compose Example

```yaml
version: '3.8'

services:
  commmate:
    image: commmate/commmate:v4.7.0
    ports:
      - "3000:3000"
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=chatwoot
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=postgres
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - FRONTEND_URL=http://localhost:3000
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Deployment

### First Time Setup (Fully Automatic!)

```bash
# 1. Start containers
podman-compose -f docker-compose.commmate.yaml up -d

# That's it! Automatic setup happens:
#  - Database schema loaded
#  - Seeds create CommMate account + admin
#  - Branding applied
#  - Ready to use!

# 2. Access (wait ~60 seconds for setup)
open http://localhost:3000
```

**Login:** admin@commmate.com / CommMate123!

**What happens automatically:**
1. Waits for PostgreSQL
2. Runs `db:chatwoot_prepare` (detects fresh vs existing)
3. Applies CommMate branding via initializer
4. Starts Rails server

**No manual steps required!** ✅

### Updating to New Image

```bash
# 1. Pull new image
podman pull commmate/commmate:v4.7.0.3

# 2. Stop app containers (keeps data)
podman-compose -f docker-compose.commmate.yaml down

# 3. Start with new image
podman-compose -f docker-compose.commmate.yaml up -d

# Automatic:
#  - db:chatwoot_prepare runs any new migrations
#  - Branding reapplied if needed
#  - Data preserved
```

**Note:** Postgres volume persists, all data safe.

### Publishing Images (Optional)

```bash
# Use the monitor and publish script
./custom/script/monitor_and_publish.sh v4.7.0.3

# Or manually:
podman manifest push commmate/commmate:v4.7.0.3 docker://commmate/commmate:v4.7.0.3

# To also update 'latest' tag:
./custom/script/monitor_and_publish.sh v4.7.0.3 --tag-latest
```

**Note:** Script only publishes, does NOT auto-deploy to production.

## Image Tags

```bash
# Latest (always newest)
commmate/commmate:latest

# Specific version
commmate/commmate:v4.7.0

# With commit hash
commmate/commmate:v4.7.0-abc1234

# Development
commmate/commmate:dev
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build CommMate Image

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: docker/Dockerfile.commmate
          push: true
          tags: |
            commmate/commmate:${{ steps.version.outputs.VERSION }}
            commmate/commmate:latest
          platforms: linux/amd64,linux/arm64
```

## Verification

After building, verify the image contains branding:

```bash
# Check environment vars
docker run --rm commmate/commmate:v4.7.0 env | grep -E "APP_NAME|BRAND"

# Check assets exist
docker run --rm commmate/commmate:v4.7.0 ls -la /app/public/images/
docker run --rm commmate/commmate:v4.7.0 ls -la /app/public/favicon-32x32.png

# Check config exists
docker run --rm commmate/commmate:v4.7.0 cat /app/config/commmate/branding.yml
```

## Build Performance

**Full Build:**
- First build: ~15-20 min
- With cache: ~5-10 min
- Multi-arch: ~25-30 min

**Simple Build:**
- First build: ~2-3 min
- Requires base image

## Clean Up

```bash
# Remove old images
docker image prune -a

# Remove build cache
docker buildx prune

# Remove specific image
docker rmi commmate/commmate:v4.7.0
```

## Related

- **Development:** `DEVELOPMENT.md`
- **Deployment:** See docker-compose.commmate.yaml
- **Configuration:** `custom/config/branding.yml`

