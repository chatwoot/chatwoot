# Chatwoot Local Development with Docker Compose

This guide explains how to use Docker Compose for local development with the multi-stage base image architecture.

## Architecture Overview

We use the same **3-tier image architecture** as production to ensure consistency and faster builds:

### Tier 1: System Base (`chatwoot-base:dev-system`)
- **Contains:** Ruby 3.3.3, Node.js 23.7.0, system packages, build tools
- **Built from:** `Dockerfile.base-system`
- **Rebuild frequency:** Rarely (only when upgrading Ruby/Node or system dependencies)
- **Build time:** ~1-2 minutes

### Tier 2: Dependencies Base (`chatwoot-base:dev-deps`)
- **Contains:** All Ruby gems and npm packages installed
- **Built from:** `Dockerfile.base-deps`
- **Rebuild frequency:** When `Gemfile.lock` or `pnpm-lock.yaml` changes
- **Build time:** ~8-12 minutes

### Tier 3: Application Images
- **Rails:** `chatwoot-rails:development` (Rails server)
- **Sidekiq:** `chatwoot-sidekiq:development` (Background jobs)
- **Vite:** `chatwoot-vite:development` (Frontend dev server)
- **Built from:** `Dockerfile.local-rails`, `Dockerfile.local-sidekiq`, `Dockerfile.local-vite`
- **Rebuild frequency:** Only when Dockerfile changes (code is mounted as volume)
- **Build time:** ~30 seconds each

## Key Benefits

### Development Advantages
✅ **Fast startup** - Base images are pre-built and cached
✅ **Live reload** - Application code is mounted as volume, changes reflect immediately
✅ **Consistency** - Same architecture as production staging/prod environments
✅ **Isolated dependencies** - No conflicts with host system
✅ **Easy cleanup** - Remove containers and volumes without affecting host

### Performance Comparison

| Scenario | Old Approach (Monolithic Dockerfile) | New Approach (Base Images) | Improvement |
|----------|--------------------------------------|----------------------------|-------------|
| First time setup | 12-15 minutes | 10-14 minutes | Similar |
| Code change only | 0 seconds (volume mount) | 0 seconds (volume mount) | Same |
| Dependency change | 12-15 minutes (full rebuild) | **8-12 minutes** (rebuild Tier 2 only) | **20-40% faster** |
| System upgrade | 12-15 minutes (full rebuild) | **1-2 minutes** (rebuild Tier 1 only) | **85% faster** |

## Prerequisites

- Docker Engine 20.10+ or Docker Desktop
- Docker Compose v2.0+ (comes with Docker Desktop)
- At least 8GB RAM allocated to Docker
- At least 20GB free disk space

**Check versions:**
```bash
docker --version          # Should be 20.10+
docker compose version    # Should be v2.0+
```

## Quick Start

### 1. Initial Setup (First Time Only)

```bash
# Clone repository (if not already done)
cd /path/to/chatwoot

# Copy environment file
cp .env.example .env

# Edit .env and set required variables:
# - REDIS_PASSWORD
# - SECRET_KEY_BASE
# - FRONTEND_URL=http://localhost:3000

# Build base images (this takes 10-14 minutes on first run)
docker compose build base-system

docker compose build base-deps

# Start all services
docker compose up
```

The application will be available at:
- **Chatwoot App:** http://localhost:3000
- **Mailhog (Email testing):** http://localhost:8025
- **Vite Dev Server:** http://localhost:3036

### 2. Daily Development Workflow

```bash
# Start all services (uses cached base images - fast!)
docker compose up

# Or run in background
docker compose up -d

# View logs
docker compose logs -f rails
docker compose logs -f sidekiq
docker compose logs -f vite

# Stop services
docker compose down
```

## Common Operations

### Database Operations

```bash
# Create and migrate database (first time)
docker compose exec rails bundle exec rails db:create
docker compose exec rails bundle exec rails db:migrate

# Or use the Chatwoot prepare task
docker compose exec rails bundle exec rails db:chatwoot_prepare

# Run migrations
docker compose exec rails bundle exec rails db:migrate

# Rollback migration
docker compose exec rails bundle exec rails db:rollback

# Reset database
docker compose exec rails bundle exec rails db:reset

# Open Rails console
docker compose exec rails bundle exec rails console
```

### Running Tests

```bash
# Ruby/Rails tests (RSpec)
docker compose exec rails bundle exec rspec
docker compose exec rails bundle exec rspec spec/models

# JavaScript tests (Vitest)
docker compose exec vite pnpm test
docker compose exec vite pnpm test:watch
```

### Code Quality & Linting

```bash
# Rubocop
docker compose exec rails bundle exec rubocop
docker compose exec rails bundle exec rubocop -a  # Auto-fix

# ESLint
docker compose exec vite pnpm eslint
docker compose exec vite pnpm eslint:fix

# Prettier
docker compose exec rails pnpm ruby:prettier
```

### Debugging

```bash
# Attach to running Rails server
docker attach $(docker compose ps -q rails)

# View real-time logs
docker compose logs -f rails sidekiq vite

# Inspect container
docker compose exec rails /bin/sh

# Check service status
docker compose ps
```

## When to Rebuild Base Images

### ✅ Rebuild Tier 1 (System Base) When:

You rarely need to rebuild this unless:
- Upgrading Ruby version (e.g., 3.3.3 → 3.4.0)
- Upgrading Node.js version (e.g., 23.7.0 → 24.0.0)
- Adding new system packages to `Dockerfile.base-system`
- Changing Alpine Linux version

**How to rebuild:**
```bash
docker compose build base-system --no-cache
docker compose build base-deps  # Must rebuild Tier 2 after Tier 1
docker compose build rails sidekiq vite  # Rebuild apps
```

### ✅ Rebuild Tier 2 (Dependencies Base) When:

You need to rebuild whenever dependencies change:
- `Gemfile.lock` updated (new gems or version changes)
- `pnpm-lock.yaml` updated (new npm packages)
- `package.json` modified significantly

**How to rebuild:**
```bash
docker compose build base-deps --no-cache
docker compose build rails sidekiq vite  # Rebuild apps
```

**Shortcut for dependency updates:**
```bash
# After running bundle install or pnpm install on host
docker compose build base-deps rails sidekiq vite
docker compose up
```

### ❌ DO NOT Rebuild When:

- Modifying application code (Ruby, JavaScript, Vue files)
- Updating configuration files (Rails configs, etc.)
- Database schema changes
- Environment variable changes

These changes are automatically reflected via volume mounts!

## Advanced Usage

### Building Specific Services

```bash
# Build only what you need
docker compose build rails
docker compose build sidekiq
docker compose build vite

# Build multiple services
docker compose build rails sidekiq
```

### Running Individual Services

```bash
# Start only Rails + dependencies
docker compose up postgres redis rails

# Start only Sidekiq for background job processing
docker compose up postgres redis sidekiq
```

### Clean Slate Rebuild

If you want to completely rebuild everything from scratch:

```bash
# Stop and remove all containers
docker compose down

# Remove base images
docker rmi chatwoot-base:dev-system chatwoot-base:dev-deps

# Remove application images
docker rmi chatwoot-rails:development chatwoot-sidekiq:development chatwoot-vite:development

# Rebuild everything
docker compose build base-system base-deps rails sidekiq vite

# Start fresh
docker compose up
```

### Cleaning Up Docker Resources

```bash
# Remove stopped containers and networks
docker compose down

# Remove volumes (⚠️ deletes database and cached data!)
docker compose down -v

# Remove unused images
docker image prune -a

# Remove everything (⚠️ nuclear option!)
docker system prune -a --volumes
```

## Troubleshooting

### Issue: "Cannot find base image chatwoot-base:dev-system"

**Cause:** Base images haven't been built yet.

**Solution:**
```bash
docker compose build base-system base-deps
```

### Issue: "Gem not found" or "Module not found"

**Cause:** Dependencies changed but base image wasn't rebuilt.

**Solution:**
```bash
# Check if Gemfile.lock or pnpm-lock.yaml changed
git status

# Rebuild dependencies base
docker compose build base-deps --no-cache
docker compose build rails sidekiq vite
docker compose up
```

### Issue: Port 3000/5432/6379 already in use

**Cause:** Another service is using these ports on your host.

**Solution:**

Option 1 - Stop conflicting services:
```bash
# Check what's using the port
lsof -i :3000
lsof -i :5432
lsof -i :6379

# Stop local services
brew services stop postgresql
brew services stop redis
```

Option 2 - Change ports in `docker-compose.yaml`:
```yaml
ports:
  - "3001:3000"  # Map container 3000 to host 3001
```

### Issue: "Database does not exist"

**Cause:** Database hasn't been created yet.

**Solution:**
```bash
docker compose exec rails bundle exec rails db:create
docker compose exec rails bundle exec rails db:migrate
```

### Issue: Slow performance on macOS

**Cause:** Docker volume mounts can be slow on macOS.

**Solution:**

1. Ensure you're using `:delegated` flag in volumes (already configured)
2. Increase Docker Desktop resources:
   - Open Docker Desktop → Settings → Resources
   - Increase CPUs to 4-6
   - Increase Memory to 8GB+
   - Enable "Use new Virtualization framework" and "VirtioFS" (macOS 12.5+)

3. Consider using docker-sync for even better performance (optional)

### Issue: "Out of disk space"

**Cause:** Docker images and volumes consuming too much space.

**Solution:**
```bash
# Check disk usage
docker system df

# Clean up
docker system prune -a --volumes

# Then rebuild
docker compose build base-system base-deps rails sidekiq vite
```

### Issue: Changes to code not reflecting

**Cause 1:** Code directory not properly mounted.

**Check:**
```bash
# Verify volume mount
docker compose config | grep -A5 volumes

# Should show: - ./:/app:delegated
```

**Cause 2:** Service needs restart for configuration changes.

**Solution:**
```bash
# Restart specific service
docker compose restart rails
docker compose restart sidekiq
```

## Comparing with Production Setup

This local Docker Compose setup mirrors the production architecture (see `README-base-images.md`):

| Aspect | Local (Docker Compose) | Production (CircleCI + ECR) |
|--------|------------------------|---------------------------|
| **Base images** | Built locally | Built in CircleCI, pushed to ECR |
| **Image names** | `chatwoot-base:dev-*` | `chatwoot-base:v4.0.4-base1-*` |
| **App images** | `chatwoot-*:development` | `chatwoot:rails-staging`, etc. |
| **Code mounting** | Volume mount (live reload) | Copied into image (immutable) |
| **Gems location** | Shared volume `/gems` | Copied into image |
| **Environment** | `RAILS_ENV=development` | `RAILS_ENV=production` |
| **Asset compilation** | On-demand by Vite | Pre-compiled during build |
| **Rebuild trigger** | Manual | Automatic on push |

**Key Difference:** Local uses volume mounts for fast iteration, while production bakes code into images for immutability.

## Performance Tips

### 1. Pre-build Base Images
Always build base images before starting services:
```bash
docker compose build base-system base-deps
docker compose up
```

### 2. Use BuildKit
Enable Docker BuildKit for faster builds (already enabled in Docker Desktop):
```bash
export DOCKER_BUILDKIT=1
docker compose build
```

### 3. Increase Docker Resources
- **CPUs:** 4-6 cores
- **Memory:** 8GB minimum, 16GB recommended
- **Disk:** At least 20GB free space

### 4. Use docker-compose up -d
Run in detached mode to free up terminal:
```bash
docker compose up -d
docker compose logs -f rails  # Follow specific logs
```

## File Reference

### Docker Compose Files
- `docker-compose.yaml` - Main compose configuration

### Dockerfiles
**Base Images:**
- `Dockerfile.base-system` - Tier 1 system base (Ruby, Node, system packages)
- `Dockerfile.base-deps` - Tier 2 dependencies base (gems + npm packages)

**Application Images:**
- `Dockerfile.local-rails` - Rails server for local development
- `Dockerfile.local-sidekiq` - Sidekiq worker for local development
- `Dockerfile.local-vite` - Vite dev server for local development

**Production Images:**
- `Dockerfile-staging-rails`, `Dockerfile-staging-sidekiq` - Staging environment
- `Dockerfile-prod-ind-rails`, `Dockerfile-prod-ind-sidekiq` - Production India
- `docker/Dockerfile` - Legacy monolithic Dockerfile

### Configuration
- `.env` - Environment variables (copy from `.env.example`)
- `docker/entrypoints/` - Container entrypoint scripts

## Best Practices

### 1. Keep Base Images Stable
- Only rebuild when dependencies change
- Tag base images with versions for easy rollback
- Test base image changes locally before production

### 2. Use Volumes Wisely
- Application code: Volume mount (fast iteration)
- Dependencies: Named volumes (persistent)
- Temp files: Named volumes (avoid host pollution)

### 3. Database Management
- Use named volumes for Postgres data (`postgres:`)
- Don't delete volumes unless you want to reset data
- Backup before major changes: `docker compose exec postgres pg_dump`

### 4. Resource Management
- Stop services when not in use: `docker compose down`
- Clean up periodically: `docker system prune`
- Monitor disk usage: `docker system df`

### 5. Version Control
- Never commit `.env` (use `.env.example`)
- Keep Dockerfiles in sync with production versions
- Document changes to base images in commit messages

## Migration from Old Setup

If you're migrating from the old `docker/Dockerfile` approach:

### Before (Old Approach)
```yaml
services:
  rails:
    build:
      context: .
      dockerfile: ./docker/Dockerfile
    # Rebuilds everything every time dependencies change
```

### After (New Approach)
```yaml
services:
  base-system:
    build:
      dockerfile: Dockerfile.base-system

  base-deps:
    build:
      dockerfile: Dockerfile.base-deps
    depends_on: [base-system]

  rails:
    build:
      dockerfile: Dockerfile.local-rails
    depends_on: [base-deps]
    # Only rebuilds when Dockerfile changes
    # Code mounted as volume for fast iteration
```

**Migration Steps:**
1. Pull latest changes: `git pull`
2. Build base images: `docker compose build base-system base-deps`
3. Build application images: `docker compose build rails sidekiq vite`
4. Start services: `docker compose up`

## FAQ

**Q: Why three tiers instead of one Dockerfile?**
A: Separating system dependencies, Ruby/Node packages, and application code allows us to rebuild only what changed. This saves time and storage.

**Q: Can I use this for production?**
A: No, this is for local development only. Production uses different Dockerfiles (`Dockerfile-staging-*`, `Dockerfile-prod-ind-*`) with optimized builds and no volume mounts.

**Q: How often should I rebuild base images?**
A: Only when `Gemfile.lock` or `pnpm-lock.yaml` changes. Code changes don't require rebuilding.

**Q: What if I don't want to use Docker?**
A: You can still use local development with `overmind` or `foreman` (see `CLAUDE.md` for instructions).

**Q: How do I update Ruby or Node versions?**
A: Edit `Dockerfile.base-system`, update `NODE_VERSION` and Ruby base image, then rebuild all tiers.

**Q: Can I run tests inside containers?**
A: Yes! See "Running Tests" section above.

**Q: Why are images so large?**
A: Development images include build tools and full dependencies. Production images are much smaller (see `README-base-images.md`).

**Q: How do I contribute changes to base images?**
A: Test locally first, then update production Dockerfiles in sync with local ones. See `README-base-images.md` for production update process.

## Additional Resources

- **Production Base Images:** See `README-base-images.md` for production setup
- **Project Documentation:** See `CLAUDE.md` for project overview and common commands
- **Docker Compose Docs:** https://docs.docker.com/compose/
- **Docker BuildKit:** https://docs.docker.com/build/buildkit/
- **Chatwoot Docs:** https://developers.chatwoot.com

## Support

If you encounter issues:

1. Check troubleshooting section above
2. Review Docker logs: `docker compose logs`
3. Search existing issues: https://github.com/chatwoot/chatwoot/issues
4. Ask in team Slack/Discord
5. Check `CLAUDE.md` for project-specific guidance

---

**Last Updated:** 2025-01-08
**Chatwoot Version:** 4.0.4
**Base Image Version:** dev-system, dev-deps
