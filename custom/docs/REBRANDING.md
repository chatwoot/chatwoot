# CommMate Rebranding Complete Guide

Complete guide for understanding and maintaining CommMate branding.

**Version**: v4.7.0.1+  
**Last Updated**: December 2025  
**Status**: ✅ Production-ready with anti-revert protection

---

## Quick Reference

**Colors:** Green palette - Primary `#107e44`  
**Philosophy:** Green = Active/Selected states only (not wholesale replacement)  
**Coverage:** 95% of UI (native browser selects remain blue - browser limitation)

### Critical Environment Variables (Must Set)

```bash
DISABLE_CHATWOOT_CONNECTIONS=true  # Blocks external connections ⚠️ REQUIRED
DISABLE_TELEMETRY=true              # Disables data collection
INSTALLATION_NAME=CommMate          # Sets instance name
BRAND_NAME=CommMate                 # Sets brand name
DEFAULT_LOCALE=pt_BR                # Default language
```

**See "Required Environment Variables" section below for complete list.**

## Color Palette

```
Primary:    #107e44  (Main brand, buttons, active states)
Secondary:  #27954c  (Hover states, accents)
Tertiary:   #59b44b  (Success, highlights)
Quaternary: #8cc540  (Light accents, badges)
```

See `/docs/BRAND_COLORS.md` for full palette details.

## Design Philosophy

### ✅ Green Is Used For

- Active sidebar menu items
- Selected submenu items
- Active tabs
- Primary action buttons
- Selected conversation in list
- Checked checkboxes/radios
- Input focus states
- Active router links
- Hover on links/buttons

### ⚪ Grey Stays For

- Inactive menu items
- Inactive tabs
- Unselected options
- Secondary buttons
- Regular text
- Background elements

**Principle:** Green draws attention to active/important items without overwhelming the UI.

---

## The ConfigLoader Problem (Solved in v4.7.0.1)

### What Was Happening

Chatwoot has a task that runs **AFTER EVERY migration**:

```ruby
# lib/tasks/db_enhancements.rake
Rake::Task['db:migrate'].enhance do
  ConfigLoader.new.process  # Loads config/installation_config.yml
end
```

**The Issue:**
1. Container restarts or migrations run → ConfigLoader executes
2. ConfigLoader reads `config/installation_config.yml` (Chatwoot's file)
3. If any branding config missing, creates it with **"Chatwoot"** defaults
4. **CommMate branding gets overwritten!** ❌

This is why branding kept reverting in early CommMate versions (pre-v4.7.0.1).

### The Solution (4-Layer System)

CommMate v4.7.0.1+ implements a **defense-in-depth** approach:

1. **Docker ENV** - Defaults baked into image
2. **Installation Config** - CommMate-specific config file
3. **Runtime Initializer** - Runs AFTER ConfigLoader, fixes overwrites ⭐ **KEY FIX**
4. **Migration** - One-time database update (backup)

**Result**: Branding NEVER reverts, even after:
- Container restarts
- Database migrations
- ConfigLoader runs
- Manual config changes in UI

---

## How It Works

### Multi-Layer Branding System

**CommMate v4.7.0.1+ uses a 4-layer approach** to ensure branding NEVER reverts:

#### Layer 1: Docker ENV Defaults (Build-time)

**File**: `docker/Dockerfile.commmate`

```dockerfile
ENV APP_NAME="CommMate" \
    BRAND_NAME="CommMate" \
    INSTALLATION_NAME="CommMate" \
    BRAND_URL="https://commmate.com" \
    HIDE_BRANDING="true" \
    DEFAULT_LOCALE="pt_BR" \
    ENABLE_ACCOUNT_SIGNUP="false" \
    DISABLE_CHATWOOT_CONNECTIONS="true" \
    DISABLE_TELEMETRY="true" \
    MAILER_SENDER_EMAIL="CommMate <support@commmate.com>"
```

**Purpose**: Baked into Docker image - provides defaults even if configs fail.

#### Layer 2: Installation Config Defaults

**File**: `custom/config/installation_config.yml`

Contains CommMate-specific defaults that override Chatwoot's `config/installation_config.yml`:

```yaml
- name: INSTALLATION_NAME
  value: 'CommMate'
- name: BRAND_NAME
  value: 'CommMate'
- name: LOGO
  value: '/brand-assets/logo-full.png'
- name: LOGO_DARK
  value: '/brand-assets/logo-full-dark.png'
- name: LOGO_THUMBNAIL
  value: '/brand-assets/logo_thumbnail.png'
- name: BRAND_URL
  value: 'https://commmate.com'
- name: WIDGET_BRAND_URL
  value: 'https://commmate.com'
```

#### Layer 3: Runtime Initializer Override (PRIMARY FIX)

**File**: `custom/config/initializers/commmate_config_overrides.rb`

**THE KEY FIX**: Runs AFTER Chatwoot's `ConfigLoader` on every Rails startup:

```ruby
Rails.application.config.after_initialize do
  # Load CommMate overrides
  commmate_configs = YAML.safe_load(File.read('custom/config/installation_config.yml'))
  
  commmate_configs.each do |config|
    existing = InstallationConfig.find_by(name: config[:name])
    
    # Only override if value is still Chatwoot default
    if existing.value == 'Chatwoot'
      existing.update!(value: 'CommMate')
    end
  end
  
  GlobalConfig.clear_cache
end
```

**Why This Matters:**
- Chatwoot's `ConfigLoader` runs after migrations and resets configs to "Chatwoot"
- This initializer runs AFTER ConfigLoader and fixes it automatically
- Only overrides Chatwoot defaults (preserves user customizations)
- Runs on EVERY startup - bulletproof protection

#### Layer 4: Migration (One-time)

**File**: `db/migrate/20251102174650_apply_commmate_branding.rb`

Applies branding once during database setup (backup redundancy).

**Result**: Even if layers 2-3 fail, branding still applies.

### 1. Configuration Files (Legacy - Still Present)

**`config/initializers/commmate_branding.rb`** (Deprecated - ENV vars now in Dockerfile)
Loads `custom/config/branding.yml` and sets environment variables:

```ruby
ENV['APP_NAME'] = 'CommMate'
ENV['BRAND_PRIMARY_COLOR'] = '#107e44'
ENV['BRAND_URL'] = 'https://commmate.com'
```

**`config/initializers/commmate_i18n.rb`**
Loads custom Portuguese translations from `custom/locales/`.

### 2. CSS Architecture

**`custom/styles/variables.scss`**
```scss
:root {
  --color-primary: #107e44;
  --color-secondary: #27954c;
  // ... more variables
}
```

**`custom/styles/branding.scss`**
- Overrides `--blue-*` CSS variables → green
- Selective component styling (only active states)
- Browser-specific fixes (accent-color, etc.)

**`app/javascript/dashboard/assets/scss/app.scss`**
```scss
@import 'woot';
@import '../../../../../custom/styles/variables';
@import '../../../../../custom/styles/branding';
```

### 3. Tailwind Integration

**`theme/colors.js`**
```javascript
woot: {
  500: greenDark.green10,  // Changed from blueDark.blue10
  600: greenDark.green9,   // Changed from blueDark.blue9
  // ...
},
brand: '#107e44',  // Changed from '#2781F6'
```

**`tailwind.config.js`**
```javascript
colors: {
  commmate: {
    'primary': '#107e44',
    'secondary': '#27954c',
    // ...
  },
}
```

### 4. Assets

**Logos** (exact mappings for Docker build):
- `custom/assets/logos/logo-full.png` → `public/brand-assets/logo.png`
- `custom/assets/logos/logo-full-dark.png` → `public/brand-assets/logo_dark.png`
- `custom/assets/logos/logo-icon.png` → `public/brand-assets/logo_thumbnail.png`

**Favicons** (copied as-is):
- `custom/assets/favicons/favicon.ico` → `public/favicon.ico`
- `custom/assets/favicons/favicon-16x16.png` → `public/favicon-16x16.png`
- `custom/assets/favicons/favicon-32x32.png` → `public/favicon-32x32.png`
- `custom/assets/favicons/android-chrome-192x192.png` → `public/android-chrome-192x192.png`
- `custom/assets/favicons/android-chrome-512x512.png` → `public/android-chrome-512x512.png`
- `custom/assets/favicons/apple-touch-icon.png` → `public/apple-touch-icon.png`

**Note**: These mappings are important because Chatwoot expects specific filenames in `public/brand-assets/`.

### 5. Database Configs

```ruby
InstallationConfig updates:
- INSTALLATION_NAME → 'CommMate'
- LOGO → '/brand-assets/logo-full.png'
- LOGO_DARK → '/brand-assets/logo-full-dark.png'
```

### 6. Hardcoded Color Replacements

**Files updated (20+):**
- All `#1f93ff` → `#107e44` (old Chatwoot blue)
- All `#2781F6` → `#107e44` (brand blue)
- All `#47A7F6` → `#107e44` (light blue)
- All `#4B7DFB` → `#107e44` (hotkey images)
- Avatar placeholder colors (2 of 6 changed to green)

## What's Branded

### ✅ Fully Green

- Page title ("CommMate")
- Logos (all variations)
- Favicons
- Primary buttons
- Active menu items & tabs
- Selected items in lists
- Multiselect dropdowns (Vue components)
- Checkboxes (when checked)
- Radio buttons (when selected)
- Input focus borders
- Links (hover state)
- Progress bars
- Avatar placeholders (blue/purple variants)
- Hotkey preference images
- Widget colors
- SVG icon fills
- CSS variables

### ⚠️ Browser Controlled (Can't Change)

- Native `<select>` dropdown internals (Safari/Chrome system UI)
- Scrollbar colors (some browsers)

**Note:** This is a known browser limitation - even major products can't override native select dropdown highlighting.

## Key Files Modified

### Core Configuration
- `config/initializers/commmate_branding.rb`
- `config/initializers/commmate_i18n.rb`
- `custom/config/branding.yml`

### Styling
- `custom/styles/variables.scss`
- `custom/styles/branding.scss`
- `app/javascript/dashboard/assets/scss/app.scss`
- `theme/colors.js`
- `tailwind.config.js`

### Assets
- `public/favicon*.png` (7 files)
- `public/brand-assets/logo*` (4 files)
- `public/manifest.json`
- `public/assets/images/dashboard/profile/hot-key-*.svg` (4 files)

### Components (20+ files)
- Avatar.vue (placeholder colors)
- EmojiInput.vue, sdk.js, WidgetBuilder.vue, etc.
- All Vue components with hardcoded blue

### Layouts
- `app/views/layouts/vueapp.html.erb` (meta theme-color)

## Browser Compatibility

**accent-color (for checkboxes/radios):**
- Chrome 93+ ✅
- Safari 15.4+ ✅
- Firefox 92+ ✅
- Edge 93+ ✅

Coverage: ~95% of users

## Troubleshooting

### Colors Still Blue

```bash
# Hard refresh browser
Cmd/Ctrl + Shift + R

# Or restart Vite
pkill -f vite
bin/vite dev

# Clear browser cache completely
```

### Branding Not Applied

```bash
# Run verification
./custom/script/verify_branding.sh

# Reapply
./custom/script/apply_commmate_branding.sh

# Restart Rails (database configs)
pkill -f "rails s"
bin/rails s -p 3000
```

### Images Cached

SVG and PNG assets are heavily cached:
- Use incognito mode
- Clear browser cache
- Wait 5-10 seconds after changes

## Maintenance

### Adding New Custom Styles

Edit `custom/styles/branding.scss`:

```scss
.my-new-component {
  &.is-active {
    background-color: var(--color-primary) !important;
  }
}
```

### Changing Brand Colors

1. Update `custom/config/branding.yml`
2. Update `custom/styles/variables.scss`
3. Update `custom/script/apply_commmate_branding.sh` (replacement hex codes)
4. Run `./custom/script/apply_commmate_branding.sh`

### Adding New Assets

1. Add to `custom/assets/`
2. Update `custom/script/apply_commmate_branding.sh` to copy them
3. Run script

## Testing Checklist

### After Applying Branding (Development)

- [ ] Browser tab shows "CommMate"
- [ ] Login logo is CommMate
- [ ] Login button is green
- [ ] Sidebar logo is CommMate
- [ ] Active menu items are green
- [ ] Inactive menus are grey
- [ ] Primary buttons are green
- [ ] Active tabs have green border
- [ ] Inactive tabs are grey
- [ ] Checkboxes are green when checked
- [ ] Selected options in multiselect are green
- [ ] Avatar placeholders use green shades
- [ ] Hotkey images show green buttons
- [ ] No blue in major UI elements

### After Docker Deploy (Production)

**Quick verification on production URL** (e.g., https://crm.commmate.com):

1. **Visual Check:**
   - [ ] Browser tab title: "CommMate"
   - [ ] Favicon: CommMate logo (green icon)
   - [ ] Login page logo: CommMate full logo
   - [ ] Login button: Green (#107e44)

2. **After Login:**
   - [ ] Header logo: CommMate
   - [ ] Active menu items: Green
   - [ ] Primary buttons: Green
   - [ ] No Chatwoot branding visible

3. **Backend Verification:**
   ```bash
   # Check environment
   docker exec chatwoot env | grep -E 'APP_NAME|BRAND_NAME|INSTALLATION_NAME'
   # Expected: All show "CommMate"
   
   # Check database
   docker exec chatwoot bundle exec rails runner "
     puts GlobalConfig.get('INSTALLATION_NAME').to_s
     puts GlobalConfig.get('BRAND_NAME').to_s
   "
   # Expected: Both show "CommMate"
   ```

4. **Privacy Verification:**
   ```bash
   # Check no external connections
   docker logs chatwoot 2>&1 | grep -i "hub.2.chatwoot"
   # Expected: No results (no connections attempted)
   ```

**All checks passing** = ✅ Deployment successful

## Required Environment Variables

### Production Deployment (Critical)

**These environment variables MUST be set** in production for CommMate branding and privacy:

```bash
# === Branding Variables ===
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_NAME=CommMate
BRAND_URL=https://commmate.com
WIDGET_BRAND_URL=https://commmate.com
HIDE_BRANDING=true

# === Privacy & Security ===
DISABLE_CHATWOOT_CONNECTIONS=true  # Blocks all connections to hub.2.chatwoot.com
DISABLE_TELEMETRY=true              # Disables telemetry data collection

# === Localization ===
DEFAULT_LOCALE=pt_BR                # Sets Brazilian Portuguese as default

# === Account Management ===
ENABLE_ACCOUNT_SIGNUP=false         # Disables public signups
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false  # Only super admins can create accounts

# === Email Configuration ===
MAILER_SENDER_EMAIL=CommMate <support@commmate.com>
```

### Docker Compose Configuration

**File**: `docker-compose.commmate.yaml` or production compose file

```yaml
services:
  rails:
    image: commmate/commmate:v4.8.0
    environment:
      # Branding (built into image, but can override)
      - APP_NAME=CommMate
      - BRAND_NAME=CommMate
      - INSTALLATION_NAME=CommMate
      - BRAND_URL=https://commmate.com
      - HIDE_BRANDING=true
      
      # Privacy (CRITICAL - must be set)
      - DISABLE_CHATWOOT_CONNECTIONS=true
      - DISABLE_TELEMETRY=true
      
      # Localization
      - DEFAULT_LOCALE=pt_BR
      
      # Security
      - ENABLE_ACCOUNT_SIGNUP=false
```

### Environment File (.env)

For production servers using `.env` files:

```bash
# Copy from template
cp custom/config/env.production.template .env

# Essential variables (minimum required):
INSTALLATION_NAME=CommMate
BRAND_NAME=CommMate
DISABLE_CHATWOOT_CONNECTIONS=true
DISABLE_TELEMETRY=true
DEFAULT_LOCALE=pt_BR
```

### Variable Priority (Highest to Lowest)

1. **Docker Compose** `environment:` - Overrides everything
2. **`.env` file** - Loaded by docker-compose
3. **Dockerfile ENV** - Built into image (defaults)
4. **Initializer** - Applies database configs if ENV missing
5. **Database** - InstallationConfig table (fallback)

**Best Practice**: Set in Docker Compose or .env file for production.

### Privacy Features Enabled

When `DISABLE_CHATWOOT_CONNECTIONS=true` is set:

**Blocked Connections:**
- ❌ `hub.2.chatwoot.com/ping` - Version checks
- ❌ `hub.2.chatwoot.com/register` - Instance registration  
- ❌ `hub.2.chatwoot.com/events` - Event tracking
- ❌ Push notifications to Chatwoot servers
- ❌ "Get help from Chatwoot support" widget (Super Admin pages)

**Disabled Services:**
- ❌ `Internal::CheckNewVersionsJob` - Automatic version checking
- ❌ `ChatwootHub.sync_with_hub` - Instance synchronization
- ❌ `ChatwootHub.register_instance` - Instance registration
- ❌ `ChatwootHub.send_push` - Push notification relay
- ❌ `ChatwootHub.emit_event` - Event emission
- ❌ `ChatwootHub.get_captain_settings` - Captain AI settings sync

**Implementation**: All `ChatwootHub` methods check for `DISABLE_CHATWOOT_CONNECTIONS`:

```ruby
# lib/chatwoot_hub.rb
def self.sync_with_hub
  return {} if ENV['DISABLE_CHATWOOT_CONNECTIONS'] == 'true'
  return {} if ENV['DISABLE_TELEMETRY'] == 'true'
  # ... rest of method
end
```

**Result**: Zero telemetry, complete privacy, no external dependencies.

### What Each Variable Does

| Variable | Purpose | Impact if Missing |
|----------|---------|-------------------|
| `DISABLE_CHATWOOT_CONNECTIONS` | Blocks external connections | ⚠️ Data sent to Chatwoot servers |
| `DISABLE_TELEMETRY` | Disables metrics collection | ⚠️ Usage stats sent to Chatwoot |
| `INSTALLATION_NAME` | Sets instance name | ⚠️ Shows "Chatwoot" instead of "CommMate" |
| `BRAND_NAME` | Sets brand name in emails | ⚠️ Emails say "Chatwoot" |
| `HIDE_BRANDING` | Hides "Powered by" footer | ⚠️ Shows "Powered by Chatwoot" |
| `DEFAULT_LOCALE` | Default language | ⚠️ Defaults to English instead of PT-BR |
| `ENABLE_ACCOUNT_SIGNUP` | Allows public signups | ⚠️ Anyone can create accounts |

### Verification Commands

```bash
# Check environment variables in running container
docker exec chatwoot env | grep -E 'DISABLE_CHATWOOT|TELEMETRY|BRAND_NAME|INSTALLATION'

# Expected output:
# DISABLE_CHATWOOT_CONNECTIONS=true
# DISABLE_TELEMETRY=true
# BRAND_NAME=CommMate
# INSTALLATION_NAME=CommMate

# Check database configs
docker exec chatwoot bundle exec rails runner "
  puts 'INSTALLATION_NAME: ' + GlobalConfig.get('INSTALLATION_NAME').to_s
  puts 'BRAND_NAME: ' + GlobalConfig.get('BRAND_NAME').to_s
"

# Expected output:
# INSTALLATION_NAME: {"INSTALLATION_NAME"=>"CommMate"}
# BRAND_NAME: {"BRAND_NAME"=>"CommMate"}
```

### Common Issues

**Issue**: Branding reverts to "Chatwoot" after container restart

**Cause**: Environment variables not set in docker-compose

**Solution**:
```yaml
# Add to docker-compose.yaml
services:
  chatwoot:
    environment:
      - DISABLE_CHATWOOT_CONNECTIONS=true
      - INSTALLATION_NAME=CommMate
      - BRAND_NAME=CommMate
```

**Issue**: Still connecting to Chatwoot servers

**Cause**: `DISABLE_CHATWOOT_CONNECTIONS` not set or set to "false"

**Solution**:
```bash
# Verify it's set correctly
docker exec chatwoot env | grep DISABLE_CHATWOOT_CONNECTIONS
# Must show: DISABLE_CHATWOOT_CONNECTIONS=true

# If missing, add to docker-compose and restart
docker-compose restart chatwoot sidekiq
```

---

## Related Documentation

- **Release Process**: 
  - Step 1: `DOWNSTREAM-RELEASE.md` - Create release branches
  - Step 2: `IMAGE-RELEASE.md` - Build and publish Docker images
- **Deployment & Setup**:
  - `DOCKER-SETUP.md` - Docker development setup
  - `UPGRADE.md` - Upgrade existing installations
  - `DEVELOPMENT.md` - Local development guide
- **Reference**:
  - `/docs/BRAND_COLORS.md` - Complete color palette
  - `../README.md` - Custom folder overview

