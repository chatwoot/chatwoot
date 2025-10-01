# Infrastructure Validation Checklist

Use this checklist to verify your development environment is working correctly.

**Run through this after initial setup and after major infrastructure changes.**

---

## Prerequisites Validation

### Docker Desktop

- [ ] Docker Desktop installed and running
- [ ] Docker version 24.x or higher: `docker --version`
- [ ] Docker Compose version 2.x or higher: `docker-compose --version`
- [ ] Docker has at least 20GB disk space: `docker system df`
- [ ] Docker allocated at least 8GB RAM (Settings → Resources)

### Git & Repository

- [ ] Git installed: `git --version`
- [ ] Repository cloned: `cd "GP Bikes" && pwd`
- [ ] On correct branch: `git branch` shows `* gp-bikes-develop`
- [ ] Upstream remote configured: `git remote -v` shows `upstream`
- [ ] SSH keys configured (if using SSH): `ssh -T git@github.com`

### Environment Files

- [ ] `.env.development` exists: `ls -la .env.development`
- [ ] `.env.development` is in `.gitignore`
- [ ] Secrets generated: `grep -q "SECRET_KEY_BASE=[a-f0-9]\{64\}" .env.development`

---

## Service Startup Validation

### Start Services

```bash
# Start all services
docker-compose up -d
```

**Expected Output:**
```
[+] Running 5/5
 ✔ Network gp-bikes-network    Created
 ✔ Container gp-bikes-postgres  Started
 ✔ Container gp-bikes-redis     Started
 ✔ Container gp-bikes-app       Started
 ✔ Container gp-bikes-sidekiq   Started
```

- [ ] No errors during startup
- [ ] All 5 items show green checkmarks

### Container Status

```bash
docker-compose ps
```

**Expected Output:**
```
NAME                  STATUS
gp-bikes-app         Up X seconds (healthy)
gp-bikes-postgres    Up X seconds (healthy)
gp-bikes-redis       Up X seconds (healthy)
gp-bikes-sidekiq     Up X seconds (healthy)
```

- [ ] All containers show `Up`
- [ ] All containers show `(healthy)` (may take 30-60 seconds)
- [ ] No containers in `Restarting` state

### Service Logs (No Critical Errors)

```bash
# Check for errors in logs
docker-compose logs app | grep -i error
docker-compose logs sidekiq | grep -i error
docker-compose logs postgres | grep -i error
docker-compose logs redis | grep -i error
```

- [ ] No FATAL errors in PostgreSQL logs
- [ ] No connection errors in app logs
- [ ] Redis shows "Ready to accept connections"
- [ ] App shows "Listening on http://0.0.0.0:3000"

---

## Database Validation

### PostgreSQL Health

```bash
# Check PostgreSQL is ready
docker-compose exec postgres pg_isready -U postgres
```

**Expected Output:**
```
postgres:5432 - accepting connections
```

- [ ] Shows "accepting connections"

### Database Connection

```bash
# Test connection
docker-compose exec postgres psql -U postgres -d chatwoot_dev -c "SELECT 1 as test;"
```

**Expected Output:**
```
 test
------
    1
(1 row)
```

- [ ] Query executes successfully
- [ ] Returns `1`

### Database Tables

```bash
# Check tables exist
docker-compose exec app rails runner "puts ActiveRecord::Base.connection.tables.count"
```

**Expected Output:**
```
<number> (should be > 50)
```

- [ ] Returns a number greater than 50
- [ ] No errors about missing database

### Database Extensions

```bash
# Check extensions loaded
docker-compose exec postgres psql -U postgres -d chatwoot_dev -c "\dx"
```

**Expected Extensions:**
- [ ] `uuid-ossp` listed
- [ ] `pgcrypto` listed
- [ ] `pg_stat_statements` listed (optional but recommended)

---

## Redis Validation

### Redis Health

```bash
# Check Redis responds
docker-compose exec redis redis-cli ping
```

**Expected Output:**
```
PONG
```

- [ ] Returns "PONG"

### Redis Info

```bash
# Check Redis info
docker-compose exec redis redis-cli info server
```

**Expected Output (partial):**
```
redis_version:7.x.x
...
os:Linux ...
```

- [ ] Shows Redis version 7.x
- [ ] No connection errors

### Redis Connection from App

```bash
# Test Redis from Rails
docker-compose exec app rails runner "puts Redis.new(url: ENV['REDIS_URL']).ping"
```

**Expected Output:**
```
PONG
```

- [ ] Returns "PONG"
- [ ] No connection refused errors

---

## Rails Application Validation

### Rails Console Access

```bash
# Open Rails console
docker-compose exec app rails console
```

**In the console, run:**
```ruby
# Test basic functionality
puts Rails.env
# Expected: development

User.connection.active?
# Expected: true

exit
```

- [ ] Console opens without errors
- [ ] Shows `development` environment
- [ ] Database connection is active
- [ ] Can exit cleanly

### Database Data (if seeded)

```bash
# Check for seeded data
docker-compose exec app rails runner "puts User.count"
```

**Expected Output (if db:seed was run):**
```
1 (or more)
```

**Expected Output (if db:seed NOT run):**
```
0
```

- [ ] Command executes without error
- [ ] Returns a number (0 or more)

### Rails Routes

```bash
# Check routes loaded
docker-compose exec app rails routes | head -20
```

**Expected Output:**
```
Prefix Verb   URI Pattern              Controller#Action
...
(list of routes)
```

- [ ] Shows list of routes
- [ ] No errors about missing routes file

### Asset Compilation

```bash
# Check Webpacker can compile
docker-compose exec app bundle exec rails webpacker:info
```

**Expected Output:**
```
Webpacker: 5.x.x
...
```

- [ ] Shows Webpacker version
- [ ] No compilation errors

---

## Sidekiq Validation

### Sidekiq Process Running

```bash
# Check Sidekiq is running
docker-compose exec sidekiq ps aux | grep sidekiq
```

**Expected Output:**
```
... bundle exec sidekiq ...
```

- [ ] Shows sidekiq process running
- [ ] Not in crashed state

### Sidekiq Queues

```bash
# Check Sidekiq queues exist
docker-compose exec app rails runner "puts Sidekiq::Queue.all.map(&:name)"
```

**Expected Output:**
```
default
mailers
...
(list of queue names)
```

- [ ] Shows list of queues
- [ ] No Redis connection errors

### Sidekiq Stats

```bash
# Check Sidekiq stats
docker-compose exec app rails runner "puts Sidekiq.redis { |r| r.info }.to_yaml"
```

**Expected Output:**
```
redis_version: 7.x.x
...
```

- [ ] Shows Redis info through Sidekiq
- [ ] No connection errors

---

## Web Application Validation

### HTTP Endpoint Response

```bash
# Test API endpoint
curl -I http://localhost:3000/api
```

**Expected Output:**
```
HTTP/1.1 404 Not Found (or other response)
...
```

- [ ] Returns HTTP response (any status code is fine)
- [ ] Not "Connection refused"

### UI Accessibility

**In your browser:**

1. Open: http://localhost:3000

**Expected:**
- [ ] Page loads (may take 10-30 seconds first time)
- [ ] No "This site can't be reached" error
- [ ] Shows Chatwoot UI (login page or dashboard)
- [ ] No critical JavaScript errors in console (F12 → Console)

### Login/Signup Flow

**If database was seeded:**

1. Navigate to http://localhost:3000
2. Log in with:
   - Email: `admin@example.com`
   - Password: `password123`

- [ ] Login form appears
- [ ] Can submit credentials
- [ ] Redirects to dashboard after login

**If database NOT seeded:**

1. Navigate to http://localhost:3000
2. Fill out signup form

- [ ] Signup form appears
- [ ] Can submit form
- [ ] Account created successfully

### Dashboard Navigation

**After logging in:**

- [ ] Dashboard loads
- [ ] Left sidebar visible (Conversations, Contacts, etc.)
- [ ] Can click between sections
- [ ] No errors in browser console

---

## Performance Validation

### Resource Usage

```bash
# Check container resource usage
docker stats --no-stream
```

**Expected Ranges (Development):**

```
CONTAINER           CPU %     MEM USAGE / LIMIT     MEM %
gp-bikes-postgres   <5%       50-150MB / 8GB        <2%
gp-bikes-redis      <2%       20-50MB / 8GB         <1%
gp-bikes-app        5-20%     500-1000MB / 8GB      8-15%
gp-bikes-sidekiq    <5%       300-600MB / 8GB       5-10%
```

- [ ] Total memory usage < 2GB
- [ ] No container using > 90% CPU consistently
- [ ] No container constantly restarting

### Disk Usage

```bash
# Check Docker disk usage
docker system df
```

**Expected:**
```
TYPE            TOTAL     ACTIVE    SIZE
Images          X         X         2-5GB
Containers      4         4         100-500MB
Local Volumes   5         5         1-3GB
```

- [ ] Total usage < 10GB
- [ ] Plenty of free space remaining

### Response Time

```bash
# Test response time
time curl -s http://localhost:3000/api > /dev/null
```

**Expected Output:**
```
real    0m0.XXXs (should be < 2 seconds)
```

- [ ] Response time < 5 seconds
- [ ] Not timing out

---

## Dependency Validation

### Ruby Gems

```bash
# Check bundle status
docker-compose exec app bundle check
```

**Expected Output:**
```
The Gemfile's dependencies are satisfied
```

- [ ] All gems installed
- [ ] No missing dependencies

### NPM Packages

```bash
# Check NPM packages
docker-compose exec app npm list --depth=0
```

**Expected Output:**
```
gp-bikes-ai-assistant@ /app
├── @rails/actioncable@...
├── @rails/webpacker@...
...
```

- [ ] Shows list of packages
- [ ] No UNMET PEER DEPENDENCY errors

---

## Networking Validation

### Container Network

```bash
# Check network exists
docker network inspect gp-bikes-network
```

**Expected Output:**
```
[
    {
        "Name": "gp-bikes-network",
        "Driver": "bridge",
        ...
        "Containers": {
            ... (4 containers listed)
        }
    }
]
```

- [ ] Network exists
- [ ] Shows 4 containers connected

### Service Discovery

```bash
# Test service discovery (app can reach postgres)
docker-compose exec app ping -c 1 postgres
```

**Expected Output:**
```
PING postgres (...) 56(84) bytes of data.
64 bytes from ...
```

- [ ] Ping succeeds
- [ ] Resolves to container IP

### Port Mapping

```bash
# Check ports are mapped
docker-compose ps --format json | jq -r '.[].Ports'
```

**Expected:**
- [ ] `0.0.0.0:3000->3000/tcp` (app)
- [ ] `0.0.0.0:5432->5432/tcp` (postgres)
- [ ] `0.0.0.0:6379->6379/tcp` (redis)

---

## Volume Validation

### Named Volumes Exist

```bash
# List volumes
docker volume ls | grep gp-bikes
```

**Expected Output:**
```
gp-bikes-bundle-cache
gp-bikes-node-modules
gp-bikes-packs
gp-bikes-postgres-data
gp-bikes-redis-data
```

- [ ] All 5 volumes listed
- [ ] No errors

### Volume Data Persistence

```bash
# Create test data
docker-compose exec app rails runner "User.create!(name: 'Test', email: 'test@test.com', password: 'password123')"

# Restart container
docker-compose restart app

# Check data still exists
docker-compose exec app rails runner "puts User.find_by(email: 'test@test.com')&.name"
```

**Expected Output:**
```
Test
```

- [ ] Data persists after container restart
- [ ] Can retrieve created user

---

## Security Validation

### Secrets Not in Git

```bash
# Check .env.development is git-ignored
git check-ignore -v .env.development
```

**Expected Output:**
```
.gitignore:XX:.env.development    .env.development
```

- [ ] Shows .env.development is ignored
- [ ] Won't be committed to Git

### No Hardcoded Secrets in Code

```bash
# Search for hardcoded secrets (should find none)
grep -r "sk-proj-" app/ --include="*.rb" | grep -v "example"
```

**Expected Output:**
```
(empty - no results)
```

- [ ] No hardcoded API keys in code
- [ ] Only .env.development.example contains placeholders

---

## Troubleshooting Validation

If any check fails:

1. **Check logs:**
   ```bash
   docker-compose logs -f
   ```

2. **Restart services:**
   ```bash
   docker-compose restart
   ```

3. **Check service-specific logs:**
   ```bash
   docker-compose logs <service-name>
   ```

4. **Full restart:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **Nuclear option (deletes data):**
   ```bash
   docker-compose down -v
   docker-compose up -d
   docker-compose exec app rails db:setup
   ```

---

## Validation Report

After completing all checks, create a validation report:

```bash
# Save validation report
cat > validation-report.txt << EOF
GP Bikes Infrastructure Validation Report
Date: $(date)
Machine: $(uname -a)

Docker Version: $(docker --version)
Docker Compose Version: $(docker-compose --version)

Services Status:
$(docker-compose ps)

Resource Usage:
$(docker stats --no-stream)

Disk Usage:
$(docker system df)

All checks: [PASS/FAIL]
Notes: [Any issues or warnings]
EOF

# View report
cat validation-report.txt
```

---

## Success Criteria

**Your environment is fully validated when:**

- ✅ All containers show `healthy` status
- ✅ PostgreSQL accepts connections
- ✅ Redis responds to ping
- ✅ Rails console opens successfully
- ✅ Sidekiq processes jobs
- ✅ Web UI loads at http://localhost:3000
- ✅ Can log in and navigate dashboard
- ✅ No critical errors in logs
- ✅ Resource usage is reasonable (< 2GB RAM total)
- ✅ Data persists after container restarts

**If all checks pass, you're ready to start development! 🚀**

---

## What's Next?

After validation:

1. **Explore Chatwoot:**
   - Create test conversations
   - Try different channels (Website, API)
   - Explore settings and configurations

2. **Read Sprint 1 Plan:**
   - See `docs/ROADMAP.md`
   - Understand BaseAiWorker architecture

3. **Set up your IDE:**
   - Install Ruby and Rails extensions
   - Configure linters and formatters
   - Set up debugging

4. **Join team sync:**
   - Share validation results
   - Get assigned tasks
   - Ask questions

---

**Document Maintenance:**
- **Created:** 2025-09-30
- **Last Updated:** 2025-09-30
- **Maintained By:** Jorge (DevOps & Infrastructure)
- **Review:** After infrastructure changes
