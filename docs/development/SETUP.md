# Development Environment Setup

Complete guide to setting up the GP Bikes AI Assistant development environment on your local machine.

**Estimated Time:** 30-45 minutes (first time)
**Difficulty:** Beginner-friendly
**Last Updated:** 2025-09-30

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start (5 Minutes)](#quick-start-5-minutes)
- [Detailed Setup](#detailed-setup)
  - [1. Fork and Clone Repository](#1-fork-and-clone-repository)
  - [2. Environment Configuration](#2-environment-configuration)
  - [3. Start Services](#3-start-services)
  - [4. Database Setup](#4-database-setup)
  - [5. Access Application](#5-access-application)
- [Verification Checklist](#verification-checklist)
- [Troubleshooting](#troubleshooting)
- [Development Workflow](#development-workflow)
- [Next Steps](#next-steps)

---

## Prerequisites

Before starting, ensure you have:

### Required Software

- **Docker Desktop 24.x or higher**
  - Download: https://www.docker.com/products/docker-desktop
  - Minimum: 20GB free disk space, 8GB RAM allocated to Docker
  - **Mac M1/M2 Users:** Ensure "Use Rosetta for x86/amd64 emulation" is enabled in Docker settings

- **Git 2.x or higher**
  - Download: https://git-scm.com/downloads
  - Verify: `git --version`
  - SSH keys configured for GitHub: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

- **Text Editor**
  - Recommended: [VS Code](https://code.visualstudio.com/) with Ruby, Docker extensions
  - Alternatives: RubyMine, Sublime Text, Vim

### Optional but Recommended

- **Terminal Emulator**
  - Mac: iTerm2
  - Windows: Windows Terminal
  - Linux: Built-in terminal is fine

- **Docker Extensions**
  - VS Code: "Docker" extension by Microsoft
  - VS Code: "Remote - Containers" for devcontainer support

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 8 GB | 16 GB |
| Disk Space | 20 GB free | 50 GB free |
| OS | macOS 11+, Ubuntu 20.04+, Windows 10+ | Latest stable |

---

## Quick Start (5 Minutes)

For experienced developers who want to get running immediately:

```bash
# 1. Fork repository on GitHub (see FORK_STRATEGY.md)
# 2. Clone your fork
git clone git@github.com:YOUR-ORG/gp-bikes-ai-assistant.git "GP Bikes"
cd "GP Bikes"

# 3. Set up environment
cp .env.development.example .env.development
./bin/generate-secrets

# 4. Start all services
docker-compose up -d

# 5. Setup database
docker-compose exec app rails db:setup

# 6. Open application
open http://localhost:3000
```

**Done!** Skip to [Verification Checklist](#verification-checklist).

If you encounter issues, continue to [Detailed Setup](#detailed-setup).

---

## Detailed Setup

### 1. Fork and Clone Repository

#### Step 1.1: Fork Chatwoot on GitHub

We're building on top of Chatwoot, so first you need to fork their repository:

1. **Navigate to Chatwoot:**
   - Open: https://github.com/chatwoot/chatwoot

2. **Click "Fork"** (top-right corner)

3. **Configure your fork:**
   - **Owner:** Your GitHub organization (e.g., `gp-bikes-yamaha`)
   - **Repository name:** `gp-bikes-ai-assistant`
   - **Description:** "AI-powered WhatsApp automation for Yamaha GP Bikes - Built on Chatwoot"
   - **Visibility:**
     - `Private` (recommended for business)
     - `Public` (if building open source)
   - ✅ **Check:** "Copy the main branch only"

4. **Click "Create fork"**

5. **Wait** for fork to complete (30-60 seconds)

#### Step 1.2: Clone Your Fork

Open your terminal and run:

```bash
# Navigate to where you keep projects
cd ~/Projects  # or wherever you prefer

# Clone YOUR fork (replace YOUR-ORG with your GitHub organization)
git clone git@github.com:YOUR-ORG/gp-bikes-ai-assistant.git "GP Bikes"

# Navigate into directory
cd "GP Bikes"

# Verify you're on main branch
git branch
# Expected output: * main
```

**Troubleshooting Clone Issues:**

- **Error: "Permission denied (publickey)"**
  - Solution: Set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
  - Or use HTTPS: `git clone https://github.com/YOUR-ORG/gp-bikes-ai-assistant.git "GP Bikes"`

- **Error: "Repository not found"**
  - Solution: Check the fork was created successfully on GitHub
  - Verify you replaced `YOUR-ORG` with your actual organization name

#### Step 1.3: Add Upstream Remote

This allows you to pull updates from Chatwoot:

```bash
# Add Chatwoot as upstream
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Fetch upstream branches
git fetch upstream

# Verify remotes
git remote -v
# Should show:
# origin    git@github.com:YOUR-ORG/gp-bikes-ai-assistant.git (fetch)
# origin    git@github.com:YOUR-ORG/gp-bikes-ai-assistant.git (push)
# upstream  https://github.com/chatwoot/chatwoot.git (fetch)
# upstream  https://github.com/chatwoot/chatwoot.git (push)
```

#### Step 1.4: Create Development Branch

```bash
# Create development branch
git checkout -b gp-bikes-develop

# Push to remote
git push -u origin gp-bikes-develop

# This is your main working branch
```

**Why two branches?**
- `main`: Stays synced with Chatwoot upstream (clean)
- `gp-bikes-develop`: Contains our GP Bikes customizations

See `docs/development/FORK_STRATEGY.md` for full branching strategy.

---

### 2. Environment Configuration

#### Step 2.1: Create Environment File

The project needs environment variables to run. We provide a template:

```bash
# Copy the example file
cp .env.development.example .env.development

# Verify file was created
ls -la .env.development
```

**Important:** `.env.development` contains secrets and is excluded from Git (in `.gitignore`). Never commit this file!

#### Step 2.2: Generate Secrets

We provide a script to generate secure secrets automatically:

```bash
# Run the secret generator
./bin/generate-secrets
```

**What this does:**
- Generates a cryptographically secure `SECRET_KEY_BASE`
- Generates a random `POSTGRES_PASSWORD`
- Generates a `WHATSAPP_WEBHOOK_VERIFY_TOKEN`
- Updates `.env.development` with these values

**Sample Output:**
```
=== GP Bikes Secret Generator ===

Found existing .env.development
Continue? (y/N): y

Generating secrets...

Generated:
  - SECRET_KEY_BASE (128 characters)
  - POSTGRES_PASSWORD (32 characters)
  - WHATSAPP_WEBHOOK_VERIFY_TOKEN (32 characters)

Updating .env.development...

✓ Updated SECRET_KEY_BASE
✓ Updated POSTGRES_PASSWORD
✓ Updated DATABASE_URL
✓ Updated WHATSAPP_WEBHOOK_VERIFY_TOKEN

Done!
```

#### Step 2.3: Add API Keys (Week 2+)

For now, the application will run without API keys. You'll add these later:

**OpenAI (Week 2 - when implementing AI Workers):**

1. Get API key from: https://platform.openai.com/api-keys
2. Open `.env.development` in your text editor
3. Find the line: `OPENAI_API_KEY=sk-proj-your-openai-api-key-here`
4. Replace with your actual key: `OPENAI_API_KEY=sk-proj-abc123...`
5. Save the file

**WhatsApp (Sprint 2 - when implementing WhatsApp integration):**

1. Get credentials from: https://developers.facebook.com/apps
2. Update these variables in `.env.development`:
   ```bash
   WHATSAPP_PHONE_NUMBER_ID=123456789
   WHATSAPP_ACCESS_TOKEN=EAAx...
   ```

**For now, you can skip these steps.** The app runs fine without them.

---

### 3. Start Services

#### Step 3.1: Start Docker Compose

This will start all services (PostgreSQL, Redis, Rails app, Sidekiq):

```bash
# Start all services in background
docker-compose up -d

# The -d flag means "detached mode" (runs in background)
```

**Expected Output:**
```
[+] Running 5/5
 ✔ Network gp-bikes-network    Created     0.1s
 ✔ Container gp-bikes-postgres  Started     2.3s
 ✔ Container gp-bikes-redis     Started     2.1s
 ✔ Container gp-bikes-app       Started     4.5s
 ✔ Container gp-bikes-sidekiq   Started     5.1s
```

**First Run Note:** The first time you run this, Docker will:
1. Download images (~2GB) - takes 5-10 minutes depending on internet
2. Build the application container - takes 5-10 minutes
3. Install Ruby gems and npm packages - takes 5-10 minutes

**Total first-run time: 15-30 minutes.** Subsequent starts take ~10 seconds.

#### Step 3.2: Check Service Status

```bash
# Check all services are running
docker-compose ps
```

**Expected Output:**
```
NAME                  IMAGE              STATUS              PORTS
gp-bikes-app         gp-bikes-app       Up (healthy)        0.0.0.0:3000->3000/tcp
gp-bikes-postgres    postgres:16-alpine Up (healthy)        0.0.0.0:5432->5432/tcp
gp-bikes-redis       redis:7-alpine     Up (healthy)        0.0.0.0:6379->6379/tcp
gp-bikes-sidekiq     gp-bikes-sidekiq   Up (healthy)
```

**All services should show "Up (healthy)".**

If any service shows "Restarting" or "Unhealthy", see [Troubleshooting](#troubleshooting).

#### Step 3.3: View Logs (Optional)

To see what's happening:

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app      # Rails application
docker-compose logs -f sidekiq  # Background jobs
docker-compose logs -f postgres # Database
docker-compose logs -f redis    # Cache

# Press Ctrl+C to stop viewing logs
```

---

### 4. Database Setup

Now that services are running, we need to create and populate the database:

#### Step 4.1: Create Database

```bash
# Create the database
docker-compose exec app rails db:create
```

**Expected Output:**
```
Created database 'chatwoot_dev'
```

#### Step 4.2: Run Migrations

```bash
# Run all database migrations
docker-compose exec app rails db:migrate
```

**Expected Output:**
```
== 20XX... CreateAccounts: migrating ===================================
-- create_table(:accounts)
   -> 0.0234s
== 20XX... CreateAccounts: migrated (0.0235s) ==========================

[... many more migrations ...]

== 20XX... AddIndexToMessages: migrating ================================
-- add_index(:messages, [:conversation_id, :created_at])
   -> 0.0123s
== 20XX... AddIndexToMessages: migrated (0.0124s) =======================
```

**This creates all database tables and indexes.**

#### Step 4.3: Seed Database (Optional)

Load sample data for development:

```bash
# Load seed data
docker-compose exec app rails db:seed
```

**Expected Output:**
```
Creating super admin user...
Email: admin@example.com
Password: password123

Creating sample account...
Creating sample inbox...
Creating sample contacts...
Creating sample conversations...

Done!
```

**Or, all in one command:**

```bash
# Create, migrate, and seed in one step
docker-compose exec app rails db:setup
```

---

### 5. Access Application

#### Step 5.1: Open Chatwoot UI

1. **Open your browser**
2. **Navigate to:** http://localhost:3000
3. **You should see:** Chatwoot login page

![Chatwoot Login Screen](https://www.chatwoot.com/docs/assets/images/login-screen.png)

#### Step 5.2: Log In

If you ran `db:seed`, use:

- **Email:** `admin@example.com`
- **Password:** `password123`

If you didn't seed, you'll see a signup form:

- **Full Name:** Your Name
- **Email:** your-email@example.com
- **Password:** Choose a password
- Click "Create Account"

#### Step 5.3: Explore Chatwoot

You should now see the Chatwoot dashboard:

- **Left sidebar:** Conversations, Contacts, Reports, Settings
- **Main panel:** Conversation list (empty if no seed data)
- **Top right:** Your profile menu

**Test basic functionality:**

1. Click "Settings" (gear icon, bottom left)
2. Click "Inboxes" → "Add Inbox"
3. Try creating a test inbox (Website, WhatsApp, etc.)

**If everything works, congratulations!** Your development environment is ready.

---

## Verification Checklist

Run through this checklist to ensure everything is working:

### Service Health Checks

```bash
# 1. Check all containers are running
docker-compose ps
# Expected: All services show "Up (healthy)"

# 2. Check PostgreSQL
docker-compose exec postgres pg_isready -U postgres
# Expected: "postgres:5432 - accepting connections"

# 3. Check Redis
docker-compose exec redis redis-cli ping
# Expected: "PONG"

# 4. Check Rails console
docker-compose exec app rails console
# Should open a Rails console prompt
# Type: User.count
# Type: exit
```

### Application Functionality

```bash
# 5. Check database has tables
docker-compose exec app rails runner "puts ActiveRecord::Base.connection.tables.count"
# Expected: A number > 50 (Chatwoot has many tables)

# 6. Check Sidekiq is processing jobs
docker-compose exec app bundle exec rails runner "puts Sidekiq.redis(&:info)"
# Should show Redis connection info

# 7. Test HTTP endpoint
curl http://localhost:3000/api
# Expected: JSON response (even if error, confirms server responding)
```

### Browser Tests

- [ ] Open http://localhost:3000 - shows Chatwoot UI
- [ ] Can create an account or log in
- [ ] Dashboard loads without errors
- [ ] Can navigate between pages (Conversations, Contacts, Settings)
- [ ] Console has no critical errors (press F12 to open DevTools)

### Performance Checks

```bash
# Check Docker resource usage
docker stats --no-stream

# Expected ranges (development):
# - gp-bikes-postgres: 50-150 MB RAM
# - gp-bikes-redis:    10-50 MB RAM
# - gp-bikes-app:      500-1000 MB RAM
# - gp-bikes-sidekiq:  300-600 MB RAM
```

**If all checks pass, you're ready to start development!**

---

## Troubleshooting

### Common Issues

#### Issue: "Port 3000 already in use"

**Symptoms:**
```
Error: Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Solution:**
```bash
# Find what's using port 3000
lsof -i :3000  # Mac/Linux
netstat -ano | findstr :3000  # Windows

# Kill the process
kill -9 <PID>  # Replace <PID> with process ID from above

# Or, change port in docker-compose.yml:
# Change "3000:3000" to "3001:3000"
# Then access at http://localhost:3001
```

---

#### Issue: PostgreSQL won't start

**Symptoms:**
```
gp-bikes-postgres | Error: Database files are incompatible with server
```

**Solution:**
```bash
# Remove old database volume
docker-compose down -v  # WARNING: Deletes all data!
docker volume rm gp-bikes-postgres-data

# Restart
docker-compose up -d
docker-compose exec app rails db:setup
```

---

#### Issue: Out of memory

**Symptoms:**
```
Container killed by Docker (exit code 137)
```

**Solution:**

1. **Increase Docker Memory:**
   - Mac: Docker Desktop → Settings → Resources → Memory → Set to 8GB
   - Windows: Docker Desktop → Settings → Resources → Memory → Set to 8GB

2. **Reduce Sidekiq concurrency:**
   - Edit `.env.development`
   - Change: `SIDEKIQ_CONCURRENCY=10` to `SIDEKIQ_CONCURRENCY=5`
   - Restart: `docker-compose restart sidekiq`

---

#### Issue: "Bundle install" fails

**Symptoms:**
```
An error occurred while installing gem_name (x.x.x), and Bundler cannot continue.
```

**Solution:**
```bash
# Clear bundle cache and reinstall
docker-compose down
docker volume rm gp-bikes-bundle-cache
docker-compose up -d --build
```

---

#### Issue: Webpacker compilation errors

**Symptoms:**
```
Webpacker::Manifest::MissingEntryError in Pages#index
```

**Solution:**
```bash
# Recompile assets
docker-compose exec app npm install
docker-compose exec app bundle exec rails webpacker:compile

# Or force clean rebuild
docker-compose exec app rm -rf public/packs
docker-compose exec app bundle exec rails webpacker:clobber
docker-compose exec app bundle exec rails webpacker:compile
```

---

#### Issue: Database migrations fail

**Symptoms:**
```
PG::UndefinedTable: ERROR:  relation "accounts" does not exist
```

**Solution:**
```bash
# Reset database (WARNING: Deletes all data!)
docker-compose exec app rails db:drop db:create db:migrate db:seed

# Or, if you want to keep investigating:
docker-compose exec app rails db:migrate:status
# Shows which migrations have run
```

---

#### Issue: Redis connection refused

**Symptoms:**
```
Redis::CannotConnectError: Error connecting to Redis on redis:6379
```

**Solution:**
```bash
# Check Redis is running
docker-compose ps redis
# Should show "Up (healthy)"

# Restart Redis
docker-compose restart redis

# Check Redis logs
docker-compose logs redis

# Test Redis connection manually
docker-compose exec redis redis-cli ping
# Should return: PONG
```

---

#### Issue: Slow performance on Mac M1/M2

**Symptoms:**
- Docker containers using high CPU
- Application responds slowly

**Solution:**

1. **Enable Rosetta:**
   - Docker Desktop → Settings → General
   - Enable "Use Rosetta for x86/amd64 emulation on Apple Silicon"
   - Restart Docker

2. **Use ARM-compatible images:**
   - Our `docker-compose.yml` already uses multi-arch images
   - If you modified it, ensure using `*-alpine` images

3. **Increase resources:**
   - Docker Desktop → Settings → Resources
   - CPUs: 4 (or more)
   - Memory: 8GB (or more)

---

#### Issue: "Cannot find module" errors

**Symptoms:**
```
Error: Cannot find module 'package-name'
```

**Solution:**
```bash
# Rebuild node_modules
docker-compose exec app npm install

# Or force clean install
docker-compose down
docker volume rm gp-bikes-node-modules
docker-compose up -d
docker-compose exec app npm install
```

---

### Getting More Help

If your issue isn't listed:

1. **Check logs:**
   ```bash
   docker-compose logs -f
   ```

2. **Check Docker system:**
   ```bash
   docker system df  # Check disk space
   docker system info  # Check Docker configuration
   ```

3. **Restart everything:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

4. **Nuclear option (deletes everything):**
   ```bash
   docker-compose down -v  # Removes all volumes
   docker system prune -a  # Removes all images
   # Then start fresh: docker-compose up -d
   ```

5. **Ask for help:**
   - Check `docs/ROADMAP.md` for architecture details
   - Review `docs/development/FORK_STRATEGY.md`
   - Ask in team Slack/Discord

---

## Development Workflow

### Daily Development

```bash
# Start services (if not already running)
docker-compose up -d

# View logs in real-time
docker-compose logs -f app

# Rails console (for testing models, queries)
docker-compose exec app rails console

# Run migrations (after pulling new code)
docker-compose exec app rails db:migrate

# Stop services (end of day)
docker-compose down
```

### Running Tests

```bash
# Run full test suite
docker-compose exec app bundle exec rspec

# Run specific test file
docker-compose exec app bundle exec rspec spec/models/conversation_spec.rb

# Run tests matching pattern
docker-compose exec app bundle exec rspec spec/models/ --pattern "*_spec.rb"

# Run with coverage report
docker-compose exec app COVERAGE=true bundle exec rspec
```

### Code Changes & Hot Reload

**Ruby/Rails files:**
- Changes are picked up automatically (thanks to volume mount)
- No need to restart server
- Just refresh browser

**JavaScript/Vue files:**
- Webpacker watches for changes
- Auto-recompiles and reloads
- May take 5-10 seconds

**Gemfile or package.json changes:**
```bash
# If you add new gems
docker-compose exec app bundle install
docker-compose restart app

# If you add new npm packages
docker-compose exec app npm install
docker-compose restart app
```

**Database schema changes:**
```bash
# Create a migration
docker-compose exec app rails generate migration AddFieldToModel field:type

# Edit the migration in db/migrate/

# Run the migration
docker-compose exec app rails db:migrate

# Rollback if needed
docker-compose exec app rails db:rollback
```

### Debugging

**Ruby debugging with byebug:**

1. Add `byebug` to your code:
   ```ruby
   def some_method
     byebug  # Execution will stop here
     # ... rest of code
   end
   ```

2. Attach to running container:
   ```bash
   docker-compose attach app
   # Or
   docker attach gp-bikes-app
   ```

3. Debug in terminal (use standard byebug commands)

4. Detach without stopping: Press `Ctrl+P` then `Ctrl+Q`

**JavaScript debugging:**

- Use browser DevTools (F12)
- Console logs appear in browser console
- Source maps are enabled in development

### Accessing Rails Console

```bash
# Standard Rails console
docker-compose exec app rails console

# Sandbox mode (rolls back all changes on exit)
docker-compose exec app rails console --sandbox

# Example queries:
> User.count
> Account.first
> Conversation.where(status: 'open').count
> exit
```

### Accessing Database Directly

```bash
# PostgreSQL console
docker-compose exec postgres psql -U postgres -d chatwoot_dev

# Example queries:
chatwoot_dev=# \dt  -- List tables
chatwoot_dev=# \d+ users  -- Describe users table
chatwoot_dev=# SELECT COUNT(*) FROM conversations;
chatwoot_dev=# \q  -- Quit
```

### Stopping Services

```bash
# Stop services (keeps containers and data)
docker-compose stop

# Stop and remove containers (keeps data)
docker-compose down

# Stop, remove containers AND delete data (fresh start)
docker-compose down -v
```

---

## Next Steps

Now that your development environment is running, you're ready to start building!

### Week 1: Sprint 1 Foundation

1. **Read the Sprint Plan:**
   - `docs/ROADMAP.md` - Full 12-week plan
   - `docs/sprint1/` - Detailed Sprint 1 tasks

2. **Understand the Architecture:**
   - `docs/development/FORK_STRATEGY.md` - How we extend Chatwoot
   - Explore Chatwoot codebase structure

3. **Start with BaseAiWorker:**
   - See `docs/sprint1/BASE_AI_WORKER_SPEC.md`
   - This is the foundation for all AI functionality

### Useful Commands Reference

```bash
# Docker Compose
docker-compose up -d              # Start services
docker-compose down               # Stop services
docker-compose ps                 # List services
docker-compose logs -f <service>  # View logs
docker-compose restart <service>  # Restart service
docker-compose exec <service> <cmd>  # Run command in service

# Rails
rails console                     # Rails console
rails db:migrate                  # Run migrations
rails db:rollback                 # Rollback migration
rails db:reset                    # Drop, create, migrate, seed
rails routes                      # Show all routes
rails runner "code"               # Run Ruby code

# Database
rails db:create                   # Create database
rails db:drop                     # Drop database
rails db:seed                     # Load seed data
rails db:setup                    # Create + migrate + seed

# Testing
rspec                             # Run all tests
rspec spec/models/                # Run model tests
rspec spec/path/to/file_spec.rb   # Run specific file

# Assets
rails assets:precompile           # Compile assets
rails webpacker:compile           # Compile Webpacker

# Bundler
bundle install                    # Install gems
bundle update                     # Update gems
bundle exec <cmd>                 # Run with bundle context

# NPM
npm install                       # Install packages
npm run build                     # Build frontend
npm run test                      # Run frontend tests
```

### Important Files to Know

```
GP Bikes/
├── app/
│   ├── models/              # Rails models
│   ├── controllers/         # Rails controllers
│   ├── workers/             # Sidekiq background jobs
│   ├── javascript/          # Vue.js frontend
│   └── views/               # Rails views
├── config/
│   ├── routes.rb            # URL routing
│   ├── database.yml         # Database config
│   └── environments/        # Environment configs
├── db/
│   ├── migrate/             # Database migrations
│   └── seeds.rb             # Seed data
├── spec/                    # RSpec tests
├── docker-compose.yml       # Docker services
├── .env.development         # Your secrets (not in Git)
└── docs/                    # Documentation
```

### Learning Resources

- **Chatwoot Docs:** https://www.chatwoot.com/docs
- **Rails Guides:** https://guides.rubyonrails.org/
- **Vue.js Docs:** https://vuejs.org/guide/
- **Docker Docs:** https://docs.docker.com/
- **PostgreSQL Docs:** https://www.postgresql.org/docs/

---

## Support

If you get stuck:

1. Check this document's [Troubleshooting](#troubleshooting) section
2. Review Docker logs: `docker-compose logs -f`
3. Check service health: `docker-compose ps`
4. Ask your team in Slack/Discord
5. Review Chatwoot's documentation for upstream features

---

**Happy coding!**

You're now ready to build AI-powered WhatsApp automation for GP Bikes. 🏍️

---

**Document Maintenance:**
- **Created:** 2025-09-30
- **Last Updated:** 2025-09-30
- **Maintained By:** Jorge (DevOps & Infrastructure)
- **Review Schedule:** Update after each major infrastructure change
