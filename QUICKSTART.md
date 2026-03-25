# Quick Start - Chatwoot-FazerAI Development

**Time to productive: ~10 minutes** (after prerequisites installed)

## 🚀 Quickest Path (One Command)

```bash
./setup-dev.sh && pnpm dev
```

That's it! The app will be at http://localhost:3000

---

## 📋 Prerequisites (Install Once)

**Need these first:**

- Ruby 3.4.4 (`rvm install 3.4.4`)
- Node.js 24.13.0 (`nvm install 24.13.0`)
- PostgreSQL 16 (running on localhost)
- Redis (running on localhost)

**Verify:**

```bash
ruby -v && node -v && psql --version && redis-cli ping
```

---

## 🎯 Common Commands

```bash
# One-time setup
make setup-local

# Start development (any terminal)
make dev              # pnpm dev
make run              # with Overmind

# Database
make db_create
make db_migrate
make db_seed          # load test data

# Testing
make test             # all tests
make test-ruby        # RSpec only
make test-js          # Jest only

# Code quality
make lint             # auto-fix everything
make lint-ruby        # RuboCop
make lint-js          # ESLint

# Rails console
make console

# Kill stuck processes
make force_run
```

---

## 🌐 What's Running

After `pnpm dev`:

| Service     | URL                   | Purpose                  |
| ----------- | --------------------- | ------------------------ |
| **App**     | http://localhost:3000 | Main UI                  |
| **Vite**    | http://localhost:3036 | Dev assets (auto-reload) |
| **MailHog** | http://localhost:1025 | Email testing            |

---

## ⚙️ Configuration

Edit `.env` for:

- `FRONTEND_URL` - Application URL
- `POSTGRES_*` - Database connection
- `REDIS_URL` - Redis connection
- `DEFAULT_LOCALE` - Default language (pt_BR for Portuguese)

---

## 🔥 If Something Breaks

```bash
# Database issues
make db_reset
make db_migrate

# Port conflicts
make force_run

# Dependency issues
bundle install
pnpm install

# Build issues
make burn  # Clean everything and reinstall
```

---

## 📚 Full Docs

- **Complete setup**: [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md)
- **Manifesto**: [CLAUDE.md](CLAUDE.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 💬 Need Help?

1. Check [CLAUDE.md](CLAUDE.md) for our engineering principles
2. Check [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md) Troubleshooting section
3. Run `make help` for all available commands

**Happy coding!** 🎉
