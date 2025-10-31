# Chatwoot Development Environment

Quick start scripts for setting up and running Chatwoot in Docker containers.

## 🚀 First Time Setup

Run this once to set up everything:

```bash
./.devcontainer/setup-dev.sh
```

This will:
- Build Docker images
- Start PostgreSQL, Redis, and Mailhog
- Run database migrations
- Seed demo data (creates test account and user)

## 📋 Daily Usage

### Start the Development Server

```bash
./.devcontainer/start-dev.sh
```

This starts all services (Rails, Vite, Sidekiq). Press `Ctrl+C` to stop.

### Stop All Services

```bash
./.devcontainer/stop-dev.sh
```

### Reset Everything (Clean Slate)

⚠️ **Warning:** This deletes all data!

```bash
./.devcontainer/reset-dev.sh
```

## 🌐 Access Points

Once running:

- **App**: http://localhost:3000/app
- **Mailhog** (email testing): http://localhost:8025

## 🔑 Default Login

- **Email**: `john@acme.inc`
- **Password**: `Password1!`

## 🛠️ Manual Commands

If you need to run commands manually:

```bash
# Get a shell inside the container
docker compose -f .devcontainer/docker-compose.yml exec app bash

# Run Rails console
docker compose -f .devcontainer/docker-compose.yml exec app bash -lc "bin/rails console"

# Run a Rails command
docker compose -f .devcontainer/docker-compose.yml exec app bash -lc "bin/rails db:migrate"

# View logs
docker compose -f .devcontainer/docker-compose.yml logs -f

# Restart specific service
docker compose -f .devcontainer/docker-compose.yml restart app
```

## 📦 What's Included

- **PostgreSQL 16** with pgvector extension
- **Redis** for caching and background jobs
- **Mailhog** for email testing
- **Ruby 3.4.4**
- **Node.js 23.7.0**
- All Chatwoot dependencies pre-installed

## 🐛 Troubleshooting

### Port already in use
```bash
# Check what's using port 3000
lsof -ti:3000 | xargs kill -9

# Or use different ports in docker-compose.yml
```

### Services won't start
```bash
# Reset everything
./.devcontainer/reset-dev.sh
./.devcontainer/setup-dev.sh
```

### Can't connect to database
```bash
# Restart database
docker compose -f .devcontainer/docker-compose.yml restart db

# Wait a few seconds then restart app
docker compose -f .devcontainer/docker-compose.yml restart app
```

## 📝 Notes

- First load may take 10-20 seconds as Vite compiles JavaScript
- Worker errors about "Channel email domain" are normal in development
- Deprecation warnings from Sass/Vue are safe to ignore

