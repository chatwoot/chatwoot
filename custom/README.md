# CommMate Customizations

This directory contains all CommMate-specific customizations for the Chatwoot fork.

## 📁 Directory Structure

```
custom/
├── assets/           # Custom logos, favicons, images
├── config/           # Branding configuration files
├── docs/             # Documentation
├── locales/          # Custom translations
├── script/           # Automation scripts
├── styles/           # Custom CSS/SCSS
└── views/            # Custom API views
```

## 🚀 Quick Start

### First Time Setup

```bash
# 1. Apply all branding
./custom/script/apply_commmate_branding.sh

# 2. Verify it worked
./custom/script/verify_branding.sh

# 3. Restart services and test
```

### After Chatwoot Upgrade

```bash
# Merge new Chatwoot version
git merge upstream/v4.8.0

# Reapply branding automatically
./custom/script/apply_commmate_branding.sh

# Verify
./custom/script/verify_branding.sh
```

## 📚 Documentation

**Essential guides:**

- **[DOWNSTREAM-RELEASE.md](docs/DOWNSTREAM-RELEASE.md)** - **Step 1:** Downstream & create release branches
- **[IMAGE-RELEASE.md](docs/IMAGE-RELEASE.md)** - **Step 2:** Build & publish Docker images
- **[UPGRADE.md](docs/UPGRADE.md)** - How to upgrade existing installations
- **[REBRANDING.md](docs/REBRANDING.md)** - Branding system & environment variables
- **[DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Setup and run locally

### Also See

- **Brand Colors:** `/docs/BRAND_COLORS.md`
- **Chatwoot Extensions:** `../COMMMATE_EXTENSIONS.md`
- **Chatwoot Dev Guide:** `../AGENTS.md`

## 🛠️ Scripts

### Automation Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `apply_commmate_branding.sh` | Apply all branding changes | After Chatwoot upgrade |
| `verify_branding.sh` | Verify branding is correct | After rebranding |
| `build_commmate_image.sh` | Build Docker image | For production deployment |

### How to Run

```bash
# Make executable (first time only)
chmod +x custom/script/*.sh

# Run any script
./custom/script/apply_commmate_branding.sh
```

## 🎨 Branding Components

### Colors

**CommMate Green Palette:**
- Primary: `#107e44`
- Secondary: `#27954c`
- Tertiary: `#59b44b`
- Quaternary: `#8cc540`

See `/docs/BRAND_COLORS.md` for full palette.

### Assets

- **Favicons:** `assets/favicons/` → `public/`
- **Logos:** `assets/logos/` → `public/brand-assets/`
- **Images:** `assets/images/` (custom images)

### Styles

- **Variables:** `styles/variables.scss` - CSS custom properties
- **Branding:** `styles/branding.scss` - All branding overrides

### Translations

- **Portuguese:** `locales/pt_BR_custom.yml` - Full PT-BR translations
- **English:** `locales/en_custom.yml` - English overrides

### Configuration

- **Branding:** `config/branding.yml` - Main branding config
- **Initializers:** `config/initializers/` - Rails initializers (backups)

## 🔄 Upgrade Workflow

```
New Chatwoot Release
        ↓
Fetch & Merge (manual)
        ↓
Update Dependencies (bundle/pnpm)
        ↓
Run Migrations (bin/rails db:migrate)
        ↓
Apply Branding (./custom/script/apply_commmate_branding.sh) ← AUTOMATED!
        ↓
Verify (./custom/script/verify_branding.sh) ← AUTOMATED!
        ↓
Test & Deploy
```

## ⚡ Key Features

### ✅ Automated
- Color replacements (blue → green)
- Asset copying
- CSS imports
- Database config updates
- Initializer activation

### 🔧 Manual Review Needed
- New UI components (check for blue)
- Merge conflicts in core files
- New features requiring custom translations
- Breaking changes in Chatwoot

## 📦 What's NOT in Custom Folder

To maintain upgradability, we DON'T put these in custom/:
- Database migrations (stay in `db/migrate/`)
- Core models (stay in `app/models/`)
- Controllers (stay in `app/controllers/`)
- Routes (stay in `config/routes.rb`)

**Why?** These files need to merge cleanly with upstream Chatwoot.

## 🎯 CommMate-Specific Features

Custom features should go in:
- `custom/views/api/v1/accounts/*/` - API views
- Translations in `locales/`
- Styles in `styles/`

Example: Pipelines feature
- Model: `app/models/pipeline.rb` (core)
- Views: `custom/app/views/api/v1/accounts/pipelines/` (custom)
- Translations: `custom/locales/pt_BR_custom.yml` (custom)

## 🐛 Troubleshooting

### Script fails?
```bash
# Check logs
cat /tmp/commmate_branding_*.log

# Run with debug
bash -x ./custom/script/apply_commmate_branding.sh
```

### Colors not changing?
```bash
# Verify Vite is running
lsof -i:3036

# Check browser console for CSS errors
# Hard refresh: Cmd/Ctrl + Shift + R
```

### Assets missing?
```bash
# Check source exists
ls -la custom/assets/favicons/
ls -la custom/assets/logos/

# Manually copy
cp -r custom/assets/favicons/* public/
cp custom/assets/logos/* public/brand-assets/
```

## 📝 Adding New Customizations

1. **New CSS Styles**
   - Add to `custom/styles/branding.scss`
   - Use CSS variables: `var(--color-primary)`

2. **New Translations**
   - Add to `custom/locales/pt_BR_custom.yml`
   - Use I18n keys from Chatwoot

3. **New Assets**
   - Add to `custom/assets/`
   - Update `apply_commmate_branding.sh` to copy them

4. **New Configuration**
   - Add to `custom/config/branding.yml`
   - Update `commmate_branding.rb` initializer if needed

## 🔐 Version Control

**Commit custom changes:**
```bash
git add custom/
git commit -m "feat: add custom branding for feature X"
```

**Keep custom/ in Git:**
- ✅ All files in `custom/` should be committed
- ✅ Generated files in `public/` are copied from `custom/`
- ✅ Scripts are versioned
- ✅ Documentation is versioned

## 📊 Maintenance

### Monthly
- Check for new Chatwoot releases
- Review changelog for branding impact
- Update dependencies if needed

### Per Upgrade
- Run automation scripts
- Test thoroughly
- Update documentation if needed
- Create version tag

### Ad-hoc
- Add new custom features
- Update brand colors (if rebrand)
- Add new translations

## 🎓 Learning Path

1. **First time?** Start with `docs/DEVELOPMENT.md`
2. **Upgrading Chatwoot?** Read `docs/UPGRADE.md`
3. **Understanding branding?** See `docs/REBRANDING.md`

## 💡 Pro Tips

1. **Use automation scripts** - Don't rebrand manually
2. **Test in incognito** - Avoid browser cache issues
3. **Keep custom/ clean** - Don't add unnecessary files
4. **Document changes** - Future you will thank you
5. **Backup before upgrade** - Always have a rollback plan

## 🆘 Support

**Issues with:**
- Branding not applying → Run `verify_branding.sh`
- Upgrade conflicts → See `UPGRADE.md`
- Local development → See `DEVELOPMENT.md`
- Understanding branding → See `REBRANDING.md`
- Colors/design → See `/docs/BRAND_COLORS.md`

## 🎉 Success Criteria

After running automation:

✅ Browser tab shows "CommMate"
✅ All buttons are green (#107e44)
✅ All links are green
✅ Logo is CommMate
✅ No blue colors visible
✅ `verify_branding.sh` passes

---

**Maintained by:** CommMate Development Team  
**Last Updated:** October 26, 2025  
**Current Base:** Chatwoot v4.7.0

