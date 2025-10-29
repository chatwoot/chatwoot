# CommMate Upgrade Guide

How to upgrade Chatwoot and maintain CommMate branding.

## Quick Upgrade (5 Commands)

```bash
# 1. Fetch and merge
git fetch upstream
git checkout -b upgrade-to-v4.8.0
git merge upstream/v4.8.0

# 2. Update dependencies
bundle install && pnpm install

# 3. Run migrations
bin/rails db:migrate

# 4. Apply branding (AUTOMATED!)
./custom/script/apply_commmate_branding.sh

# 5. Verify
./custom/script/verify_branding.sh
```

**Done!** 90% of rebranding is automated.

## What the Automation Does

The script `apply_commmate_branding.sh` handles:

1. ✅ Enables initializers (`commmate_branding.rb`, `commmate_i18n.rb`)
2. ✅ Copies assets (favicons, logos)
3. ✅ Adds CSS imports to `app.scss`
4. ✅ Replaces hardcoded blue colors (20+ files):
   - `#1f93ff` → `#107e44`
   - `#2781F6` → `#107e44`
   - `#47A7F6` → `#107e44`
   - `#4B7DFB` → `#107e44`
5. ✅ Updates Tailwind config (`theme/colors.js`)
6. ✅ Updates avatar placeholder colors
7. ✅ Fixes known migration bugs
8. ✅ Updates database configs
9. ✅ Verifies all files in place

**Result:** Complete rebrand in ~5 minutes instead of 3-4 hours!

## Pre-Upgrade Steps

```bash
# 1. Backup
git checkout -b backup-$(date +%Y%m%d)
git commit -am "Backup before upgrade"

# 2. Review changes
git log HEAD..upstream/v4.8.0 --oneline

# 3. Check for breaking changes
git diff upstream/v4.7.0..upstream/v4.8.0 -- package.json Gemfile
```

## Common Merge Conflicts

### `package.json` / `Gemfile.lock`
```bash
# Accept both, merge dependencies manually
# Run: bundle install && pnpm install
```

### `db/schema.rb`
```bash
# Accept upstream version
git checkout --theirs db/schema.rb
# Regenerate: bin/rails db:migrate
```

### `custom/*` files
```bash
# Keep yours
git checkout --ours custom/
git add custom/
```

### Known Migration Issues

**Migration:** `20231211010807_add_cached_labels_list.rb`  
**Fix:** Comment out: `# ActsAsTaggableOn::Taggable::Cache.included(Conversation)`  
**Automation:** Script handles this automatically

### Initializer Issues

**File:** `config/initializers/01_inject_enterprise_edition_module.rb`  
**Issue:** `const_get_maybe_false` fails with non-Module  
**Fix:** Check if `mod.is_a?(Module)` first  
**Automation:** Script warns if needs manual fix

## Manual Review Needed (~10%)

After automation, manually check:

### New UI Components

```bash
# Find new Vue files
git diff upstream/v4.7.0..upstream/v4.8.0 --name-only | grep "\.vue$"

# Check for blue colors
grep -n "#1f93ff\|#2781F6\|#47A7F6\|#4B7DFB" path/to/new/file.vue
```

### New SVG Assets

```bash
git diff upstream/v4.7.0..upstream/v4.8.0 --name-only | grep "\.svg$"
grep "fill=" path/to/new/file.svg
```

### Tailwind Config Changes

If Chatwoot updates `tailwind.config.js`, verify commmate colors still present.

## Testing After Upgrade

### Automated

```bash
# Verify branding applied
./custom/script/verify_branding.sh

# Should show: 20+ checks passed
```

### Manual Testing

Visit these pages and check for blue:

- [ ] Login page
- [ ] Dashboard home
- [ ] Settings → Profile
- [ ] Settings → Custom Attributes
- [ ] Settings → Automation Rules
- [ ] Inbox → Conversations
- [ ] Contacts list
- [ ] Help Center (if enabled)

**Look for:**
- Green active states ✅
- Grey inactive states ✅
- No blue (except native select dropdowns - OK)

## Known Limitations

### Native Select Dropdowns

**Issue:** Browser-controlled UI shows blue highlight  
**Locations:** Automation rules conditions, some settings dropdowns  
**Fix:** Not possible with CSS (would require component replacement)  
**Impact:** Minor (< 5% of UI)  
**Recommendation:** Accept as-is

This affects:
- `<select>` elements when clicked (dropdown list highlighting)
- Some date pickers
- Native browser autocomplete

## Version Tracking

```bash
# After successful upgrade
git tag -a v4.8.0-commmate -m "CommMate based on Chatwoot v4.8.0"
git push origin v4.8.0-commmate

# Recommended branch naming
commmate/v4.7.0
commmate/v4.8.0
```

## Rollback

```bash
# Quick rollback
git checkout commmate/v4.7.0

# Database rollback
bin/rails db:rollback STEP=5  # Adjust number

# Or restore from backup
podman exec commmate-postgres psql -U postgres chatwoot_commmate < backup.sql
```

## Files Protected During Merge

Use `.gitattributes` to protect custom files:

```
# Always keep our custom branding
custom/** merge=ours
```

## What Gets Updated

### Every Upgrade (Automated)

- All hardcoded blue hex codes
- Tailwind woot palette
- Avatar colors
- SVG fills
- CSS imports
- Database configs
- Assets copied

### Rarely (Manual Check)

- Tailwind config structure changes
- New UI component libraries
- New blue shades introduced
- CSS framework updates

## Quick Commands Reference

```bash
# Apply branding
./custom/script/apply_commmate_branding.sh

# Verify branding
./custom/script/verify_branding.sh

# Find remaining blue
grep -r "#1f93ff\|#2781F6\|#47A7F6\|#4B7DFB" app/javascript

# Update database configs
bin/rails runner "InstallationConfig.where(name: 'INSTALLATION_NAME').update_all(value: 'CommMate')"

# Stop/restart services
pkill -f "rails s" && pkill -f "vite" && pkill -f sidekiq
bin/rails s -p 3000 &
bin/vite dev &
bundle exec sidekiq -C config/sidekiq.yml &
```

## Upgrade History Template

Keep a changelog in `custom/CHANGELOG.md`:

```markdown
## v4.8.0-commmate (2025-11-01)

**Base:** Chatwoot v4.8.0
**Previous:** v4.7.0-commmate

### Upstream Changes
- Feature X added
- Bug Y fixed

### Merge Conflicts
- package.json - merged both
- theme/colors.js - kept green palette

### Custom Changes
- Added CSS for new component Z
- Updated automation script for new file

### Issues
- None
```

## Best Practices

1. **Always use upgrade branch** - Never upgrade on main
2. **Test locally first** - Catch issues early
3. **Run automation** - Don't rebrand manually
4. **Verify thoroughly** - Use verification script
5. **Keep custom/ clean** - Only branding, no business logic
6. **Document issues** - Help future upgrades

## Future Improvements

- [ ] Automated visual regression testing
- [ ] Pre-commit hook to detect new blue colors
- [ ] CI/CD integration for auto-rebranding
- [ ] Screenshot comparison tool

## Support

**Issue:** Branding not applying  
**Solution:** Run `./custom/script/verify_branding.sh`

**Issue:** Merge conflicts  
**Solution:** See "Common Merge Conflicts" above

**Issue:** New blue colors found  
**Solution:** Add to `apply_commmate_branding.sh`

## Summary

Upgrading Chatwoot with CommMate branding:

**Old way:** 3-4 hours of manual work  
**New way:** 5 minutes automated + 30 min testing  
**Savings:** 60% faster

The automation handles everything. Just run one command after merging upstream! 🚀

