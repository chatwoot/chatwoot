# Local Development Setup Plan

## Current State

Running Rails and Vite manually in separate terminals, missing Sidekiq. Overmind was failing with exit code 1 because tmux wasn't installed (now fixed: `brew install tmux`).

## Correct Way to Run Locally

Per [AGENTS.md](AGENTS.md) and [Procfile.dev](Procfile.dev), a single command starts all 3 processes:

```bash
cd ~/AirysChat
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
eval "$(rbenv init -)"
rm -f .overmind.sock tmp/pids/*.pid
overmind start -f Procfile.dev
```

Or equivalently: `pnpm dev`

### Processes Started by Procfile.dev

| Process | Command | Purpose |
|---------|---------|---------|
| `backend` | `bin/rails s -p 3000` | Rails API + pages |
| `worker` | `dotenv bundle exec sidekiq -C config/sidekiq.yml` | Background jobs (emails, webhooks, notifications) |
| `vite` | `bin/vite dev` | Frontend asset serving + HMR |

### Prerequisites

- **tmux**: `brew install tmux` (overmind hard dependency) ✅ installed
- **Redis**: `brew services start redis` (required by Sidekiq + ActionCable)
- **PostgreSQL 17**: `brew services start postgresql@17`
- **rbenv**: Ruby 3.4.4 via `eval "$(rbenv init -)"`
- **PATH**: `/opt/homebrew/opt/postgresql@17/bin` must be in PATH

### Before Starting (cleanup)

```bash
rm -f .overmind.sock tmp/pids/*.pid
kill -9 $(lsof -ti:3000) 2>/dev/null
kill -9 $(lsof -ti:3036) 2>/dev/null
```

### Known Issues

1. **Stale `.overmind.sock`** — always remove before starting
2. **Stale `tmp/pids/server.pid`** — always remove before starting
3. **EDB PostgreSQL 18** may restart on reboot and block port 5432 — stop it with:
   ```bash
   sudo -u postgres /Library/PostgreSQL/18/bin/pg_ctl stop -D /Library/PostgreSQL/18/data -m fast
   ```
4. **Port conflicts** — kill anything on ports 3000/3036 first

### What's Missing Without Sidekiq

- Incoming message processing
- Email/notification delivery
- Webhook dispatches
- Campaign execution
- Scheduled jobs (CSAT surveys, auto-resolve, etc.)

### Performance Optimizations Applied

1. **Dev caching enabled** — `rails dev:cache` (created `tmp/caching-dev.txt`)
2. **YJIT enabled** — `RUBY_YJIT_ENABLE=1` in `.env`
3. **rack-mini-profiler disabled** — `DISABLE_MINI_PROFILER=true` in `.env`
4. **ActiveRecordQueryTrace disabled** — `config/initializers/active_record_query_trace.rb`
5. **Verbose query logs disabled** — `config/environments/development.rb`

### Fallback (if overmind still fails)

```bash
pnpm start:dev    # uses foreman instead of overmind
```

### Login Credentials

- **Super Admin**: http://localhost:3000/super_admin/sign_in
- **App**: http://localhost:3000/app/login
- Email: `john@acme.inc` / Password: `Password1!`

## Next Step

Run `overmind start -f Procfile.dev` now that tmux is installed and verify all 3 processes start cleanly.
