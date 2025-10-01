# Fork Strategy for GP Bikes AI Assistant

## Overview

GP Bikes AI Assistant is built as a **strategic fork** of Chatwoot v4.6.0. This document explains our forking approach, maintenance strategy, and how to keep synchronized with upstream.

## Why We Forked Chatwoot

### Business Justification
- **Proven Foundation:** Chatwoot is battle-tested with 100k+ deployments
- **Complete Feature Set:** Multi-channel messaging, contact management, team collaboration
- **Active Maintenance:** Regular security updates and bug fixes from upstream
- **Open Source License:** MIT license allows commercial use and modification
- **WhatsApp Integration:** Native WhatsApp Business API support

### Technical Benefits
- Ruby on Rails 7.2 with modern best practices
- Vue.js 3 frontend with component architecture
- PostgreSQL with full-text search capabilities
- Redis for caching and background jobs
- Comprehensive test suite (RSpec + Jest)

## Fork Strategy: Additive Customization

We follow an **additive, not subtractive** approach:

### DO (Recommended):
- ✅ Add new models in `app/models/gp_bikes/`
- ✅ Create concerns in `app/models/concerns/gp_bikes/`
- ✅ Add controllers in `app/controllers/gp_bikes/`
- ✅ Create new Vue components in `app/javascript/dashboard/routes/gp_bikes/`
- ✅ Add workers in `app/workers/ai_workers/`
- ✅ Extend existing classes using Rails concerns
- ✅ Add database migrations with `gp_bikes_` prefix

### AVOID (When Possible):
- ❌ Modifying Chatwoot core files directly
- ❌ Removing Chatwoot features
- ❌ Changing database schema of core tables
- ❌ Editing Chatwoot's Vue components directly

### When Core Modifications Are Necessary:
If you must modify core Chatwoot code:
1. Document the change in `CUSTOMIZATIONS.md`
2. Add comments with `# GP_BIKES_CUSTOM:` prefix
3. Consider extracting to a concern or decorator pattern
4. Create tests to ensure changes don't break on upstream updates

## Step-by-Step Fork Setup

### 1. Fork on GitHub (Browser)

1. Navigate to: https://github.com/chatwoot/chatwoot
2. Click "Fork" button (top right)
3. Configure fork:
   - **Owner:** Your GitHub organization (e.g., `gp-bikes-yamaha`)
   - **Repository name:** `gp-bikes-ai-assistant`
   - **Description:** "AI-powered WhatsApp automation for Yamaha GP Bikes - Built on Chatwoot"
   - **Visibility:** Private (recommended) or Public
   - ✅ Check: "Copy the main branch only"
4. Click "Create fork"
5. Wait for fork to complete (30-60 seconds)

### 2. Clone Your Fork (Terminal)

```bash
# Navigate to your projects directory
cd ~/Projects  # or wherever you keep projects

# Clone YOUR fork (replace with your org name)
git clone git@github.com:gp-bikes-yamaha/gp-bikes-ai-assistant.git "GP Bikes"

# Navigate into the directory
cd "GP Bikes"

# Verify you're on the main branch
git branch
# Should show: * main
```

### 3. Add Upstream Remote

This allows you to pull updates from Chatwoot:

```bash
# Add Chatwoot as upstream remote
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Verify remotes
git remote -v
# Should show:
# origin    git@github.com:gp-bikes-yamaha/gp-bikes-ai-assistant.git (fetch)
# origin    git@github.com:gp-bikes-yamaha/gp-bikes-ai-assistant.git (push)
# upstream  https://github.com/chatwoot/chatwoot.git (fetch)
# upstream  https://github.com/chatwoot/chatwoot.git (push)

# Fetch upstream branches (don't merge yet)
git fetch upstream

# List available upstream tags
git tag -l | grep -E "v4\.[0-9]+\.[0-9]+" | tail -5
```

### 4. Create Development Branch

We maintain two primary branches:

- **main:** Stable, production-ready code (synced from upstream main)
- **gp-bikes-develop:** Active development with GP Bikes customizations

```bash
# Create and switch to development branch
git checkout -b gp-bikes-develop

# Push to remote
git push -u origin gp-bikes-develop

# Set this as your default working branch
git config branch.gp-bikes-develop.rebase true
```

### 5. Tag Initial Fork Point

Important for tracking divergence:

```bash
# Tag the exact commit where we forked
git tag -a v4.6.0-fork-base -m "Initial fork from Chatwoot v4.6.0"

# Push tag to remote
git push origin v4.6.0-fork-base
```

## Branch Strategy

```
main (synced from upstream/main)
  ↓
gp-bikes-develop (our main development branch)
  ↓
feature/sprint1-ai-worker (feature branches)
feature/sprint2-whatsapp-integration
feature/sprint3-vehicle-catalog
hotfix/critical-bug-fix
```

### Branch Naming Conventions

**Feature Branches:**
```bash
feature/sprint{N}-{description}
# Example: feature/sprint1-ai-worker-base
```

**Bugfix Branches:**
```bash
bugfix/{issue-number}-{description}
# Example: bugfix/42-conversation-state-bug
```

**Hotfix Branches:**
```bash
hotfix/{critical-issue}
# Example: hotfix/security-patch-openai
```

**Release Branches:**
```bash
release/v{version}
# Example: release/v1.0.0
```

## Keeping Synchronized with Upstream

### Check for Upstream Updates (Weekly)

```bash
# Fetch latest from Chatwoot
git fetch upstream

# See what's new
git log HEAD..upstream/main --oneline --graph

# Check for security releases
git tag -l | grep -E "v4\.[0-9]+\.[0-9]+" | tail -5
```

### Merge Upstream Updates (Monthly or for Security)

**IMPORTANT:** Always test in a separate branch first!

```bash
# Create a sync branch
git checkout gp-bikes-develop
git checkout -b sync/upstream-$(date +%Y%m%d)

# Merge upstream changes
git merge upstream/main

# Resolve conflicts (if any)
# Priority: Keep GP Bikes customizations, integrate Chatwoot improvements

# Test thoroughly
docker-compose down -v
docker-compose up -d
docker-compose exec app rails db:migrate
docker-compose exec app bundle exec rspec

# If tests pass, merge to gp-bikes-develop
git checkout gp-bikes-develop
git merge sync/upstream-$(date +%Y%m%d)
git push origin gp-bikes-develop
```

### Handling Merge Conflicts

Common conflict areas:

1. **Gemfile / package.json:**
   - Keep both upstream dependencies AND our additions
   - Run `bundle install` and `npm install` after resolving

2. **Routes (config/routes.rb):**
   - Keep Chatwoot routes + add our GP Bikes routes
   - Namespace our routes under `/gp_bikes/`

3. **Database Migrations:**
   - Never modify upstream migrations
   - If conflict, create a new migration to reconcile

4. **Configuration Files:**
   - Merge environment variables from both
   - Keep GP Bikes specific configs

## Security Updates

**CRITICAL:** Always apply security patches immediately.

### Subscribe to Security Notifications:

1. Watch Chatwoot repository: https://github.com/chatwoot/chatwoot
   - Click "Watch" → "Custom" → Check "Security alerts"

2. Monitor Chatwoot's security advisories:
   - https://github.com/chatwoot/chatwoot/security/advisories

3. Set up GitHub Dependabot:
   - Already enabled in forked repos by default
   - Review PRs from Dependabot weekly

### Emergency Security Patch Process:

```bash
# 1. Create hotfix branch
git checkout gp-bikes-develop
git checkout -b hotfix/security-$(date +%Y%m%d)

# 2. Fetch and merge specific security release
git fetch upstream
git merge upstream/main  # or specific tag like v4.6.1

# 3. Test immediately
docker-compose up -d
docker-compose exec app bundle exec rspec spec/models/
docker-compose exec app bundle exec rspec spec/controllers/

# 4. Deploy to staging ASAP
# 5. If staging passes, merge to main and deploy to production

# 6. Merge back to gp-bikes-develop
git checkout gp-bikes-develop
git merge hotfix/security-$(date +%Y%m%d)
```

## Tracking Customizations

### CUSTOMIZATIONS.md

We maintain a living document of all Chatwoot modifications:

```markdown
# GP Bikes Customizations to Chatwoot

## Core Model Extensions

### Conversation Model
- **File:** `app/models/concerns/gp_bikes/conversation_ai_handler.rb`
- **Purpose:** Adds AI worker orchestration
- **Upstream Impact:** Low (uses concern pattern)
- **Updated:** 2025-09-30

### Message Model
- **File:** `app/models/concerns/gp_bikes/message_ai_processor.rb`
- **Purpose:** AI-powered message classification
- **Upstream Impact:** Low (uses concern pattern)
- **Updated:** 2025-09-30

## Direct Modifications (Minimize These!)

### app/controllers/api/v1/accounts/conversations_controller.rb
- **Line:** 45-52
- **Change:** Added `ai_worker_enabled` parameter
- **Reason:** Enable/disable AI per conversation
- **Migration Risk:** Medium (may conflict on updates)
- **Marker:** `# GP_BIKES_CUSTOM: AI worker toggle`
- **Updated:** 2025-09-30
```

### Automated Customization Tracking

Add to `bin/check-customizations`:

```bash
#!/bin/bash
# Find all GP_BIKES_CUSTOM markers in codebase

echo "Scanning for GP Bikes customizations..."
grep -r "GP_BIKES_CUSTOM" app/ --include="*.rb" --include="*.vue" -n
```

## Testing Strategy for Fork Maintenance

### 1. Upstream Merge Testing

Before merging upstream changes:

```bash
# Run full test suite
docker-compose exec app bundle exec rspec

# Run frontend tests
docker-compose exec app npm run test

# Run integration tests for GP Bikes features
docker-compose exec app bundle exec rspec spec/integration/gp_bikes/

# Test AI workers specifically
docker-compose exec app bundle exec rspec spec/workers/ai_workers/
```

### 2. Regression Testing

After merging upstream:

```bash
# Test core Chatwoot features still work
# - Create conversation
# - Send message
# - Assign agent
# - Close conversation

# Test GP Bikes features still work
# - AI worker processes message
# - Vehicle catalog search
# - Appointment booking
# - Lead qualification
```

## When to Stop Syncing

Consider maintaining a **static fork** if:

- Upstream changes conflict with core GP Bikes logic > 3 times
- Customizations exceed 30% of codebase
- Upstream direction diverges from our needs
- Maintenance burden exceeds building from scratch

**Current Status:** Active sync recommended (< 5% customization expected)

## Rollback Strategy

If an upstream merge breaks production:

```bash
# 1. Identify last working commit
git log gp-bikes-develop --oneline

# 2. Create rollback branch
git checkout -b rollback/broken-merge
git revert <merge-commit-sha>

# 3. Test rollback
docker-compose up -d
# Run tests

# 4. Emergency deploy
git push origin rollback/broken-merge
# Deploy this branch to production

# 5. Investigate and fix properly in separate branch
```

## Resources

- **Chatwoot Docs:** https://www.chatwoot.com/docs
- **Chatwoot GitHub:** https://github.com/chatwoot/chatwoot
- **Chatwoot Discord:** https://discord.gg/cJXdrwS (for upstream discussions)
- **Our Sprint Plan:** `/docs/ROADMAP.md`

## Questions?

- **Fork strategy unclear?** → Ask @jorge (DevOps)
- **Merge conflicts?** → Ask @simón (Rails Architect)
- **Testing concerns?** → Ask @david (QA Lead)

---

**Last Updated:** 2025-09-30
**Maintained By:** Jorge (DevOps & Infrastructure)
**Review Schedule:** Monthly or after major upstream releases
