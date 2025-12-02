# CommMate Docker Setup Guide

**Last Updated**: 09/11/2025  
**Status**: Production Ready

---

## 🎯 **Automatic Setup - How It Works**

CommMate uses **Chatwoot's proven `db:chatwoot_prepare` task** for reliable database initialization.

### **Entrypoint Flow**

**File:** `custom/config/docker-entrypoint.sh`

```sh
1. Wait for PostgreSQL to be ready
2. Run: bundle exec rails db:chatwoot_prepare
3. Start Rails server
```

### **What db:chatwoot_prepare Does**

**Task:** `lib/tasks/db_enhancements.rake`

```ruby
unless table_exists?('ar_internal_metadata')
  # Fresh install
  load_schema      # Fast, skips buggy migrations
  db:seed         # Creates CommMate account/admin
end
db:migrate        # Run any new migrations
```

**Smart Detection:**
- Checks `ar_internal_metadata` (only created by schema:load)
- Fresh install: schema:load + seeds
- Existing install: migrations only
- Bulletproof, no restart loops

---

## 🚀 **Quick Start**

```bash
# Clone and start
git clone https://github.com/commmate/chatwoot
cd chatwoot
podman-compose -f docker-compose.commmate.yaml up -d

# That's it! Automatic setup happens on first start
```

**Access:** http://localhost:3000  
**Login:** admin@commmate.com / CommMate123!

---

## 🔧 **First-Time Behavior**

### **Fresh Database**

```
🚀 Starting CommMate...
⏳ Waiting for database...
✅ Database is ready
📦 Preparing database (using Chatwoot's db:chatwoot_prepare)...
   Loading database schema...
   Running seeds...
   🎨 Applying CommMate config overrides...
   ✅ CommMate config overrides applied
🎉 Starting Rails server...
* Listening on http://0.0.0.0:3000
```

**Result:**
- ✅ Schema loaded (skips buggy migrations)
- ✅ CommMate account created
- ✅ Super admin: admin@commmate.com created
- ✅ Branding applied
- ✅ Onboarding disabled
- ✅ Portuguese (pt_BR) set as default

### **Existing Database**

```
🚀 Starting CommMate...
✅ Database is ready
📦 Preparing database...
   Running migrations...
   Loading Installation config
   🎨 Applying CommMate config overrides...
🎉 Starting Rails server...
```

**Result:**
- ✅ Only new migrations run
- ✅ Existing data preserved
- ✅ Branding reapplied (if reverted)
- ✅ No duplicate admins created

---

## 📋 **Default Configuration**

### **Built into Image**

All these are defaults, overridable via environment variables:

```env
# Branding
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_NAME=CommMate
BRAND_URL=https://commmate.com
HIDE_BRANDING=true

# Locale
DEFAULT_LOCALE=pt_BR

# Privacy & Security  
DISABLE_CHATWOOT_CONNECTIONS=true
DISABLE_TELEMETRY=true
ENABLE_ACCOUNT_SIGNUP=false

# Email
MAILER_SENDER_EMAIL=CommMate <support@commmate.com>
```

### **Required in docker-compose**

```env
# Database
POSTGRES_HOST=postgres
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=<your_password>

# Redis
REDIS_URL=redis://redis:6379

# Rails
SECRET_KEY_BASE=<generate with: openssl rand -hex 64>
FRONTEND_URL=http://localhost:3000
```

---

## 🔐 **Privacy Features**

### **No External Connections**

CommMate blocks all connections to Chatwoot servers:

**Blocked endpoints:**
- `hub.2.chatwoot.com/ping` - Version checks ❌
- `hub.2.chatwoot.com/instances` - Registration ❌
- `hub.2.chatwoot.com/send_push` - Push notifications ❌
- `hub.2.chatwoot.com/events` - Analytics ❌

**Implementation:**
- `lib/chatwoot_hub.rb` - All methods check `DISABLE_CHATWOOT_CONNECTIONS`
- `app/jobs/internal/check_new_versions_job.rb` - Disabled
- `app/views/super_admin/.../_javascript.html.erb` - Support widget removed

**Result:** Zero telemetry, no version checks, complete privacy.

### **Update Notifications**

- Restricted to **SuperAdmins only** (not regular admins)
- Regular users never see update banners
- File: `app/javascript/dashboard/components/app/UpdateBanner.vue`

---

## 🌍 **Locale Configuration**

### **Default: Portuguese (Brazil)**

Set via multiple layers:

1. **Dockerfile:** `ENV DEFAULT_LOCALE="pt_BR"`
2. **installation_config.yml:** `DEFAULT_LOCALE: pt_BR`
3. **Seeds:** Account created with `locale: 'pt_BR'`
4. **Initializer:** Overrides if still 'en'

**To change:** Set `DEFAULT_LOCALE` env var in docker-compose.

**Supported locales:** Any Chatwoot locale (en, pt_BR, es, fr, etc.)

---

## 🐳 **Docker Compose Structure**

**Minimal docker-compose.commmate.yaml:**

```yaml
services:
  rails:
    image: commmate/commmate:v4.7.0.3
    environment:
      # Only required vars - all CommMate defaults built into image
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=chatwoot
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY_BASE=<your_secret>
      - FRONTEND_URL=http://localhost:3000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    # No command needed - uses entrypoint from image

  postgres:
    image: pgvector/pgvector:pg16  # Required for AI features
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
```

**Important:** No `command` override needed - image entrypoint handles everything.

---

## 🧪 **Testing Container Rebuild**

### **Verify Data Persistence**

```bash
# 1. Create test data (via UI or console)
podman exec commmate-rails bundle exec rails runner "
  User.create!(email: 'test@example.com', name: 'Test', password: 'Test123!')
"

# 2. Destroy app containers (keep postgres)
podman rm -f commmate-rails commmate-sidekiq

# 3. Start new containers
podman-compose -f docker-compose.commmate.yaml up -d rails sidekiq

# 4. Verify data exists
podman exec commmate-rails bundle exec rails runner "
  puts User.find_by(email: 'test@example.com').present? ? '✅ Data persisted' : '❌ Data lost'
"
```

**Expected:** ✅ All data persisted, branding intact

---

## 🔍 **Troubleshooting**

### **Branding Reverts to Chatwoot**

**Cause:** ConfigLoader overwrites on migrations  
**Fix:** Already handled by initializer (should not happen)  
**Verify:**
```bash
podman exec commmate-rails bundle exec rails runner "
  puts InstallationConfig.find_by(name: 'BRAND_NAME')&.value
"
# Should output: CommMate
```

### **Application Shows English Instead of Portuguese**

**Fix:**
```bash
podman exec commmate-rails bundle exec rails runner "
  # Set DEFAULT_LOCALE
  config = InstallationConfig.find_or_create_by(name: 'DEFAULT_LOCALE')
  config.value = 'pt_BR'
  config.save!
  
  # Update account locale
  Account.first.update!(locale: 'pt_BR')
  
  GlobalConfig.clear_cache
"
```

Refresh browser after.

### **Restart Loop / Container Keeps Crashing**

**Cause:** Migration bug (20231211010807_add_cached_labels_list.rb)  
**Solution:** db:chatwoot_prepare uses schema:load for fresh installs, avoiding the bug  
**Verify:** Check logs don't show repeated "Running database migrations..."

If loop persists, clean volumes and restart:
```bash
podman-compose -f docker-compose.commmate.yaml down -v
podman-compose -f docker-compose.commmate.yaml up -d
```

### **Onboarding Screen Appears**

**Cause:** Redis flag not cleared  
**Fix:** Seeds handle this automatically  
**Manual fix:**
```bash
podman exec commmate-rails bundle exec rails runner "
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
"
```

---

## 📊 **Verification Checklist**

After `docker-compose up`:

- [ ] No restart loops
- [ ] Puma starts and listens on port 3000
- [ ] Login page accessible
- [ ] Branding shows "CommMate" (not "Chatwoot")
- [ ] Interface in Portuguese
- [ ] Can login with admin@commmate.com
- [ ] No errors in `podman logs commmate-rails`
- [ ] Sidekiq processing jobs

---

## 🎓 **Key Learnings**

### **Why We Use db:chatwoot_prepare**

Original Chatwoot uses this task for a reason:
- ✅ Handles fresh vs existing intelligently
- ✅ Uses schema:load for fresh (fast, avoids migration bugs)
- ✅ Uses migrations for existing (safe, only new ones)
- ✅ Production-tested by Chatwoot team
- ✅ Works with Heroku, Docker, systemd

**Don't reinvent the wheel** - use Chatwoot's proven approach.

### **Why ConfigLoader is Tricky**

- Runs automatically after **every** migration
- Designed to ensure all configs exist
- Will create missing configs with defaults
- **Solution:** Override AFTER it runs (initializer)

### **Multiple Layers = Resilience**

CommMate branding uses 4 layers:
1. Docker ENV (defaults)
2. Migration (one-time setup)
3. Initializer (on every startup)
4. Config file (defines what to override)

**Result:** Branding never reverts, even if user manually changes configs.

---

## 🔗 **Related Documentation**

- **Development:** `DEVELOPMENT.md`
- **Building Images:** `IMAGE-RELEASE.md`
- **Branding Details:** `REBRANDING.md`
- **Upgrading:** `UPGRADE.md`

