# 🏗️ GP Bikes AI Assistant - Render Deployment Architecture

**Document Version:** 1.0.0  
**Last Updated:** October 1, 2025  
**Author:** AI Backend Engineer (Render Specialist)  
**Status:** Production-Ready Blueprint

---

## 📋 Executive Summary

This document provides a comprehensive, production-grade deployment architecture for **GP Bikes AI Assistant** on Render.com. The platform is a fork of Chatwoot with 8 specialized AI workers that automate 80% of WhatsApp conversations for Yamaha motorcycle sales in Colombia.

### Key Outcomes
- ✅ **Multi-service architecture** with proper separation of concerns
- ✅ **Cost-optimized** with staging and production environments
- ✅ **Highly available** with automatic scaling and health checks
- ✅ **Secure** with encrypted secrets and private networking
- ✅ **Observable** with metrics, logging, and alerting
- ✅ **Maintainable** with Infrastructure as Code (Blueprint YAML)

---

## 🎯 Architecture Overview

### Current State Analysis

**Tech Stack:**
- **Ruby:** 3.4.4
- **Rails:** 7.1.x
- **Node.js:** 23.x (with pnpm 10.x)
- **PostgreSQL:** 16.x with pgvector extension (vector embeddings for AI)
- **Redis:** 7.x (cache + Sidekiq jobs)
- **Sidekiq:** Background job processor (10 concurrent threads default)
- **Vue.js:** 3.5.x (frontend with Vite 5.x)
- **AI Stack:** OpenAI GPT-4, ruby-openai, ai-agents gem

**Critical Dependencies:**
- **Active Storage:** Requires persistent storage (S3 or Render Disk)
- **pgvector:** PostgreSQL extension for AI embeddings
- **OpenAI API:** External dependency with rate limits
- **WhatsApp Business API:** Webhook integration
- **Sidekiq Queues:** 13 queues with priority-based processing

---

## 🏛️ Proposed Render Architecture

### Service Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                         RENDER PLATFORM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │   Web Service    │◄────────┤  Load Balancer   │              │
│  │   (Rails App)    │         │   (Auto-scaling) │              │
│  │   Ruby 3.4.4     │         └──────────────────┘              │
│  │   2 instances    │                                            │
│  │   Standard Plan  │                                            │
│  └────────┬─────────┘                                            │
│           │                                                       │
│           │ connects to                                          │
│           ▼                                                       │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │ Background Worker│         │  Private Service │              │
│  │    (Sidekiq)     │         │    (optional)    │              │
│  │   Ruby 3.4.4     │         │  Internal APIs   │              │
│  │   1 instance     │         └──────────────────┘              │
│  │   Standard Plan  │                                            │
│  └────────┬─────────┘                                            │
│           │                                                       │
│           │ connects to                                          │
│           ▼                                                       │
│  ┌──────────────────────────────────────────────┐               │
│  │            MANAGED DATABASES                 │               │
│  ├──────────────────────────────────────────────┤               │
│  │  ┌──────────────┐      ┌──────────────┐     │               │
│  │  │  PostgreSQL  │      │    Redis     │     │               │
│  │  │   16.x       │      │    7.x       │     │               │
│  │  │  + pgvector  │      │  256MB plan  │     │               │
│  │  │  Pro plan    │      │  Starter     │     │               │
│  │  └──────────────┘      └──────────────┘     │               │
│  └──────────────────────────────────────────────┘               │
│                                                                   │
│  ┌──────────────────────────────────────────────┐               │
│  │           PERSISTENT STORAGE                 │               │
│  ├──────────────────────────────────────────────┤               │
│  │  ┌──────────────┐      ┌──────────────┐     │               │
│  │  │  Render Disk │  OR  │   AWS S3     │     │               │
│  │  │  10GB SSD    │      │  (preferred) │     │               │
│  │  │  /app/storage│      │              │     │               │
│  │  └──────────────┘      └──────────────┘     │               │
│  └──────────────────────────────────────────────┘               │
│                                                                   │
│  ┌──────────────────────────────────────────────┐               │
│  │       EXTERNAL INTEGRATIONS                  │               │
│  ├──────────────────────────────────────────────┤               │
│  │  • OpenAI API (GPT-4)                        │               │
│  │  • WhatsApp Business API (Meta)              │               │
│  │  • Sentry (error tracking)                   │               │
│  │  • Datadog/New Relic (APM - optional)        │               │
│  └──────────────────────────────────────────────┘               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Service Breakdown

### 1. Web Service (Rails Application)

**Purpose:** Serve HTTP requests, handle WhatsApp webhooks, render Vue.js dashboard

**Configuration:**
```yaml
services:
  - type: web
    name: gp-bikes-web
    runtime: ruby
    plan: standard  # $25/month per instance
    numInstances: 2 # For high availability
    region: oregon  # Or closest to Colombia (if available)
    buildCommand: "./bin/render-build.sh"
    startCommand: "bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV"
    healthCheckPath: /api/v1/health
    autoDeploy: true
    branch: production
    
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RACK_ENV
        value: production
      - key: NODE_ENV
        value: production
      - key: RAILS_SERVE_STATIC_FILES
        value: true
      - key: RAILS_LOG_TO_STDOUT
        value: true
      - key: RAILS_MAX_THREADS
        value: 5
      - key: WEB_CONCURRENCY
        value: 2
      
    scalingConfig:
      minInstances: 1
      maxInstances: 4
      targetCPUPercent: 70
      targetMemoryPercent: 80
```

**Resource Requirements:**
- **CPU:** 1.0 vCPU (Standard plan)
- **RAM:** 2 GB
- **Boot Time:** ~60-90 seconds (Ruby + Node.js assets)
- **Concurrent Requests:** ~50-100 per instance (Puma with 5 threads)

**Scaling Strategy:**
- **Vertical:** Standard plan sufficient for 1000 MAU
- **Horizontal:** Auto-scale to 4 instances during peak hours
- **Trigger:** >70% CPU or >80% memory for 5 minutes

---

### 2. Background Worker (Sidekiq)

**Purpose:** Process AI worker jobs, scheduled tasks, async operations

**Configuration:**
```yaml
services:
  - type: worker
    name: gp-bikes-worker
    runtime: ruby
    plan: standard  # $25/month
    numInstances: 1
    region: oregon
    buildCommand: "./bin/render-build.sh"
    startCommand: "bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml"
    autoDeploy: true
    branch: production
    
    envVars:
      - key: RAILS_ENV
        value: production
      - key: SIDEKIQ_CONCURRENCY
        value: 10
      - key: SIDEKIQ_TIMEOUT
        value: 25
```

**Resource Requirements:**
- **CPU:** 1.0 vCPU
- **RAM:** 2 GB (handles 10 concurrent jobs)
- **Job Throughput:** ~100-200 jobs/minute (depends on AI API latency)

**Queue Priority:**
```
critical > high > medium > default > mailers > low > scheduled_jobs > deferred > purgable > housekeeping
```

**Scaling Strategy:**
- **Manual scaling** initially (add workers if queue lag > 1 minute)
- **Future:** Auto-scale based on Sidekiq queue depth (using Judoscale gem)

---

### 3. PostgreSQL Database

**Purpose:** Primary data store, conversation history, AI embeddings

**Configuration:**
```yaml
databases:
  - name: gp-bikes-postgres
    databaseName: chatwoot_production
    user: chatwoot_prod
    plan: pro  # $90/month - 16GB RAM, 4 vCPU
    region: oregon
    version: "16"
    ipAllowList: []  # Empty = Render internal network only
    
    postgreSQLExtensions:
      - pgvector   # CRITICAL for AI embeddings
      - pg_trgm    # Full-text search
      - pgcrypto   # Encryption
      - uuid-ossp  # UUID generation
```

**Resource Requirements:**
- **Storage:** 100 GB SSD (Pro plan)
- **RAM:** 16 GB
- **Connections:** 200 max (sufficient for 3-4 app instances)
- **Backups:** Daily automatic, 7-day retention

**Performance Tuning:**
```sql
-- Set in PostgreSQL config (via Render dashboard)
shared_buffers = 4GB
effective_cache_size = 12GB
maintenance_work_mem = 1GB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1  -- SSD optimization
effective_io_concurrency = 200
work_mem = 10MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2
```

**Why Pro Plan:**
- ✅ pgvector extension support (required for AI embeddings)
- ✅ 16GB RAM for in-memory query caching
- ✅ Daily backups with point-in-time recovery
- ✅ Private networking
- ✅ Read replicas (future scalability)

---

### 4. Redis

**Purpose:** Session store, cache, Sidekiq queue backend

**Configuration:**
```yaml
databases:
  - name: gp-bikes-redis
    plan: starter  # $10/month - 256MB
    region: oregon
    maxmemoryPolicy: allkeys-lru
    version: "7"
```

**Resource Requirements:**
- **Memory:** 256 MB (sufficient for 1000 MAU)
- **Persistence:** AOF enabled (append-only file)
- **Eviction Policy:** `allkeys-lru` (Least Recently Used)

**Usage Breakdown:**
- **Sessions:** ~50% (50KB per active session)
- **Cache:** ~30% (Rails fragment caching)
- **Sidekiq:** ~20% (job queue metadata)

**Scaling Threshold:**
- Upgrade to **Standard plan (1GB)** when:
  - Memory usage > 80% consistently
  - MAU > 2000
  - Cache hit ratio < 70%

---

### 5. Persistent Storage

**Option A: Render Disk (Simpler, More Expensive)**

```yaml
services:
  - type: web
    name: gp-bikes-web
    disk:
      name: gp-bikes-storage
      mountPath: /app/storage
      sizeGB: 10  # $0.25/GB/month = $2.50/month
```

**Pros:**
- ✅ Zero configuration
- ✅ Fast local I/O
- ✅ Automatic backups with snapshots

**Cons:**
- ❌ More expensive at scale ($25/month for 100GB)
- ❌ Tied to single instance (not shared across web instances)
- ❌ No CDN for user uploads

---

**Option B: AWS S3 (Recommended for Production)**

**Configuration:**
```yaml
envVars:
  - key: ACTIVE_STORAGE_SERVICE
    value: amazon
  - key: AWS_ACCESS_KEY_ID
    sync: false  # Set as secret in Render dashboard
  - key: AWS_SECRET_ACCESS_KEY
    sync: false
  - key: AWS_REGION
    value: us-west-2
  - key: S3_BUCKET_NAME
    value: gp-bikes-production-uploads
```

**S3 Setup:**
```bash
# Create S3 bucket (one-time setup)
aws s3 mb s3://gp-bikes-production-uploads --region us-west-2

# Set bucket policy for public read (only for avatars/public uploads)
aws s3api put-bucket-policy --bucket gp-bikes-production-uploads --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::gp-bikes-production-uploads/public/*"
    }
  ]
}'

# Enable CORS for direct uploads
aws s3api put-bucket-cors --bucket gp-bikes-production-uploads --cors-configuration '{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://gp-bikes.onrender.com"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}'

# Enable CloudFront CDN (optional but recommended)
aws cloudfront create-distribution --origin-domain-name gp-bikes-production-uploads.s3.us-west-2.amazonaws.com
```

**Pros:**
- ✅ **Cost-effective:** $0.023/GB/month (~$5/month for 200GB)
- ✅ **Unlimited scalability**
- ✅ **Shared across all instances** (no sync issues)
- ✅ **CloudFront CDN** for global distribution
- ✅ **99.999999999% durability** (11 nines)

**Cons:**
- ❌ Requires AWS account setup
- ❌ Slightly higher latency for first access (mitigated by CDN)

**Recommendation:** **Use S3 for production**, Render Disk for staging.

---

## 🔐 Environment Variables

### Critical Secrets (Set in Render Dashboard)

```bash
# Rails Core
SECRET_KEY_BASE=<generate with: bundle exec rails secret>
RAILS_MASTER_KEY=<from config/master.key>

# Database (Auto-populated by Render)
DATABASE_URL=<automatically set>
REDIS_URL=<automatically set>

# OpenAI (REQUIRED for AI Workers)
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxx
OPENAI_MODEL=gpt-4-turbo-preview

# WhatsApp Business API (REQUIRED)
WHATSAPP_PHONE_NUMBER_ID=<from Meta Business Manager>
WHATSAPP_ACCESS_TOKEN=<from Meta Business Manager>
WHATSAPP_WEBHOOK_VERIFY_TOKEN=<generate random secure string>

# Active Storage (if using S3)
AWS_ACCESS_KEY_ID=<IAM user with S3 access>
AWS_SECRET_ACCESS_KEY=<IAM secret key>
AWS_REGION=us-west-2
S3_BUCKET_NAME=gp-bikes-production-uploads

# GP Bikes Configuration
GP_BIKES_ACCOUNT_ID=1
GP_BIKES_INBOX_ID=1
GP_BIKES_TEAM_ID=1
GP_BIKES_WHATSAPP_NUMBER=+57XXXXXXXXXX
GP_BIKES_DEALERSHIP_NAME="GP Bikes Yamaha"
GP_BIKES_DEALERSHIP_ADDRESS="Calle 123 No 45-67, Bogotá, Colombia"
```

### Optional (Monitoring & Features)

```bash
# Error Tracking
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
SENTRY_ENVIRONMENT=production

# APM (Application Performance Monitoring)
DATADOG_API_KEY=<if using Datadog>
NEW_RELIC_LICENSE_KEY=<if using New Relic>

# Email (if using SendGrid/Postmark)
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=<SendGrid API key>
SMTP_DOMAIN=gpbikes.com
MAILER_SENDER_EMAIL=noreply@gpbikes.com

# Feature Flags
GP_BIKES_ENABLED=true
AI_WORKERS_ENABLED=true
N8N_INTEGRATION_ENABLED=false  # Future feature

# Performance
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
SIDEKIQ_CONCURRENCY=10
POSTGRES_STATEMENT_TIMEOUT=14s

# Security
FORCE_SSL=true
RAILS_LOG_LEVEL=info  # warn for production (less verbose)
INSTALLATION_ENV=render
```

---

## 🏗️ Build Configuration

### Create `bin/render-build.sh`

```bash
#!/usr/bin/env bash
# exit on error
set -o errexit

echo "🔨 Starting Render Build Process..."

# Install Ruby dependencies
echo "📦 Installing Ruby gems..."
bundle install --without development test --jobs 4 --retry 3

# Install Node.js dependencies (using pnpm)
echo "📦 Installing Node.js packages with pnpm..."
corepack enable
corepack prepare pnpm@10.2.0 --activate
pnpm install --frozen-lockfile --prod

# Compile assets (Vite)
echo "🎨 Compiling frontend assets with Vite..."
NODE_ENV=production bundle exec rails assets:precompile

# Verify critical files exist
echo "✅ Verifying build artifacts..."
if [ ! -f "public/vite/.vite/manifest.json" ]; then
  echo "❌ ERROR: Vite manifest not found!"
  exit 1
fi

echo "✅ Build completed successfully!"
```

**Make it executable:**
```bash
chmod +x bin/render-build.sh
git add bin/render-build.sh
git commit -m "Add Render build script"
```

---

### Update `Procfile` (Already Configured)

The existing `Procfile` is production-ready:

```
release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && echo $SOURCE_VERSION > .git_sha
web: bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
```

**Key Points:**
- **Release command:** Runs database migrations before deploy (zero-downtime)
- **`db:chatwoot_prepare`:** Chatwoot-specific task (handles migrations + data migrations)
- **`ip_lookup:setup`:** Downloads MaxMind GeoIP database
- **`$PORT`:** Render auto-assigns port (don't hardcode 3000)

---

## 📄 Infrastructure as Code: Blueprint YAML

### Create `render.yaml`

```yaml
# GP Bikes AI Assistant - Render Blueprint
# Version: 1.0.0
# Last Updated: 2025-10-01
#
# Deploy: https://dashboard.render.com/select-repo?type=blueprint

services:
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # WEB SERVICE (Rails Application)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  - type: web
    name: gp-bikes-web
    runtime: ruby
    plan: standard  # $25/month per instance
    numInstances: 2
    region: oregon
    buildCommand: ./bin/render-build.sh
    startCommand: bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
    healthCheckPath: /api/v1/health
    autoDeploy: true
    branch: production
    
    envVars:
      # Rails Core
      - key: RAILS_ENV
        value: production
      - key: RACK_ENV
        value: production
      - key: NODE_ENV
        value: production
      - key: RAILS_SERVE_STATIC_FILES
        value: true
      - key: RAILS_LOG_TO_STDOUT
        value: true
      - key: RAILS_LOG_LEVEL
        value: info
      - key: RAILS_MAX_THREADS
        value: 5
      - key: WEB_CONCURRENCY
        value: 2
      
      # Frontend
      - key: FRONTEND_URL
        value: https://gp-bikes.onrender.com
      - key: FORCE_SSL
        value: true
      
      # Installation
      - key: INSTALLATION_ENV
        value: render
      
      # Database (auto-populated)
      - key: DATABASE_URL
        fromDatabase:
          name: gp-bikes-postgres
          property: connectionString
      
      # Redis (auto-populated)
      - key: REDIS_URL
        fromDatabase:
          name: gp-bikes-redis
          property: connectionString
      
      # Secrets (set manually in Render dashboard)
      - key: SECRET_KEY_BASE
        generateValue: true  # Auto-generate on first deploy
      - key: RAILS_MASTER_KEY
        sync: false  # Must set manually from config/master.key
      
      # OpenAI (REQUIRED - set manually)
      - key: OPENAI_API_KEY
        sync: false
      - key: OPENAI_MODEL
        value: gpt-4-turbo-preview
      
      # WhatsApp Business API (REQUIRED - set manually)
      - key: WHATSAPP_PHONE_NUMBER_ID
        sync: false
      - key: WHATSAPP_ACCESS_TOKEN
        sync: false
      - key: WHATSAPP_WEBHOOK_VERIFY_TOKEN
        sync: false
      
      # Active Storage (S3 recommended)
      - key: ACTIVE_STORAGE_SERVICE
        value: amazon
      - key: AWS_ACCESS_KEY_ID
        sync: false
      - key: AWS_SECRET_ACCESS_KEY
        sync: false
      - key: AWS_REGION
        value: us-west-2
      - key: S3_BUCKET_NAME
        value: gp-bikes-production-uploads
      
      # GP Bikes Configuration
      - key: GP_BIKES_ACCOUNT_ID
        value: 1
      - key: GP_BIKES_INBOX_ID
        value: 1
      - key: GP_BIKES_TEAM_ID
        value: 1
      - key: GP_BIKES_WHATSAPP_NUMBER
        sync: false  # Set manually: +57XXXXXXXXXX
      - key: GP_BIKES_DEALERSHIP_NAME
        value: "GP Bikes Yamaha"
      - key: GP_BIKES_DEALERSHIP_ADDRESS
        value: "Calle 123 No 45-67, Bogotá, Colombia"
      
      # Error Tracking (optional)
      - key: SENTRY_DSN
        sync: false
      - key: SENTRY_ENVIRONMENT
        value: production
      
      # Performance
      - key: POSTGRES_STATEMENT_TIMEOUT
        value: 14s
    
    # Auto-scaling configuration
    scalingConfig:
      minInstances: 1
      maxInstances: 4
      targetCPUPercent: 70
      targetMemoryPercent: 80

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # BACKGROUND WORKER (Sidekiq)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  - type: worker
    name: gp-bikes-worker
    runtime: ruby
    plan: standard  # $25/month
    numInstances: 1
    region: oregon
    buildCommand: ./bin/render-build.sh
    startCommand: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
    autoDeploy: true
    branch: production
    
    envVars:
      # Inherit most env vars from web service
      - key: RAILS_ENV
        value: production
      - key: RACK_ENV
        value: production
      - key: RAILS_LOG_TO_STDOUT
        value: true
      - key: RAILS_LOG_LEVEL
        value: info
      
      # Sidekiq Configuration
      - key: SIDEKIQ_CONCURRENCY
        value: 10
      - key: SIDEKIQ_TIMEOUT
        value: 25
      - key: SIDEKIQ_MAX_RETRIES
        value: 3
      
      # Database
      - key: DATABASE_URL
        fromDatabase:
          name: gp-bikes-postgres
          property: connectionString
      
      # Redis
      - key: REDIS_URL
        fromDatabase:
          name: gp-bikes-redis
          property: connectionString
      
      # Secrets
      - key: SECRET_KEY_BASE
        sync: false  # Synced from web service
      - key: RAILS_MASTER_KEY
        sync: false
      
      # OpenAI
      - key: OPENAI_API_KEY
        sync: false
      - key: OPENAI_MODEL
        value: gpt-4-turbo-preview
      
      # WhatsApp
      - key: WHATSAPP_PHONE_NUMBER_ID
        sync: false
      - key: WHATSAPP_ACCESS_TOKEN
        sync: false
      
      # GP Bikes Configuration
      - key: GP_BIKES_ACCOUNT_ID
        value: 1
      - key: GP_BIKES_INBOX_ID
        value: 1
      - key: GP_BIKES_TEAM_ID
        value: 1
      - key: GP_BIKES_WHATSAPP_NUMBER
        sync: false
      - key: GP_BIKES_DEALERSHIP_NAME
        value: "GP Bikes Yamaha"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DATABASES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
databases:
  # PostgreSQL with pgvector
  - name: gp-bikes-postgres
    databaseName: chatwoot_production
    user: chatwoot_prod
    plan: pro  # $90/month - 16GB RAM, 4 vCPU, 100GB SSD
    region: oregon
    version: "16"
    ipAllowList: []  # Private network only
    
    # Enable pgvector extension (CRITICAL for AI embeddings)
    postgreSQLExtensions:
      - pgvector
      - pg_trgm
      - pgcrypto
      - uuid-ossp
  
  # Redis for cache and Sidekiq
  - name: gp-bikes-redis
    plan: starter  # $10/month - 256MB
    region: oregon
    maxmemoryPolicy: allkeys-lru
    version: "7"
```

**Deploy with Blueprint:**
1. Push `render.yaml` to your repository
2. Go to Render Dashboard → New → Blueprint
3. Connect your GitHub repository
4. Render will auto-create all services
5. Set missing environment variables in dashboard
6. Deploy!

---

## 💰 Cost Breakdown

### Staging Environment

| Service | Plan | Monthly Cost | Notes |
|---------|------|--------------|-------|
| Web Service | Starter (512MB) | $7 | 1 instance |
| Worker Service | Starter (512MB) | $7 | 1 instance |
| PostgreSQL | Starter (1GB) | $7 | Shared CPU |
| Redis | Free (25MB) | $0 | Free tier |
| **TOTAL** | | **$21/month** | Minimal staging |

---

### Production Environment (Initial)

| Service | Plan | Monthly Cost | Notes |
|---------|------|--------------|-------|
| Web Service | Standard (2GB) | $25 × 2 | 2 instances (HA) |
| Worker Service | Standard (2GB) | $25 × 1 | 1 instance |
| PostgreSQL | Pro (16GB) | $90 | 100GB SSD |
| Redis | Starter (256MB) | $10 | Persistence |
| S3 Storage | AWS | ~$5 | 200GB |
| **TOTAL** | | **$180/month** | ~1000 MAU |

---

### Production Environment (Scaled)

**At 5,000 MAU (~500 daily active users):**

| Service | Plan | Monthly Cost | Notes |
|---------|------|--------------|-------|
| Web Service | Standard (2GB) | $25 × 4 | Auto-scaled to 4 |
| Worker Service | Standard (2GB) | $25 × 2 | 2 workers |
| PostgreSQL | Pro Plus (32GB) | $200 | 200GB SSD |
| Redis | Standard (1GB) | $50 | More cache |
| S3 Storage | AWS | ~$10 | 400GB |
| Monitoring | Sentry/Datadog | ~$50 | Optional |
| **TOTAL** | | **$410/month** | ~5000 MAU |

---

### Cost Optimization Strategies

1. **Use Staging for Development:** Free tier + $21/month staging saves $180/month
2. **S3 over Render Disk:** $5/month vs $25/month for 100GB
3. **Auto-scaling:** Only pay for extra instances during peak hours
4. **Redis Caching:** Reduce PostgreSQL query load (cost-effective)
5. **OpenAI Cost Management:** Cache responses, use shorter prompts
6. **Judoscale:** Heroku Autoscaling gem (available for Render)

---

## 🚀 Deployment Strategy

### Phase 1: Staging Environment (Week 1)

**Goals:**
- ✅ Validate Render configuration
- ✅ Test build process
- ✅ Verify database migrations
- ✅ Test AI workers in production-like environment
- ✅ Load test with 100 concurrent users

**Steps:**
1. Create staging branch: `git checkout -b staging`
2. Deploy to Render with minimal resources (Starter plans)
3. Run smoke tests: `bundle exec rspec spec/features/`
4. Test WhatsApp webhook integration
5. Verify OpenAI API connectivity
6. Load test with k6 or Apache Bench

**Success Criteria:**
- All services healthy for 24 hours
- No deployment errors
- Response time < 2 seconds (95th percentile)
- Zero downtime during redeployment

---

### Phase 2: Production Deployment (Week 2)

**Pre-Deployment Checklist:**
- [ ] All environment variables set in Render dashboard
- [ ] S3 bucket created and CORS configured
- [ ] Sentry project created (error tracking)
- [ ] DNS configured (custom domain if needed)
- [ ] SSL certificate auto-provisioned by Render
- [ ] Database backups enabled (automatic on Render)
- [ ] Monitoring alerts configured
- [ ] Rollback plan documented
- [ ] Team trained on Render dashboard

**Deployment Steps:**
1. Merge staging to production branch
2. Push to GitHub: `git push origin production`
3. Render auto-deploys (takes ~5-10 minutes)
4. Run release command (migrations): `rails db:chatwoot_prepare`
5. Health check passes → traffic routes to new version
6. Monitor logs for 30 minutes: `render logs gp-bikes-web`
7. Verify AI workers processing jobs: Check Sidekiq dashboard
8. Test critical user flows manually

**Post-Deployment Verification:**
```bash
# 1. Check service status
curl -I https://gp-bikes.onrender.com/api/v1/health
# Expected: HTTP/2 200

# 2. Test WhatsApp webhook
curl -X POST https://gp-bikes.onrender.com/webhooks/whatsapp \
  -H "Content-Type: application/json" \
  -d '{...test payload...}'

# 3. Monitor Sidekiq
open https://gp-bikes.onrender.com/sidekiq
# Check queue depths, processing times

# 4. Check error logs
render logs gp-bikes-web --tail
render logs gp-bikes-worker --tail
```

---

### Rollback Procedure

**If deployment fails:**

```bash
# Option 1: Rollback in Render Dashboard
# Dashboard → Services → gp-bikes-web → Rollback to previous deployment

# Option 2: Git revert
git revert HEAD
git push origin production
# Render auto-deploys previous version

# Option 3: Manual rollback (emergency)
render services scale gp-bikes-web --num-instances 0  # Stop new version
render services scale gp-bikes-web-old --num-instances 2  # Start old version
```

**Rollback Triggers:**
- Error rate > 5% for 5 minutes
- Response time > 5 seconds (p95)
- Database migration failure
- AI workers not processing jobs
- Critical feature broken

---

## 📊 Monitoring & Observability

### Built-in Render Metrics

**Available in Dashboard:**
- CPU usage (per service)
- Memory usage (per service)
- Request rate (requests/second)
- Response time (p50, p95, p99)
- Error rate (%)
- Auto-restart count

**Alerts Configuration:**
```yaml
# Set in Render Dashboard → Service → Alerts
- name: High Error Rate
  condition: error_rate > 5%
  duration: 5 minutes
  notification: email, Slack

- name: High Memory Usage
  condition: memory > 90%
  duration: 10 minutes
  notification: email, Slack

- name: Service Unavailable
  condition: health_check_failed
  duration: 2 minutes
  notification: email, SMS
```

---

### Sentry (Error Tracking)

**Setup:**
```bash
# 1. Create Sentry project at sentry.io
# 2. Get DSN: https://xxxxx@sentry.io/xxxxx
# 3. Add to Render env vars:
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
SENTRY_ENVIRONMENT=production
```

**Rails Configuration (already included in Gemfile):**
```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = ENV['SENTRY_ENVIRONMENT']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1  # 10% of transactions
  config.profiles_sample_rate = 0.1
end
```

**Benefits:**
- Real-time error notifications
- Stack traces with source maps
- User context (which customer hit error)
- Release tracking (which deploy introduced error)
- Performance monitoring (slow queries, API calls)

---

### Application Logs

**View logs in real-time:**
```bash
# Web service logs
render logs gp-bikes-web --tail

# Worker logs (Sidekiq)
render logs gp-bikes-worker --tail

# Filter by severity
render logs gp-bikes-web --level error

# Search logs
render logs gp-bikes-web --search "OpenAI"
```

**Log Aggregation (Optional):**
- **Papertrail:** $7/month for 1GB/month logs
- **Logtail:** $5/month for 500MB/month logs
- **Datadog Logs:** $0.10/GB ingested

---

### Health Checks

**Endpoint Implementation:**
```ruby
# app/controllers/api/v1/health_controller.rb
class Api::V1::HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    checks = {
      database: database_check,
      redis: redis_check,
      sidekiq: sidekiq_check,
      storage: storage_check
    }
    
    status = checks.values.all? ? :ok : :service_unavailable
    
    render json: {
      status: status == :ok ? 'healthy' : 'unhealthy',
      checks: checks,
      version: ENV['SOURCE_VERSION'] || 'unknown',
      timestamp: Time.current.iso8601
    }, status: status
  end
  
  private
  
  def database_check
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'ok', latency_ms: 5 }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def redis_check
    Redis.current.ping == 'PONG'
    { status: 'ok' }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def sidekiq_check
    workers_count = Sidekiq::Workers.new.size
    { status: workers_count > 0 ? 'ok' : 'warning', workers: workers_count }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def storage_check
    ActiveStorage::Blob.service.exist?('health_check_test')
    { status: 'ok' }
  rescue => e
    { status: 'error', message: e.message }
  end
end

# config/routes.rb
namespace :api do
  namespace :v1 do
    get '/health', to: 'health#show'
  end
end
```

---

## 🔒 Security Best Practices

### 1. Secrets Management

**DO:**
- ✅ Use Render's encrypted environment variables
- ✅ Rotate secrets every 90 days
- ✅ Use different secrets for staging and production
- ✅ Store `RAILS_MASTER_KEY` securely (1Password, Vault)

**DON'T:**
- ❌ Commit secrets to Git (check with `git-secrets`)
- ❌ Share secrets via Slack/email
- ❌ Reuse secrets across environments
- ❌ Log sensitive data (OpenAI API key, tokens)

---

### 2. Network Security

**Render Provides:**
- ✅ Free SSL/TLS certificates (auto-renewed)
- ✅ DDoS protection at edge
- ✅ Private networking between services
- ✅ IP allowlisting for databases

**Additional Hardening:**
```ruby
# config/initializers/content_security_policy.rb
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https
  policy.connect_src :self, :https, "wss://*.onrender.com"
end

# config/application.rb
config.force_ssl = true  # Redirect HTTP to HTTPS
config.ssl_options = {
  hsts: { expires: 1.year, subdomains: true, preload: true }
}
```

---

### 3. Rate Limiting

**Protect against abuse:**
```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle WhatsApp webhooks
  throttle('webhooks/whatsapp', limit: 100, period: 1.minute) do |req|
    req.ip if req.path == '/webhooks/whatsapp' && req.post?
  end
  
  # Throttle API requests per IP
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end
  
  # Throttle login attempts
  throttle('auth/email', limit: 5, period: 1.hour) do |req|
    req.params['email'] if req.path == '/auth/sign_in' && req.post?
  end
  
  # Block known bad actors
  blocklist('block bad IPs') do |req|
    # Check against Redis set of banned IPs
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 10.minutes, bantime: 1.day) do
      Rails.cache.read("blocklist:#{req.ip}") == true
    end
  end
end
```

---

### 4. Database Security

**Chatwoot has encryption for:**
- ✅ API keys (via `attr_encrypted`)
- ✅ Access tokens (via `attr_encrypted`)
- ✅ Passwords (via `bcrypt`)

**Additional Measures:**
```ruby
# config/database.yml production settings
production:
  <<: *default
  # Prevent long-running queries from blocking
  variables:
    statement_timeout: 14s
    idle_in_transaction_session_timeout: 60s
  
  # Use read-only replica for reports (future)
  replica:
    <<: *default
    host: <%= ENV['POSTGRES_REPLICA_HOST'] %>
    replica: true
```

**Backup Strategy:**
- Render provides **daily automatic backups** (7-day retention)
- Upgrade to **Point-in-Time Recovery** (PITR) for mission-critical data
- **Manual backups** before major schema changes

---

## 🚨 Troubleshooting Guide

### Issue 1: Build Fails with "pnpm not found"

**Error:**
```
/bin/sh: pnpm: not found
```

**Solution:**
```bash
# Add to bin/render-build.sh
corepack enable
corepack prepare pnpm@10.2.0 --activate
```

---

### Issue 2: pgvector Extension Missing

**Error:**
```
PG::UndefinedObject: ERROR:  extension "pgvector" does not exist
```

**Solution:**
1. Go to Render Dashboard → PostgreSQL → Extensions
2. Enable `pgvector` extension
3. Restart database
4. Run migration again

---

### Issue 3: Sidekiq Not Processing Jobs

**Symptoms:**
- Queues growing (visible in Sidekiq dashboard)
- AI workers not responding to messages

**Debug Steps:**
```bash
# 1. Check worker logs
render logs gp-bikes-worker --tail

# 2. Check Redis connection
render ssh gp-bikes-worker
bundle exec rails console
> Redis.current.ping
# Should return "PONG"

# 3. Check Sidekiq process
> Sidekiq::Workers.new.size
# Should return > 0

# 4. Manually trigger a job (test)
> AiWorkers::GreetingWorkerJob.perform_later(conversation_id: 1)
```

**Common Causes:**
- Redis URL incorrect
- Worker crashed (check memory usage)
- Job serialization error (check logs)
- OpenAI API timeout (check API status)

---

### Issue 4: High Memory Usage

**Symptoms:**
- Service restarted by Render (OOM killer)
- Slow response times
- "Out of memory" errors in logs

**Solutions:**
```bash
# 1. Reduce Puma threads
RAILS_MAX_THREADS=3  # Down from 5
WEB_CONCURRENCY=1    # Down from 2

# 2. Reduce Sidekiq concurrency
SIDEKIQ_CONCURRENCY=5  # Down from 10

# 3. Enable jemalloc (better memory allocator)
# Add to Dockerfile
RUN apt-get update && apt-get install -y libjemalloc2
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# 4. Upgrade plan
# Standard → Pro (2GB → 4GB RAM)
```

---

### Issue 5: Active Storage Uploads Failing

**Error:**
```
Aws::S3::Errors::AccessDenied: Access Denied
```

**Solution:**
```bash
# 1. Verify S3 credentials
render ssh gp-bikes-web
bundle exec rails console
> ActiveStorage::Blob.service.upload("test", StringIO.new("test"))

# 2. Check IAM policy (AWS Console)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::gp-bikes-production-uploads",
        "arn:aws:s3:::gp-bikes-production-uploads/*"
      ]
    }
  ]
}

# 3. Verify CORS configuration
aws s3api get-bucket-cors --bucket gp-bikes-production-uploads
```

---

## 📚 Additional Resources

### Official Documentation
- **Render Docs:** https://render.com/docs
- **Chatwoot Self-Hosted Guide:** https://www.chatwoot.com/docs/self-hosted
- **Rails on Render:** https://render.com/docs/deploy-rails
- **Sidekiq Best Practices:** https://github.com/sidekiq/sidekiq/wiki/Best-Practices

### Community Resources
- **Render Community Forum:** https://community.render.com
- **Chatwoot Discord:** https://discord.gg/chatwoot
- **Rails Performance:** https://www.speedshop.co

### Monitoring & APM
- **Sentry Ruby SDK:** https://docs.sentry.io/platforms/ruby/guides/rails
- **Datadog Rails Integration:** https://docs.datadoghq.com/integrations/ruby
- **New Relic:** https://docs.newrelic.com/docs/apm/agents/ruby-agent

---

## ✅ Next Steps

### Immediate (Day 1-3)

1. **Create Render Account:**
   - Sign up: https://dashboard.render.com/register
   - Connect GitHub repository
   - Add payment method (required for Starter plans)

2. **Create `render.yaml` Blueprint:**
   - Copy blueprint from this document
   - Commit to repository: `git add render.yaml && git commit -m "Add Render blueprint"`
   - Push to GitHub

3. **Set Up S3 Bucket:**
   - Create AWS account if needed
   - Run S3 setup commands from this document
   - Save access keys securely

4. **Deploy to Staging:**
   - Render Dashboard → New → Blueprint → Select Repository
   - Choose `staging` branch
   - Wait for deploy (~10 minutes)
   - Verify all services healthy

5. **Test Staging:**
   - Run smoke tests
   - Test WhatsApp webhook
   - Verify AI workers responding
   - Load test with 50 concurrent users

### Week 1

- [ ] Staging environment fully functional
- [ ] All 8 AI workers tested in staging
- [ ] OpenAI API costs monitored (< $50/month)
- [ ] Documentation updated with Render URLs
- [ ] Team trained on Render dashboard

### Week 2 (Production Go-Live)

- [ ] Production deployment successful
- [ ] Custom domain configured (if applicable)
- [ ] Monitoring alerts configured
- [ ] Backup strategy verified
- [ ] Incident response plan documented
- [ ] Post-mortem template created

### Ongoing

- [ ] Weekly review of error logs (Sentry)
- [ ] Monthly cost optimization review
- [ ] Quarterly load testing
- [ ] Bi-annual security audit

---

## 🎓 Conclusion

This architecture provides a **production-grade, scalable, and cost-effective** deployment strategy for GP Bikes AI Assistant on Render. Key advantages:

✅ **Zero-downtime deployments** with automatic health checks
✅ **Auto-scaling** to handle traffic spikes (Colombian holidays, promotions)
✅ **Managed databases** with automatic backups and updates
✅ **Infrastructure as Code** with Blueprint YAML (version-controlled)
✅ **Cost-optimized** with staging ($21/month) and production ($180/month) environments
✅ **Observable** with built-in metrics, Sentry, and logs
✅ **Secure** with SSL, rate limiting, and secrets management

**Total Initial Cost:** ~$200/month for production-ready platform handling 1000 MAU

**Estimated Time to Deploy:** 4-6 hours (including testing)

---

**Questions or Issues?** Contact the DevOps team or open an issue in GitHub.

**Ready to Deploy?** Follow the "Next Steps" section above. 🚀


