# Docker Architecture - GP Bikes AI Assistant

Technical deep-dive into the Docker-based development environment.

**Audience:** DevOps engineers, senior developers
**Last Updated:** 2025-09-30

---

## Overview

The GP Bikes AI Assistant uses a multi-container Docker architecture for local development that mirrors production deployment patterns. This approach ensures:

- **Consistency:** "Works on my machine" becomes "works everywhere"
- **Isolation:** Services can't interfere with host system
- **Reproducibility:** New developers onboard in minutes
- **Scalability:** Easy to add new services (monitoring, caching layers, etc.)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host Machine                            │
│  (macOS / Linux / Windows)                                      │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              Docker Engine                                 │ │
│  │                                                            │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │      gp-bikes-network (Bridge Network)              │  │ │
│  │  │                                                      │  │ │
│  │  │  ┌──────────────┐   ┌──────────────┐                │  │ │
│  │  │  │  PostgreSQL  │   │    Redis     │                │  │ │
│  │  │  │   (16-alpine)│   │  (7-alpine)  │                │  │ │
│  │  │  │              │   │              │                │  │ │
│  │  │  │  Port: 5432  │   │  Port: 6379  │                │  │ │
│  │  │  │              │   │              │                │  │ │
│  │  │  │  Volume:     │   │  Volume:     │                │  │ │
│  │  │  │  postgres_   │   │  redis_      │                │  │ │
│  │  │  │  data        │   │  data        │                │  │ │
│  │  │  └──────┬───────┘   └──────┬───────┘                │  │ │
│  │  │         │                   │                        │  │ │
│  │  │         └────────┬──────────┘                        │  │ │
│  │  │                  │                                   │  │ │
│  │  │         ┌────────▼──────────┐                        │  │ │
│  │  │         │   Rails App       │                        │  │ │
│  │  │         │   (Chatwoot)      │                        │  │ │
│  │  │         │                   │                        │  │ │
│  │  │         │   Port: 3000      │◄──────── HTTP          │  │ │
│  │  │         │   Port: 3035      │◄──────── Webpacker     │  │ │
│  │  │         │                   │                        │  │ │
│  │  │         │   Volumes:        │                        │  │ │
│  │  │         │   - ./:/app       │◄──────── Code          │  │ │
│  │  │         │   - bundle_cache  │          Hot-reload    │  │ │
│  │  │         │   - node_modules  │                        │  │ │
│  │  │         └───────────────────┘                        │  │ │
│  │  │                  │                                   │  │ │
│  │  │         ┌────────▼──────────┐                        │  │ │
│  │  │         │   Sidekiq         │                        │  │ │
│  │  │         │   (Background)    │                        │  │ │
│  │  │         │                   │                        │  │ │
│  │  │         │   Volumes:        │                        │  │ │
│  │  │         │   - ./:/app       │                        │  │ │
│  │  │         │   - bundle_cache  │                        │  │ │
│  │  │         └───────────────────┘                        │  │ │
│  │  │                                                      │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │                                                            │ │
│  │  Named Volumes:                                           │ │
│  │  - gp-bikes-postgres-data    (PostgreSQL data)           │ │
│  │  - gp-bikes-redis-data       (Redis persistence)         │ │
│  │  - gp-bikes-bundle-cache     (Ruby gems)                 │ │
│  │  - gp-bikes-node-modules     (NPM packages)              │ │
│  │  - gp-bikes-packs            (Webpacker output)          │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Service Details

### 1. PostgreSQL 16 (Database)

**Image:** `postgres:16-alpine`
**Purpose:** Primary relational database for all application data

**Configuration:**

```yaml
Performance Tuning:
  POSTGRES_SHARED_BUFFERS: 256MB
  POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
  POSTGRES_MAX_CONNECTIONS: 100

Extensions (auto-loaded):
  - uuid-ossp          # UUID generation
  - pgcrypto           # Cryptographic functions
  - pg_stat_statements # Query performance monitoring
  - unaccent           # Full-text search enhancements
  - pg_trgm            # Trigram fuzzy matching
```

**Health Check:**
- Command: `pg_isready -U postgres -d chatwoot_dev`
- Interval: 10 seconds
- Retries: 5
- Start period: 10 seconds

**Volume:** `gp-bikes-postgres-data` (persists across container restarts)

**Why Alpine?**
- Base image: ~5MB vs ~200MB for full Debian
- Contains everything needed for PostgreSQL
- Security: Smaller attack surface

---

### 2. Redis 7 (Cache & Jobs)

**Image:** `redis:7-alpine`
**Purpose:**
- Session storage
- Background job queue (Sidekiq)
- Action Cable (WebSockets)
- Application caching

**Configuration:**

```yaml
Memory Management:
  maxmemory: 256mb
  maxmemory-policy: allkeys-lru  # Evict least recently used

Persistence:
  save 60 1      # Save if 1 key changed in 60 seconds
  save 300 10    # Save if 10 keys changed in 300 seconds
  save 900 100   # Save if 100 keys changed in 900 seconds

Performance:
  activedefrag: yes  # Defragment memory automatically
  lazyfree-lazy-eviction: yes
```

**Health Check:**
- Command: `redis-cli ping`
- Interval: 10 seconds
- Retries: 5
- Start period: 5 seconds

**Volume:** `gp-bikes-redis-data` (persists queue data)

**Why Redis 7?**
- Redis 7 includes:
  - Active defragmentation (reduces memory fragmentation)
  - Improved eviction policies
  - Better memory efficiency

---

### 3. Rails Application (Chatwoot)

**Build:** Custom Dockerfile (uses Chatwoot's official Dockerfile)
**Purpose:** Main web application serving HTTP requests

**Ports:**
- `3000`: Rails server (HTTP)
- `3035`: Webpacker dev server (Hot Module Replacement)

**Environment Variables:**
- Database: `DATABASE_URL`, `POSTGRES_*`
- Redis: `REDIS_URL`
- Rails: `RAILS_ENV=development`, `SECRET_KEY_BASE`
- GP Bikes: `GP_BIKES_ENABLED`, `AI_WORKERS_ENABLED`
- APIs: `OPENAI_API_KEY`, `WHATSAPP_*`

**Volumes:**

```yaml
Code (bind mount):
  - ./:/app:cached
  # Mounts entire project directory for hot-reload
  # :cached improves performance on macOS

Caches (named volumes):
  - bundle_cache:/usr/local/bundle
    # Persists installed gems
  - node_modules:/app/node_modules
    # Persists NPM packages
  - packs:/app/public/packs
    # Webpacker compiled output

Temporary (anonymous volumes):
  - /app/tmp    # Rails temporary files
  - /app/log    # Rails logs
```

**Startup Sequence:**

```bash
1. Wait for PostgreSQL (pg_isready)
2. bundle check || bundle install
3. npm install
4. rails db:prepare (create + migrate if needed)
5. rails server -b 0.0.0.0 -p 3000
```

**Health Check:**
- Command: `curl -f http://localhost:3000/api || exit 1`
- Interval: 30 seconds
- Timeout: 10 seconds
- Start period: 60 seconds (first boot takes time)

---

### 4. Sidekiq (Background Jobs)

**Build:** Same as Rails app
**Purpose:** Process asynchronous jobs (emails, webhooks, AI workers)

**Depends On:**
- PostgreSQL (healthy)
- Redis (healthy)
- App (started)

**Environment:** Same as Rails app

**Volumes:** Same as Rails app (shares code and caches)

**Startup Sequence:**

```bash
1. Wait for PostgreSQL
2. bundle check || bundle install
3. sidekiq -C config/sidekiq.yml
```

**Concurrency:**
- Default: 10 concurrent threads
- Configurable via `SIDEKIQ_CONCURRENCY` env var
- Reduce if experiencing memory issues

**Health Check:**
- Command: `ps aux | grep sidekiq | grep -v grep || exit 1`
- Interval: 30 seconds
- Start period: 30 seconds

---

## Networking

### Bridge Network: `gp-bikes-network`

All services connect to a custom bridge network for:

**Service Discovery:**
```ruby
# Services can reach each other by container name
database_host = "postgres"  # Not localhost!
redis_host = "redis"        # Not localhost!
```

**DNS Resolution:**
Docker's internal DNS resolves service names to container IPs automatically.

**Isolation:**
Network is isolated from other Docker projects on the same host.

**Port Mapping:**
```yaml
Host          Container       Service
localhost:3000 → 3000       Rails app
localhost:3035 → 3035       Webpacker
localhost:5432 → 5432       PostgreSQL
localhost:6379 → 6379       Redis
```

---

## Volume Strategy

### Why Named Volumes?

**Persistence:** Data survives container recreation

**Performance:** Better I/O performance than bind mounts (especially on macOS)

**Portability:** Can be backed up, migrated, shared

### Volume Types Used

**1. Named Volumes (for data persistence)**

```yaml
postgres_data:      # Database files
  - Persists: All PostgreSQL data
  - Size: Grows with data (typically 100MB-1GB in dev)
  - Backup: docker run --rm -v gp-bikes-postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz /data

redis_data:         # Redis persistence
  - Persists: Redis RDB snapshots
  - Size: 10-100MB typically
  - Backup: Same as postgres

bundle_cache:       # Ruby gems
  - Persists: Installed gems
  - Size: 500MB-1GB
  - Rebuild: docker volume rm gp-bikes-bundle-cache

node_modules:       # NPM packages
  - Persists: Installed NPM packages
  - Size: 300-800MB
  - Rebuild: docker volume rm gp-bikes-node-modules

packs:              # Webpacker output
  - Persists: Compiled JavaScript/CSS
  - Size: 50-200MB
  - Rebuild: docker-compose exec app rails webpacker:clobber
```

**2. Bind Mounts (for code sync)**

```yaml
./:/app:cached
  - Real-time code sync
  - Changes on host immediately available in container
  - :cached flag for macOS performance
```

**3. Anonymous Volumes (for excludes)**

```yaml
/app/tmp, /app/log
  - Prevents host tmp/log from interfering
  - Container-specific temporary files
```

### Volume Management Commands

```bash
# List volumes
docker volume ls | grep gp-bikes

# Inspect volume
docker volume inspect gp-bikes-postgres-data

# Backup volume
docker run --rm \
  -v gp-bikes-postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/db-backup.tar.gz /data

# Restore volume
docker run --rm \
  -v gp-bikes-postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/db-backup.tar.gz -C /

# Remove volume (WARNING: Deletes data!)
docker volume rm gp-bikes-postgres-data

# Remove all unused volumes
docker volume prune
```

---

## Resource Limits

### Development Defaults

**Recommended Host Resources:**
- **CPUs:** 4 cores
- **RAM:** 8GB allocated to Docker
- **Disk:** 20GB free (40GB recommended)

**Per-Service Limits:**

```yaml
postgres:
  Memory: ~100-150MB at rest, up to 512MB under load
  CPU: Low usage in development

redis:
  Memory: ~20-50MB at rest, max 256MB (maxmemory setting)
  CPU: Very low

app:
  Memory: ~500-1000MB (Rails + Puma + Webpacker)
  CPU: Medium (spikes during asset compilation)

sidekiq:
  Memory: ~300-600MB (depends on concurrency)
  CPU: Low-Medium (spikes during job processing)
```

### Adding Resource Limits (Production)

For production, add to docker-compose.yml:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

---

## Build Strategy

### Multi-Stage Build (Not currently used, but recommended)

For production, implement multi-stage Dockerfile:

```dockerfile
# Stage 1: Dependencies
FROM ruby:3.3.0-alpine AS dependencies
RUN apk add --no-cache build-base postgresql-dev nodejs npm
WORKDIR /app
COPY Gemfile Gemfile.lock package.json package-lock.json ./
RUN bundle install --jobs 4 --retry 3
RUN npm ci

# Stage 2: Assets
FROM dependencies AS assets
COPY . .
RUN bundle exec rails assets:precompile
RUN bundle exec rails webpacker:compile

# Stage 3: Runtime
FROM ruby:3.3.0-alpine AS runtime
RUN apk add --no-cache postgresql-client nodejs
WORKDIR /app
COPY --from=dependencies /usr/local/bundle /usr/local/bundle
COPY --from=assets /app/public /app/public
COPY . .
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

**Benefits:**
- Smaller final image (no build tools)
- Faster deployments
- Better security (no compilation tools in production)

---

## Dependency Management

### Startup Dependencies

Using `depends_on` with health checks ensures correct startup order:

```yaml
app:
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

**What this does:**
1. Docker starts postgres and redis first
2. Waits for both to report healthy
3. Only then starts app container
4. Prevents "connection refused" errors

### Without Health Checks

Old approach (less reliable):

```yaml
app:
  depends_on:
    - postgres
    - redis
```

**Problem:** App might start before postgres is ready to accept connections.

---

## Hot Reload & Development Workflow

### Code Changes

**Ruby/Rails:**
- Spring preloader detects changes
- Files auto-reload on next request
- No server restart needed

**JavaScript/Vue:**
- Webpacker watches files
- Recompiles on save
- Browser auto-reloads (HMR)

**CSS/Stylesheets:**
- Webpacker watches
- Recompiles on save
- Browser auto-reloads

### When Restart IS Needed

**Gemfile changes:**
```bash
docker-compose exec app bundle install
docker-compose restart app
```

**package.json changes:**
```bash
docker-compose exec app npm install
docker-compose restart app
```

**Environment variable changes:**
```bash
# Edit .env.development
docker-compose restart app sidekiq
```

**Config changes (routes.rb, initializers):**
```bash
docker-compose restart app
```

---

## Logs & Debugging

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f sidekiq
docker-compose logs -f postgres
docker-compose logs -f redis

# Last 100 lines
docker-compose logs --tail=100 app

# Since specific time
docker-compose logs --since 2025-09-30T10:00:00 app
```

### Log Locations

**Inside Containers:**
```
/app/log/development.log    # Rails log
/app/log/sidekiq.log        # Sidekiq log (if configured)
/var/log/postgresql/        # PostgreSQL logs
```

**On Host (via docker logs):**
```bash
docker logs gp-bikes-app 2>&1 | grep ERROR
```

### Interactive Debugging

**Attach to running container:**
```bash
docker attach gp-bikes-app
# Now byebug breakpoints will work
# Detach: Ctrl+P, Ctrl+Q
```

**Shell access:**
```bash
docker-compose exec app bash
docker-compose exec postgres sh
docker-compose exec redis sh
```

---

## Security Considerations

### Development vs Production

**Development (Current Setup):**
- ✅ No passwords on Redis (acceptable for local dev)
- ✅ Simple PostgreSQL password (acceptable for local dev)
- ✅ Exposed ports (only bound to localhost)
- ✅ Debug logging enabled
- ✅ Source code mounted (necessary for dev)

**Production (Required Changes):**
- ❌ Must use strong Redis password
- ❌ Must use strong PostgreSQL password from secrets manager
- ❌ Don't expose unnecessary ports
- ❌ Use production logging level
- ❌ Don't mount source code
- ❌ Use read-only root filesystem
- ❌ Run as non-root user
- ❌ Enable SSL/TLS for all connections

### Secrets Management

**Current (Development):**
```bash
.env.development (git-ignored)
```

**Production Options:**
1. **Docker Secrets** (Docker Swarm)
2. **Kubernetes Secrets** (K8s)
3. **AWS Secrets Manager** (AWS)
4. **HashiCorp Vault** (Self-hosted)

---

## Performance Optimization

### Mac M1/M2 Specific

**Enable Rosetta:**
```
Docker Desktop → Settings → General
☑ Use Rosetta for x86/amd64 emulation on Apple Silicon
```

**Use ARM images when possible:**
- ✅ postgres:16-alpine (multi-arch)
- ✅ redis:7-alpine (multi-arch)
- ✅ ruby:3.3.0-alpine (multi-arch)

### Volume Performance

**macOS/Windows:**
Use `:cached` flag for bind mounts:
```yaml
volumes:
  - ./:/app:cached
```

**Options:**
- `consistent`: Strictest (slowest)
- `cached`: Host changes propagate eventually (fastest)
- `delegated`: Container changes propagate eventually

### Build Cache

**Optimize Dockerfile layer caching:**

```dockerfile
# Copy dependency files first (changes less frequently)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy source code last (changes frequently)
COPY . .
```

---

## Troubleshooting Commands

```bash
# Check service health
docker-compose ps

# Check resource usage
docker stats

# Check disk space
docker system df

# Restart specific service
docker-compose restart app

# Rebuild specific service
docker-compose up -d --build app

# View container details
docker inspect gp-bikes-app

# Check network
docker network inspect gp-bikes-network

# Clean up everything (DESTRUCTIVE!)
docker-compose down -v
docker system prune -a --volumes
```

---

## Future Improvements

### Phase 2 Additions (Sprint 2-3)

**Add monitoring stack:**
```yaml
prometheus:
  image: prom/prometheus
  # Scrape metrics from app

grafana:
  image: grafana/grafana
  # Visualize metrics

jaeger:
  image: jaegertracing/all-in-one
  # Distributed tracing
```

### Phase 3 (Production)

**Add production services:**
```yaml
nginx:
  image: nginx:alpine
  # Reverse proxy, SSL termination

certbot:
  image: certbot/certbot
  # Automatic SSL certificates
```

---

**Document Maintenance:**
- **Created:** 2025-09-30
- **Last Updated:** 2025-09-30
- **Maintained By:** Jorge (DevOps & Infrastructure)
- **Review:** After infrastructure changes
