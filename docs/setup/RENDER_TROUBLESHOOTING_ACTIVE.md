# 🚨 Render Deployment Troubleshooting - ACTIVE ISSUE

**Date:** October 1, 2025  
**Status:** 🔴 INVESTIGATING - Failed Deploy  
**Service:** crm-agents (Ruby)  
**Dashboard:** https://dashboard.render.com (Usuario: Ke-ai)

---

## 📊 Current Status (From Screenshot)

### ✅ Working:
- **PostgreSQL 17:** Available (deployed 14h ago)
- **Region:** Oregon
- **Account:** Active and configured

### ❌ Failed:
- **Ruby Service (crm-agents):** Failed deploy (deployed 4h ago)
- **Status:** Red "Failed deploy" indicator
- **Runtime:** Ruby

---

## 🔍 Possible Causes & Solutions

### Issue 1: Missing Build Script

**Likely Cause:** The service doesn't have `bin/render-build.sh` in the deployed branch

**Check:**
```bash
# Ver qué branch está conectado en Render
# Dashboard → crm-agents → Settings → Build & Deploy → Branch

# Verificar si el archivo existe en esa branch
git checkout <branch-name>
ls -la bin/render-build.sh
```

**Solution:**
```bash
# Si el archivo no existe o no es ejecutable:
chmod +x bin/render-build.sh
git add bin/render-build.sh
git commit -m "Add executable Render build script"
git push origin <branch-name>

# Render auto-redeploys si autoDeploy está habilitado
```

---

### Issue 2: pnpm Not Found

**Error típico:**
```
/bin/sh: pnpm: not found
Error: Command failed: pnpm install
```

**Solution:**
Asegúrate que `bin/render-build.sh` incluya:
```bash
corepack enable
corepack prepare pnpm@10.2.0 --activate
```

**Nuestro script YA lo incluye**, pero verifica que esté en el branch correcto.

---

### Issue 3: Node.js Version Mismatch

**Error típico:**
```
The engine "node" is incompatible with this module
```

**Check:**
```bash
# Ver qué Node.js está configurado
cat package.json | grep "engines" -A 3
```

**Expected:**
```json
"engines": {
  "node": "23.x",
  "pnpm": "10.x"
}
```

**Solution:**
Si no coincide, Render usa la versión especificada en `package.json`.

---

### Issue 4: Missing Environment Variables

**Síntomas:**
```
undefined method `[]' for nil:NilClass (NoMethodError)
ERROR: SECRET_KEY_BASE is not set
```

**Check:**
1. Dashboard → crm-agents → Environment
2. Verificar que existan:
   - `SECRET_KEY_BASE`
   - `RAILS_MASTER_KEY`
   - `DATABASE_URL` (auto-populated)
   - `REDIS_URL` (si tienes Redis)

**Solution:**
```bash
# Generar SECRET_KEY_BASE
bundle exec rails secret
# Copiar output a Render Dashboard → Environment

# RAILS_MASTER_KEY
cat config/master.key
# Copiar contenido a Render Dashboard → Environment
```

---

### Issue 5: Database Migration Failure

**Error típico:**
```
PG::UndefinedTable: ERROR:  relation "accounts" does not exist
rake aborted!
ActiveRecord::StatementInvalid
```

**Solution:**
1. Verify `release` command in Procfile:
   ```
   release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && echo $SOURCE_VERSION > .git_sha
   ```

2. Check if PostgreSQL 17 is compatible:
   - Your PostgreSQL is version **17** (muy nueva!)
   - Rails 7.1 officially supports PostgreSQL 16
   - May need compatibility adjustments

**Quick Fix:**
```ruby
# config/database.yml
production:
  adapter: postgresql
  # Explicitly set encoding
  encoding: unicode
  # Add compatibility settings for PG 17
  variables:
    statement_timeout: 14s
```

---

### Issue 6: Asset Compilation Failure

**Error típico:**
```
Vite manifest not found
SassC::SyntaxError
ExecJS::RuntimeError
```

**Check:**
```bash
# Test build locally
./bin/render-build.sh

# Should output:
# ✅ Build completed successfully!
```

**Solution:**
If fails locally, fix errors before pushing to Render.

---

## 🛠️ Step-by-Step Diagnostic Process

### Step 1: Check Render Logs

**In Render Dashboard:**
1. Click on `crm-agents` service (the failed one)
2. Go to "Logs" tab
3. Look for the **specific error message**

**Common error patterns to look for:**
```
❌ "pnpm: not found"
❌ "SECRET_KEY_BASE is required"
❌ "pg_vector extension does not exist"
❌ "relation does not exist"
❌ "Vite manifest not found"
❌ "Out of memory"
```

---

### Step 2: Verify Branch & Files

```bash
# Check what branch Render is deploying
# Dashboard → Settings → Build & Deploy → Branch

# Switch to that branch locally
git checkout <branch-name>

# Verify critical files exist:
ls -la bin/render-build.sh      # Should exist and be executable
ls -la Procfile                  # Should exist
ls -la render.yaml              # Should exist (if using Blueprint)
ls -la config/master.key        # Should exist but NOT in Git
```

---

### Step 3: Test Build Locally

```bash
# Run the exact build command Render uses
./bin/render-build.sh

# If it fails locally, fix those errors first
# Common fixes:
bundle install
pnpm install
bundle exec rails assets:precompile
```

---

### Step 4: Check Environment Variables

**Required variables in Render Dashboard:**
- [ ] `RAILS_ENV=production`
- [ ] `RACK_ENV=production`
- [ ] `NODE_ENV=production`
- [ ] `SECRET_KEY_BASE` (generate with: `bundle exec rails secret`)
- [ ] `RAILS_MASTER_KEY` (from `config/master.key`)
- [ ] `DATABASE_URL` (should be auto-populated from PostgreSQL service)

**Optional but recommended:**
- [ ] `RAILS_LOG_LEVEL=info`
- [ ] `RAILS_SERVE_STATIC_FILES=true`
- [ ] `FORCE_SSL=true`

---

### Step 5: Check Database Connection

**In Render Dashboard:**
1. Go to PostgreSQL service
2. Go to "Connect" tab
3. Copy the "Internal Database URL"
4. Paste in crm-agents service → Environment → `DATABASE_URL`

**Format should be:**
```
postgresql://user:password@internal-host:5432/database_name
```

---

### Step 6: Manual Redeploy

**Option A: Trigger Manual Deploy**
1. Dashboard → crm-agents
2. Click "Manual Deploy"
3. Select branch
4. Click "Deploy"
5. Watch logs in real-time

**Option B: Force Push to Trigger Deploy**
```bash
git commit --allow-empty -m "Trigger Render redeploy"
git push origin <branch-name>
```

---

## 🎯 Quick Fix Checklist

Before redeploying, ensure:

- [ ] `bin/render-build.sh` exists and is executable
- [ ] `Procfile` has correct commands
- [ ] All environment variables set in Render Dashboard
- [ ] `config/master.key` value copied to `RAILS_MASTER_KEY`
- [ ] PostgreSQL service is "Available"
- [ ] Branch specified in Render matches your working branch
- [ ] Build script runs successfully locally

---

## 📋 Information Needed to Debug

Please provide:

1. **Branch name** deployed in Render
2. **Render logs** from the failed deploy (last 50-100 lines)
3. **Environment variables** currently set (just the keys, not values)
4. **PostgreSQL version compatibility** (you have PG 17, Rails expects PG 16)

---

## 🚀 Recommended Next Steps

### Immediate (Next 15 minutes):

1. **Access Render Dashboard**
   ```
   https://dashboard.render.com
   → Click on "crm-agents" (failed service)
   → Go to "Logs" tab
   → Copy last 100 lines of error logs
   ```

2. **Check Branch**
   ```bash
   # In Render Dashboard → crm-agents → Settings
   # Note the "Branch" field
   
   # Then locally:
   git branch -a
   # Confirm that branch exists
   ```

3. **Verify Build Script**
   ```bash
   git checkout <branch-from-render>
   ls -la bin/render-build.sh
   cat bin/render-build.sh | grep "pnpm"
   # Should see: corepack prepare pnpm@10.2.0
   ```

4. **Push Our New Configuration**
   ```bash
   # If bin/render-build.sh is missing in that branch:
   git checkout <branch-from-render>
   git add bin/render-build.sh render.yaml
   git commit -m "Add Render production configuration"
   git push origin <branch-from-render>
   ```

---

### Next 1 Hour:

5. **Review Environment Variables**
   - Render Dashboard → crm-agents → Environment
   - Add missing variables (see Step 4 above)

6. **Test PostgreSQL 17 Compatibility**
   ```bash
   # In your local terminal
   psql --version
   # If you have PG 16 locally but 17 in Render, may cause issues
   ```

7. **Manual Redeploy**
   - Dashboard → Manual Deploy
   - Watch logs carefully
   - Note exact error message

---

## 💡 Most Likely Solution

Based on common Render deployment failures, **the most probable issue is:**

### **Missing or Incorrect Build Command**

**Current (in Render Dashboard):**
```bash
# Probably something like:
bundle install && npm install && bundle exec rails assets:precompile
```

**Should be:**
```bash
./bin/render-build.sh
```

**To fix:**
1. Dashboard → crm-agents → Settings → Build & Deploy
2. Find "Build Command" field
3. Change to: `./bin/render-build.sh`
4. Click "Save Changes"
5. Click "Manual Deploy"

---

## 📞 Need More Help?

If the issue persists:

1. **Share with me:**
   - Screenshot of full error logs from Render
   - Output of: `git branch -a` (show all branches)
   - Output of: `ls -la bin/render-build.sh`

2. **Check Render Status Page:**
   - https://status.render.com
   - Verify no platform-wide issues

3. **Render Support:**
   - Community: https://community.render.com
   - Support: support@render.com

---

## 🎓 Learning from This

**Key Takeaway:** Always verify:
1. ✅ Branch consistency (local vs Render)
2. ✅ Build script exists and is executable
3. ✅ Environment variables are set
4. ✅ Database compatibility (PG 17 is very new)

**This is normal!** Deployment troubleshooting is part of the process. We'll get it working. 💪

---

**Status:** ⏳ Awaiting Render logs and branch information  
**Next Action:** Share error logs from Render Dashboard → Logs tab


