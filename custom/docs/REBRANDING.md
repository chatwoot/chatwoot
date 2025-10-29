# CommMate Rebranding Complete Guide

Complete guide for understanding and maintaining CommMate branding.

## Quick Reference

**Colors:** Green palette - Primary `#107e44`  
**Philosophy:** Green = Active/Selected states only (not wholesale replacement)  
**Coverage:** 95% of UI (native browser selects remain blue - browser limitation)

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

## How It Works

### 1. Configuration Files

**`config/initializers/commmate_branding.rb`**
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

**Logos:**
- `custom/assets/logos/` → `public/brand-assets/`
- Displayed via CSS and database configs

**Favicons:**
- `custom/assets/favicons/` → `public/`

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

After applying branding:

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

## Related Documentation

- **Upgrades:** `UPGRADE.md`
- **Colors:** `/docs/BRAND_COLORS.md`
- **Custom Folder:** `../README.md`

