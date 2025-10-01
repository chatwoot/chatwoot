# Quick Reference - GP Bikes Development

One-page cheat sheet for common development tasks.

**Print this out or keep it open in a browser tab!**

---

## Daily Commands

```bash
# Start development environment
docker-compose up -d

# View all logs
docker-compose logs -f

# Stop everything
docker-compose down

# Stop and delete all data (fresh start)
docker-compose down -v
```

---

## Service Status

```bash
# Check all services
docker-compose ps

# Check specific service
docker-compose ps app

# Restart service
docker-compose restart app

# View logs
docker-compose logs -f app
docker-compose logs -f sidekiq
```

---

## Database

```bash
# Rails console
docker-compose exec app rails console

# Database console (psql)
docker-compose exec postgres psql -U postgres -d chatwoot_dev

# Create database
docker-compose exec app rails db:create

# Run migrations
docker-compose exec app rails db:migrate

# Rollback migration
docker-compose exec app rails db:rollback

# Reset database (WARNING: Deletes data!)
docker-compose exec app rails db:reset

# Seed data
docker-compose exec app rails db:seed

# Full setup (create + migrate + seed)
docker-compose exec app rails db:setup
```

---

## Testing

```bash
# Run all tests
docker-compose exec app bundle exec rspec

# Run specific test file
docker-compose exec app bundle exec rspec spec/models/user_spec.rb

# Run specific test line
docker-compose exec app bundle exec rspec spec/models/user_spec.rb:42

# Run tests matching pattern
docker-compose exec app bundle exec rspec --pattern "spec/**/*_spec.rb"

# Run with coverage
docker-compose exec app COVERAGE=true bundle exec rspec
```

---

## Dependencies

```bash
# Install Ruby gems
docker-compose exec app bundle install

# Install NPM packages
docker-compose exec app npm install

# Update gems
docker-compose exec app bundle update

# Check for security vulnerabilities
docker-compose exec app bundle audit
```

---

## Assets & Webpacker

```bash
# Compile assets
docker-compose exec app rails assets:precompile

# Compile Webpacker
docker-compose exec app bundle exec rails webpacker:compile

# Clean compiled assets
docker-compose exec app rails webpacker:clobber

# Check Webpacker config
docker-compose exec app bundle exec rails webpacker:info
```

---

## Rails Generators

```bash
# Generate model
docker-compose exec app rails generate model Product name:string price:decimal

# Generate migration
docker-compose exec app rails generate migration AddFieldToTable field:type

# Generate controller
docker-compose exec app rails generate controller Products index show

# Generate worker
docker-compose exec app rails generate sidekiq:worker ProcessOrder

# Show all routes
docker-compose exec app rails routes

# Show routes matching pattern
docker-compose exec app rails routes | grep conversation
```

---

## Debugging

```bash
# Attach to running app (for byebug)
docker attach gp-bikes-app
# Detach without stopping: Ctrl+P, then Ctrl+Q

# Shell into container
docker-compose exec app bash
docker-compose exec app sh  # if bash not available

# Check Rails environment
docker-compose exec app rails runner "puts Rails.env"

# Run Ruby code
docker-compose exec app rails runner "puts User.count"

# Check environment variables
docker-compose exec app env | grep RAILS
```

---

## Background Jobs (Sidekiq)

```bash
# Check Sidekiq status
docker-compose exec app bundle exec sidekiqmon

# View Sidekiq queues
docker-compose exec app rails runner "puts Sidekiq::Queue.all.map(&:name)"

# Clear Sidekiq queue
docker-compose exec app rails runner "Sidekiq::Queue.new('default').clear"

# View failed jobs
docker-compose exec app rails runner "puts Sidekiq::RetrySet.new.size"

# Restart Sidekiq
docker-compose restart sidekiq
```

---

## Redis

```bash
# Redis CLI
docker-compose exec redis redis-cli

# Check Redis info
docker-compose exec redis redis-cli info

# Monitor Redis commands
docker-compose exec redis redis-cli monitor

# Check memory usage
docker-compose exec redis redis-cli info memory

# Flush all Redis data (WARNING: Deletes cache!)
docker-compose exec redis redis-cli FLUSHALL
```

---

## PostgreSQL

```bash
# PostgreSQL console
docker-compose exec postgres psql -U postgres -d chatwoot_dev

# List databases
docker-compose exec postgres psql -U postgres -c "\l"

# List tables
docker-compose exec postgres psql -U postgres -d chatwoot_dev -c "\dt"

# Describe table
docker-compose exec postgres psql -U postgres -d chatwoot_dev -c "\d+ users"

# Run SQL query
docker-compose exec postgres psql -U postgres -d chatwoot_dev -c "SELECT COUNT(*) FROM users;"

# Backup database
docker-compose exec postgres pg_dump -U postgres chatwoot_dev > backup.sql

# Restore database
docker-compose exec -T postgres psql -U postgres chatwoot_dev < backup.sql
```

---

## Docker Cleanup

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused (CAREFUL!)
docker system prune -a --volumes

# Check disk usage
docker system df
```

---

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/sprint1-ai-worker

# Stage changes
git add .

# Commit
git commit -m "Add BaseAiWorker implementation"

# Push to remote
git push -u origin feature/sprint1-ai-worker

# Pull from upstream Chatwoot
git fetch upstream
git merge upstream/main

# Create pull request
gh pr create --title "Add AI Worker" --body "Description here"
```

---

## Environment Variables

```bash
# View current environment
docker-compose exec app env | grep RAILS

# Generate new secrets
./bin/generate-secrets

# Edit environment
nano .env.development

# Reload environment (restart services)
docker-compose restart app sidekiq
```

---

## Health Checks

```bash
# Check app health
curl http://localhost:3000/api

# Check PostgreSQL
docker-compose exec postgres pg_isready -U postgres

# Check Redis
docker-compose exec redis redis-cli ping

# Check all services
docker-compose ps
```

---

## Performance

```bash
# Check container resource usage
docker stats

# Check container memory
docker stats --no-stream gp-bikes-app

# Check Rails memory usage
docker-compose exec app rails runner "puts \`ps aux | grep ruby\`"

# Profile specific endpoint
docker-compose exec app rails runner "Rack::MiniProfiler.profile_request('/api/v1/conversations')"
```

---

## Logs

```bash
# Follow all logs
docker-compose logs -f

# Follow specific service
docker-compose logs -f app

# Last 100 lines
docker-compose logs --tail=100 app

# Show timestamps
docker-compose logs -f -t app

# Save logs to file
docker-compose logs app > app.log

# Search logs
docker-compose logs app | grep ERROR
docker-compose logs app | grep -i "conversation"
```

---

## Troubleshooting

### App won't start

```bash
# Check logs
docker-compose logs app

# Check dependencies
docker-compose exec app bundle check
docker-compose exec app npm list

# Rebuild
docker-compose down
docker-compose up -d --build
```

### Port already in use

```bash
# Mac/Linux: Find process
lsof -i :3000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Database connection refused

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres
```

### Redis connection refused

```bash
# Check Redis is running
docker-compose ps redis

# Restart Redis
docker-compose restart redis
```

### Out of memory

```bash
# Increase Docker memory
# Docker Desktop → Settings → Resources → Memory → 8GB

# Or reduce Sidekiq concurrency
# Edit .env.development: SIDEKIQ_CONCURRENCY=5
docker-compose restart sidekiq
```

### Webpacker errors

```bash
# Recompile
docker-compose exec app bundle exec rails webpacker:compile

# Clean and recompile
docker-compose exec app rm -rf public/packs
docker-compose exec app bundle exec rails webpacker:clobber
docker-compose exec app bundle exec rails webpacker:compile
```

---

## URLs

- **Application:** http://localhost:3000
- **Webpacker Dev Server:** http://localhost:3035
- **Sidekiq Web UI:** http://localhost:3000/sidekiq (if configured)

---

## File Locations

```
app/models/              # Rails models
app/controllers/         # Rails controllers
app/workers/             # Sidekiq workers
app/javascript/          # Vue.js frontend
config/routes.rb         # URL routes
db/migrate/              # Database migrations
spec/                    # RSpec tests
.env.development         # Environment variables (git-ignored)
docker-compose.yml       # Docker services
```

---

## Keyboard Shortcuts (VS Code)

- `Cmd+P` (Mac) / `Ctrl+P` (Win): Quick file open
- `Cmd+Shift+F`: Search in files
- `Cmd+T`: Go to symbol
- `F5`: Start debugging
- `Cmd+J`: Toggle terminal

---

## Getting Help

1. Check `docs/development/SETUP.md`
2. Check `docs/development/TROUBLESHOOTING.md`
3. View service logs: `docker-compose logs -f`
4. Ask in team chat

---

## Common Patterns

### Run Rails migration

```bash
# Generate
docker-compose exec app rails g migration AddAiEnabledToConversation ai_enabled:boolean

# Edit in editor
nano db/migrate/20XX_add_ai_enabled_to_conversation.rb

# Run
docker-compose exec app rails db:migrate

# Rollback if wrong
docker-compose exec app rails db:rollback
```

### Create new model

```bash
# Generate
docker-compose exec app rails g model AiWorkerLog conversation:references content:text

# Run migration
docker-compose exec app rails db:migrate

# Create test
# Edit spec/models/ai_worker_log_spec.rb

# Run test
docker-compose exec app bundle exec rspec spec/models/ai_worker_log_spec.rb
```

### Add new gem

```bash
# Edit Gemfile
echo "gem 'gem_name'" >> Gemfile

# Install
docker-compose exec app bundle install

# Restart
docker-compose restart app
```

---

**Keep this handy!**

Save as bookmark: `file:///path/to/GP%20Bikes/docs/development/QUICK_REFERENCE.md`
