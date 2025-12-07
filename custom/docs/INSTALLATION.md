# CommMate Installation and Configuration Guide

**Purpose**: Complete guide for installing and configuring CommMate Chatwoot  
**Last Updated**: December 2025  
**Version**: v4.8.0+

---

## Table of Contents

1. [Installation Methods](#installation-methods)
2. [Installation Configuration System](#installation-configuration-system)
3. [Environment Variables](#environment-variables)
4. [Database Configuration](#database-configuration)
5. [Production Deployment](#production-deployment)
6. [Configuration Management](#configuration-management)
7. [Troubleshooting](#troubleshooting)

---

## Installation Methods

### Method 1: Docker (Recommended for Production)

```bash
# Pull latest CommMate image
docker pull commmate/commmate:latest

# Run with docker-compose
version: '3'
services:
  chatwoot:
    image: commmate/commmate:latest
    env_file: chatwoot.env
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
```

See `DOCKER-SETUP.md` for complete docker-compose configuration.

### Method 2: Local Development

```bash
# Clone repository
git clone https://github.com/commmate/chatwoot.git
cd chatwoot

# Install dependencies
bundle install
pnpm install

# Setup environment
cp .env.example .env.local
# Edit .env.local with your configuration

# Setup database
bundle exec rails db:migrate

# Run development server
overmind start -f ./Procfile.dev
```

See `DEVELOPMENT.md` for detailed local development setup.

---

## Installation Configuration System

CommMate uses a powerful configuration system via the `installation_configs` database table that allows runtime configuration without code changes.

### Understanding Installation Configs

**Database Table**: `installation_configs`

| Column | Type | Description |
|--------|------|-------------|
| `name` | string | Configuration key (unique) |
| `serialized_value` | jsonb | JSONB hash containing `{value: <actual_value>}` |
| `locked` | boolean | If true, cannot be changed via UI |
| `created_at` | timestamp | Creation time |
| `updated_at` | timestamp | Last update time |

**Important**: The `serialized_value` column uses YAML serialization and expects a hash with a `value` key.

### How to Set Installation Configs

#### Method 1: Via Rails Console (Development)

```bash
# Access Rails console
bundle exec rails console

# Create or update configuration
config = InstallationConfig.find_or_initialize_by(name: 'CONFIG_NAME')
config.value = 'your_value'  # Use value= method for proper serialization
config.locked = false  # Set to true to prevent UI changes
config.save!

# Verify
puts GlobalConfig.get_value('CONFIG_NAME')
# => "your_value"
```

#### Method 2: Via Rails Runner (Production)

```bash
# From host machine
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_or_initialize_by(name: 'CONFIG_NAME')
config.value = 'your_value'
config.locked = false
config.save!
puts 'Config set: ' + config.value.to_s
"
```

#### Method 3: Via Direct SQL (Advanced)

**⚠️ Not Recommended** - Use Rails methods when possible.

```sql
-- Format: serialized_value must be YAML serialized hash
INSERT INTO installation_configs (name, serialized_value, locked, created_at, updated_at)
VALUES (
  'CONFIG_NAME',
  '---\n:value: your_value\n',  -- YAML format
  false,
  NOW(),
  NOW()
)
ON CONFLICT (name) 
DO UPDATE SET serialized_value = '---\n:value: your_value\n', updated_at = NOW();
```

### Common Installation Configs

| Config Name | Type | Default | Description |
|-------------|------|---------|-------------|
| `INSTALLATION_NAME` | string | "CommMate" | Application name displayed in UI |
| `BRAND_NAME` | string | "CommMate" | Brand name for emails and branding |
| `BRAND_URL` | string | "https://commmate.com" | Brand website URL |
| `LOGO` | string | "/brand-assets/logo.png" | Main logo path |
| `LOGO_DARK` | string | "/brand-assets/logo_dark.png" | Dark theme logo path |
| `LOGO_THUMBNAIL` | string | "/brand-assets/logo_thumbnail.png" | Thumbnail logo path |
| `DEFAULT_LOCALE` | string | "pt_BR" | Default language |
| `WEBHOOK_TIMEOUT` | integer | 5 | Webhook HTTP timeout (seconds) |
| `ENABLE_ACCOUNT_SIGNUP` | boolean | false | Allow public signups |
| `DISABLE_CHATWOOT_CONNECTIONS` | boolean | true | Disable Chatwoot Hub connections |

### Configuration Precedence

CommMate uses a **4-layer configuration system**:

1. **Layer 1**: Database `installation_configs` (highest priority)
2. **Layer 2**: ENV variables from `chatwoot.env` or `.env.local`
3. **Layer 3**: CommMate initializers (`custom/config/initializers/`)
4. **Layer 4**: Default values in code

**Resolution Order**:
```ruby
# In lib/global_config.rb
def get_value(name)
  # 1. Try database first
  db_value = InstallationConfig.where(name: name).first&.value
  return db_value if db_value.present?
  
  # 2. Fallback to ENV var
  ENV[name]
end
```

---

## Environment Variables

### Required Variables

```bash
# Database
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=your_secure_password
DATABASE_URL=postgresql://postgres:password@127.0.0.1:5432/chatwoot

# Redis
REDIS_URL=redis://localhost:6379

# Application
SECRET_KEY_BASE=$(openssl rand -hex 64)
FRONTEND_URL=http://localhost:3000
RAILS_ENV=production
```

### CommMate-Specific Variables

```bash
# Branding (optional - defaults in installation_configs)
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_NAME=CommMate
BRAND_URL=https://commmate.com

# Privacy
DISABLE_CHATWOOT_CONNECTIONS=true
DISABLE_TELEMETRY=true

# Features
ENABLE_ACCOUNT_SIGNUP=false
DEFAULT_LOCALE=pt_BR

# Performance
WEBHOOK_TIMEOUT=10  # Seconds (can also be set in installation_configs)
DISABLE_MINI_PROFILER=true
```

### Optional Variables

```bash
# Email
MAILER_SENDER_EMAIL=CommMate <support@commmate.com>
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email
SMTP_PASSWORD=your_password

# Storage
ACTIVE_STORAGE_SERVICE=local  # or 's3'
S3_BUCKET_NAME=commmate-uploads
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=sa-east-1

# Monitoring
SENTRY_DSN=your_sentry_dsn
```

---

## Database Configuration

### PostgreSQL Setup

```bash
# Create database
createdb chatwoot

# Or via SQL
psql -U postgres
CREATE DATABASE chatwoot;
\q

# Run migrations
bundle exec rails db:migrate

# Seed initial data (if needed)
bundle exec rails db:seed
```

### CommMate-Specific Migrations

CommMate includes custom migrations for branding:

```bash
# Check migration status
bundle exec rails db:migrate:status

# Key CommMate migrations:
# - 20251102174650_apply_commmate_branding.rb
# - 20251022162159_add_assignee_agent_bot_id_to_conversations.rb
```

### Database Backup

```bash
# Backup PostgreSQL database
pg_dump -h localhost -U postgres chatwoot > chatwoot_backup_$(date +%Y%m%d).sql

# Restore
psql -h localhost -U postgres chatwoot < chatwoot_backup_20251207.sql
```

---

## Production Deployment

### Docker Production Stack

**File**: `/opt/evolution-chatwoot/docker-compose.yaml`

```yaml
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: chatwoot
      POSTGRES_USER: chatwoot_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U chatwoot_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:8-alpine
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  chatwoot:
    image: commmate/commmate:v4.8.0.2
    env_file: chatwoot.env
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:3000/api || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  sidekiq:
    image: commmate/commmate:v4.8.0.2
    env_file: chatwoot.env
    command: bundle exec sidekiq -C config/sidekiq.yml
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "ps aux | grep sidekiq | grep -v grep || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

### Update Production

```bash
# 1. Pull new image
docker pull commmate/commmate:v4.8.0.2

# 2. Stop services
docker compose stop chatwoot sidekiq

# 3. Backup database (optional but recommended)
docker exec postgres pg_dump -U chatwoot_user chatwoot > backup_$(date +%Y%m%d).sql

# 4. Start with new version
docker compose up -d chatwoot sidekiq

# 5. Verify
docker ps
docker logs chatwoot --tail 50 | grep "CommMate config"
# Expected: "✅ CommMate config overrides applied"
```

---

## Configuration Management

### Critical Configurations for CommMate

#### 1. Webhook Timeout (Performance)

**Problem**: Evolution API integration timing out on message send  
**Symptom**: Messages sent successfully but marked as "failed" in Chatwoot  
**Solution**: Increase webhook timeout

```bash
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_or_initialize_by(name: 'WEBHOOK_TIMEOUT')
config.value = 10  # 10 seconds
config.locked = false
config.save!
puts 'WEBHOOK_TIMEOUT: ' + GlobalConfig.get_value('WEBHOOK_TIMEOUT').to_s
"

# Restart to apply
docker compose restart chatwoot sidekiq
```

**Recommended Values**:
- **Default**: 5 seconds (too short for Evolution API)
- **Evolution API**: 10 seconds (recommended)
- **Slow networks**: 15-30 seconds
- **Maximum**: 60 seconds

#### 2. Branding Configuration

Set CommMate branding in database:

```bash
docker exec chatwoot bundle exec rails runner "
configs = {
  'INSTALLATION_NAME' => 'CommMate',
  'BRAND_NAME' => 'CommMate',
  'BRAND_URL' => 'https://commmate.com',
  'LOGO' => '/brand-assets/logo.png',
  'LOGO_DARK' => '/brand-assets/logo_dark.png',
  'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.png'
}

configs.each do |name, value|
  config = InstallationConfig.find_or_initialize_by(name: name)
  config.value = value
  config.locked = true  # Lock to prevent UI changes
  config.save!
  puts \"✓ #{name}: #{value}\"
end

puts '✅ CommMate branding configured'
"
```

#### 3. Feature Flags

Enable/disable features:

```bash
docker exec chatwoot bundle exec rails runner "
# Disable public signups
config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
config.value = false
config.save!

# Disable Chatwoot Hub connections (privacy)
config = InstallationConfig.find_or_initialize_by(name: 'DISABLE_CHATWOOT_CONNECTIONS')
config.value = true
config.save!

# Set default locale
config = InstallationConfig.find_or_initialize_by(name: 'DEFAULT_LOCALE')
config.value = 'pt_BR'
config.save!

puts '✅ Feature flags configured'
"
```

### Viewing Current Configurations

```bash
# List all installation configs
docker exec chatwoot bundle exec rails runner "
InstallationConfig.order(:name).each do |config|
  puts \"#{config.name}: #{config.value}\"
end
"

# Check specific config
docker exec chatwoot bundle exec rails runner "
puts GlobalConfig.get_value('WEBHOOK_TIMEOUT')
"

# Export all configs to JSON
docker exec chatwoot bundle exec rails runner "
configs = {}
InstallationConfig.all.each do |config|
  configs[config.name] = config.value
end
puts JSON.pretty_generate(configs)
" > installation_configs_backup.json
```

### Locking/Unlocking Configurations

```bash
# Lock configuration (prevent UI changes)
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_by(name: 'INSTALLATION_NAME')
config.locked = true
config.save!
puts 'Configuration locked'
"

# Unlock configuration (allow UI changes)
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_by(name: 'SOME_CONFIG')
config.locked = false
config.save!
puts 'Configuration unlocked'
"
```

---

## Database Configuration

### PostgreSQL Configuration

**Production Connection String Format**:
```
postgresql://username:password@host:port/database
```

**Example**:
```bash
DATABASE_URL=postgresql://chatwoot_user:secure_password@postgres:5432/chatwoot
```

**Environment Variables** (alternative to DATABASE_URL):
```bash
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot_user
POSTGRES_PASSWORD=secure_password
```

### Redis Configuration

```bash
REDIS_URL=redis://redis:6379
# or with password
REDIS_URL=redis://:password@redis:6379
```

### Connection Pool Settings

```bash
# Rails connection pool
RAILS_MAX_THREADS=5

# Sidekiq concurrency
SIDEKIQ_CONCURRENCY=10

# Database pool size (auto-calculated but can override)
DB_POOL_REAPING_FREQUENCY=30  # seconds
```

---

## Production Deployment

### Initial Setup

```bash
# 1. Create production environment file
cat > /opt/evolution-chatwoot/chatwoot.env << 'EOF'
# Database
POSTGRES_HOST=postgres
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot_user
POSTGRES_PASSWORD=CHANGE_ME_SECURE_PASSWORD

# Redis
REDIS_URL=redis://:CHANGE_ME_REDIS_PASSWORD@redis:6379

# Application
SECRET_KEY_BASE=$(openssl rand -hex 64)
FRONTEND_URL=https://crm.commmate.com
RAILS_ENV=production

# CommMate Branding (ENV vars as defaults)
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_NAME=CommMate
BRAND_URL=https://commmate.com
DISABLE_CHATWOOT_CONNECTIONS=true
ENABLE_ACCOUNT_SIGNUP=false

# Performance
WEBHOOK_TIMEOUT=10
DISABLE_MINI_PROFILER=true

# Email
MAILER_SENDER_EMAIL=CommMate <support@commmate.com>
EOF

# 2. Generate secrets
sed -i "s/CHANGE_ME_SECURE_PASSWORD/$(openssl rand -base64 32)/g" chatwoot.env
sed -i "s/CHANGE_ME_REDIS_PASSWORD/$(openssl rand -base64 32)/g" chatwoot.env

# 3. Start services
docker compose up -d

# 4. Wait for healthy status
docker ps

# 5. Run migrations
docker exec chatwoot bundle exec rails db:migrate

# 6. Verify branding
docker logs chatwoot | grep "CommMate config"
# Expected: "✅ CommMate config overrides applied"
```

### Post-Installation Configuration

After installation, set critical installation_configs:

```bash
docker exec chatwoot bundle exec rails runner "
# Performance: Webhook timeout for Evolution API
config = InstallationConfig.find_or_initialize_by(name: 'WEBHOOK_TIMEOUT')
config.value = 10
config.locked = false
config.save!

# Privacy: Disable Chatwoot Hub
config = InstallationConfig.find_or_initialize_by(name: 'DISABLE_CHATWOOT_CONNECTIONS')
config.value = true
config.locked = true
config.save!

# Features: Disable public signups
config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
config.value = false
config.locked = true
config.save!

puts '✅ Critical configurations set'
"

# Restart to apply
docker compose restart chatwoot sidekiq
```

---

## Configuration Management

### Backup Configuration

```bash
# Backup all installation_configs
docker exec chatwoot bundle exec rails runner "
configs = {}
InstallationConfig.all.each do |config|
  configs[config.name] = {
    value: config.value,
    locked: config.locked
  }
end
File.write('/tmp/installation_configs.json', JSON.pretty_generate(configs))
" && docker cp chatwoot:/tmp/installation_configs.json ./installation_configs_backup.json

echo "✅ Configuration backed up to installation_configs_backup.json"
```

### Restore Configuration

```bash
# Restore from backup
docker cp ./installation_configs_backup.json chatwoot:/tmp/restore_configs.json

docker exec chatwoot bundle exec rails runner "
configs = JSON.parse(File.read('/tmp/restore_configs.json'))

configs.each do |name, data|
  config = InstallationConfig.find_or_initialize_by(name: name)
  config.value = data['value']
  config.locked = data['locked']
  config.save!
  puts \"✓ Restored: #{name}\"
end

puts '✅ Configuration restored'
"

# Restart to apply
docker compose restart chatwoot sidekiq
```

### Reset to Defaults

```bash
# Reset all unlocked configs to defaults
docker exec chatwoot bundle exec rails runner "
InstallationConfig.where(locked: false).destroy_all
puts '✅ Unlocked configurations reset'
"

# Or reset specific config
docker exec chatwoot bundle exec rails runner "
InstallationConfig.find_by(name: 'WEBHOOK_TIMEOUT')&.destroy
puts '✅ WEBHOOK_TIMEOUT reset to default (5s)'
"
```

---

## Troubleshooting

### Issue: Configuration Not Applied

**Problem**: Changed `installation_config` but not taking effect

**Solution**:
```bash
# 1. Verify config in database
docker exec chatwoot bundle exec rails runner "
puts GlobalConfig.get_value('YOUR_CONFIG_NAME')
"

# 2. Clear Rails cache
docker exec chatwoot bundle exec rails runner "
Rails.cache.clear
GlobalConfig.clear_cache
puts '✅ Cache cleared'
"

# 3. Restart application
docker compose restart chatwoot sidekiq
```

### Issue: Serialization Error

**Problem**: `can't load serialized_value: was supposed to be a Hash`

**Cause**: Incorrect format in database (not using YAML hash format)

**Solution**:
```bash
# Delete bad entry
docker exec chatwoot bundle exec rails runner "
ActiveRecord::Base.connection.execute(
  \\\"DELETE FROM installation_configs WHERE name = 'BAD_CONFIG'\\\"
)
"

# Recreate using ActiveRecord
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.new(name: 'CONFIG_NAME', locked: false)
config.value = 'correct_value'  # Use value= method!
config.save!
"
```

### Issue: Migrations Pending

**Problem**: `ActiveRecord::PendingMigrationError`

**Solution**:
```bash
# Check migration status
docker exec chatwoot bundle exec rails db:migrate:status

# Run pending migrations
docker exec chatwoot bundle exec rails db:migrate

# If migration fails, check logs
docker logs chatwoot --tail 100
```

### Issue: Messages Marked as Failed (Evolution API)

**Problem**: Messages sent successfully but shown as failed in Chatwoot

**Cause**: Webhook timeout too short for Evolution API processing

**Solution**:
```bash
# Set WEBHOOK_TIMEOUT to 10 seconds
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_or_initialize_by(name: 'WEBHOOK_TIMEOUT')
config.value = 10
config.save!
puts 'Timeout set to: ' + config.value.to_s + ' seconds'
"

# Restart
docker compose restart chatwoot sidekiq

# Verify
docker exec chatwoot bundle exec rails runner "
puts 'Current timeout: ' + GlobalConfig.get_value('WEBHOOK_TIMEOUT').to_s
"
```

### Issue: Wrong Branding Displayed

**Problem**: CommMate branding not appearing, shows Chatwoot branding

**Cause**: Installation configs not set or overridden by ENV vars

**Solution**:
```bash
# Check current branding
docker exec chatwoot bundle exec rails runner "
puts 'INSTALLATION_NAME: ' + GlobalConfig.get_value('INSTALLATION_NAME').to_s
puts 'BRAND_NAME: ' + GlobalConfig.get_value('BRAND_NAME').to_s
puts 'LOGO: ' + GlobalConfig.get_value('LOGO').to_s
"

# Reapply CommMate branding
docker exec chatwoot bundle exec rails db:migrate:redo VERSION=20251102174650

# Or set manually
docker exec chatwoot bundle exec rails runner "
['INSTALLATION_NAME', 'BRAND_NAME'].each do |name|
  config = InstallationConfig.find_or_initialize_by(name: name)
  config.value = 'CommMate'
  config.locked = true
  config.save!
end
"

# Restart
docker compose restart chatwoot sidekiq
```

### Issue: Database Connection Failed

**Problem**: `ActiveRecord::DatabaseConnectionError`

**Solutions**:
```bash
# 1. Check database is running
docker ps | grep postgres

# 2. Test connection from Chatwoot container
docker exec chatwoot bundle exec rails runner "
ActiveRecord::Base.connection.execute('SELECT 1')
puts '✅ Database connected'
"

# 3. Verify environment variables
docker exec chatwoot env | grep POSTGRES

# 4. Check DATABASE_URL format
# Must be: postgresql://user:pass@host:port/database
```

---

## Health Checks

### Application Health

```bash
# Check all services
docker ps --format 'table {{.Names}}\t{{.Status}}'

# Check Chatwoot logs
docker logs chatwoot --tail 50

# Check Sidekiq is processing jobs
docker logs sidekiq --tail 50 | grep "Performed"

# Test HTTP endpoint
curl -I http://localhost:3000/api
# Expected: HTTP/1.1 200 OK
```

### Configuration Health

```bash
# Verify critical configs are set
docker exec chatwoot bundle exec rails runner "
critical = ['INSTALLATION_NAME', 'BRAND_NAME', 'WEBHOOK_TIMEOUT']
critical.each do |name|
  value = GlobalConfig.get_value(name)
  status = value.present? ? '✓' : '✗'
  puts \"#{status} #{name}: #{value}\"
end
"
```

### Database Health

```bash
# Check database size
docker exec postgres psql -U chatwoot_user -d chatwoot -c "
SELECT pg_size_pretty(pg_database_size('chatwoot'));
"

# Check table sizes
docker exec postgres psql -U chatwoot_user -d chatwoot -c "
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"

# Check connections
docker exec postgres psql -U chatwoot_user -d chatwoot -c "
SELECT count(*) as connections FROM pg_stat_activity;
"
```

---

## Maintenance Tasks

### Clear Cache

```bash
# Clear Rails cache
docker exec chatwoot bundle exec rails runner "
Rails.cache.clear
puts '✅ Rails cache cleared'
"

# Clear Redis cache (careful - affects sessions)
docker exec redis redis-cli FLUSHALL
```

### Database Maintenance

```bash
# Vacuum database (reclaim space)
docker exec postgres psql -U chatwoot_user -d chatwoot -c "VACUUM ANALYZE;"

# Reindex database
docker exec postgres psql -U chatwoot_user -d chatwoot -c "REINDEX DATABASE chatwoot;"
```

### Clean Old Data

```bash
# Clean old notifications (older than 90 days)
docker exec chatwoot bundle exec rails runner "
Notification.where('created_at < ?', 90.days.ago).delete_all
puts '✅ Old notifications cleaned'
"

# Clean old messages (if needed - be careful!)
docker exec chatwoot bundle exec rails runner "
# Only clean if you really need to free space
# Message.where('created_at < ?', 365.days.ago).delete_all
"
```

---

## Security Checklist

### Before Going Live

- [ ] Change all default passwords (PostgreSQL, Redis)
- [ ] Generate new `SECRET_KEY_BASE` (never reuse from example)
- [ ] Set `DISABLE_CHATWOOT_CONNECTIONS=true` (privacy)
- [ ] Set `ENABLE_ACCOUNT_SIGNUP=false` (unless you want public signups)
- [ ] Lock critical `installation_configs` (branding, privacy settings)
- [ ] Configure SSL/TLS (use reverse proxy like Traefik/Nginx)
- [ ] Enable firewall rules (only expose necessary ports)
- [ ] Setup regular database backups
- [ ] Configure Sentry or error tracking
- [ ] Review and limit admin access

---

## Quick Reference

### Essential Commands

```bash
# Restart CommMate
docker compose restart chatwoot sidekiq

# View logs
docker logs -f chatwoot

# Rails console
docker exec -it chatwoot bundle exec rails console

# Run migrations
docker exec chatwoot bundle exec rails db:migrate

# Set installation config
docker exec chatwoot bundle exec rails runner "
InstallationConfig.find_or_initialize_by(name: 'KEY').update!(value: 'VALUE')
"

# Check config value
docker exec chatwoot bundle exec rails runner "
puts GlobalConfig.get_value('KEY')
"
```

### Configuration Examples

```bash
# Example 1: Set webhook timeout
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_or_initialize_by(name: 'WEBHOOK_TIMEOUT')
config.value = 10
config.save!
"

# Example 2: Update branding
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_NAME')
config.value = 'My Company'
config.save!
"

# Example 3: Lock configuration
docker exec chatwoot bundle exec rails runner "
config = InstallationConfig.find_by(name: 'BRAND_NAME')
config.locked = true
config.save!
"
```

---

## Related Documentation

- **Development Setup**: `DEVELOPMENT.md` - Local development environment
- **Docker Setup**: `DOCKER-SETUP.md` - Docker compose configuration
- **Branding**: `REBRANDING.md` - CommMate branding system
- **Upgrades**: `UPGRADE.md` - Upgrading to new versions
- **Architecture**: `ARCHITECTURE.md` - Code organization
- **Release Process**: `IMAGE-RELEASE.md` - Building and publishing images

---

## Support

For issues or questions:
- **Documentation**: Check other docs in `custom/docs/`
- **Logs**: Always check `docker logs chatwoot` and `docker logs sidekiq`
- **Database**: Use `docker exec chatwoot bundle exec rails runner` for queries
- **CommMate Team**: Contact support team for production issues

---

**Last Updated**: December 7, 2025  
**Maintained By**: CommMate Team  
**Version**: 1.0

