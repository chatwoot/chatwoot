# CommMate Development Guide

Complete guide for setting up and running CommMate locally.

## Prerequisites

| Software | Version | Installation |
|----------|---------|--------------|
| Ruby | 3.4.4 | `rbenv install 3.4.4` |
| Node.js | 23.x (24.x works) | `brew install node` |
| pnpm | Latest | `npm install -g pnpm` |
| PostgreSQL | 16 | Running in Podman: `commmate-postgres` |
| Redis | Latest | Port 6379 |

## Quick Start

```bash
# 1. Install dependencies
bundle install && pnpm install

# 2. Setup database
bin/rails db:create db:migrate

# 3. Apply CommMate branding
./custom/script/apply_commmate_branding.sh

# 4. Create admin user
bin/rails runner "
account = Account.create!(name: 'CommMate')
user = User.create!(
  email: 'admin@commmate.com',
  password: 'Password@123',
  password_confirmation: 'Password@123',
  name: 'Admin',
  confirmed_at: Time.current
)
AccountUser.create!(account: account, user: user, role: :administrator)
"

# 5. Start servers
bin/rails s -p 3000 &
bin/vite dev &
bundle exec sidekiq -C config/sidekiq.yml &

# 6. Access
open http://localhost:3000
```

**Login:** admin@commmate.com / Password@123

## Running Servers

### Method 1: Individual Processes (Recommended)

```bash
# Terminal 1 - Rails
cd /path/to/chatwoot
eval "$(rbenv init -)"
bin/rails s -p 3000

# Terminal 2 - Vite
export PATH="$HOME/.npm-global/bin:$PATH"
bin/vite dev

# Terminal 3 - Sidekiq
bundle exec sidekiq -C config/sidekiq.yml
```

### Method 2: Overmind (if installed)

```bash
brew install tmux overmind
overmind start -f Procfile.dev
```

### Verify Running

```bash
lsof -iTCP -sTCP:LISTEN -P -n | grep -E "(3000|3036)"
ps aux | grep -E "(rails|vite|sidekiq)" | grep -v grep
```

## Database Operations

### Fresh Start

```bash
# Stop servers first
pkill -f "rails s" && pkill -f "vite" && pkill -f sidekiq

# Terminate DB connections
podman exec commmate-postgres psql -U postgres -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'chatwoot_commmate';"

# Reset database
bin/rails db:drop db:create db:migrate

# Reapply branding
./custom/script/apply_commmate_branding.sh
```

### Install pgvector (Required for AI features)

```bash
podman exec -u root commmate-postgres sh -c \
  "apt-get update && apt-get install -y postgresql-16-pgvector"
```

### Fix Common Migration Issue

If migration `20231211010807_add_cached_labels_list.rb` fails, comment out:

```ruby
# ActsAsTaggableOn::Taggable::Cache.included(Conversation)
```

## Switching Branches

```bash
# Stop all services
pkill -f "rails s" && pkill -f "vite" && pkill -f sidekiq

# Switch branch
git checkout branch-name

# Update dependencies
bundle install && pnpm install

# Run migrations
bin/rails db:migrate

# Reapply branding
./custom/script/apply_commmate_branding.sh

# Restart servers
```

## Common Issues

### pnpm not found

```bash
npm install -g pnpm
export PATH="$HOME/.npm-global/bin:$PATH"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
```

### Port already in use

```bash
lsof -ti:3000 | xargs kill -9  # Kill Rails
lsof -ti:3036 | xargs kill -9  # Kill Vite
```

### Enterprise Edition Error

Fixed in `config/initializers/01_inject_enterprise_edition_module.rb`:

```ruby
def const_get_maybe_false(mod, name)
  return nil unless mod.is_a?(Module)
  mod.const_defined?(name, false) ? mod.const_get(name, false) : nil
end
```

## Development Commands

```bash
# Console
bin/rails console

# Tests
pnpm test               # JavaScript
bundle exec rspec       # Ruby

# Linting
pnpm eslint:fix
bundle exec rubocop -a

# Database
bin/rails db:reset
bin/rails db:version
bin/rails dbconsole
```

## Project Structure

```
chatwoot/
├── custom/               # CommMate customizations
│   ├── assets/          # Logos, favicons
│   ├── config/          # Branding config
│   ├── docs/            # This documentation
│   ├── locales/         # Translations
│   ├── script/          # Automation scripts
│   └── styles/          # Custom CSS
├── app/
│   ├── javascript/      # Vue.js frontend
│   ├── models/          # Rails models
│   └── controllers/     # API controllers
├── config/
└── db/
```

## Environment

**Database:** `chatwoot_commmate` (PostgreSQL in Podman)  
**Services:** Rails (3000), Vite (3036), Sidekiq, Redis (6379)

## Next Steps

- **Branding:** See `REBRANDING.md`
- **Upgrades:** See `UPGRADE.md`

