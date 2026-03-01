# Branding

## Overview

AirysChat replaces all Chatwoot branding with custom brand identity. This includes colors, logos, product name, and locale strings.

## Brand Color

**Primary:** `#1BFBBD` (teal-green)

Replaces Chatwoot's default blue (`#2781F6`).

### Where it's defined

- **`theme/colors.js`** — `n.brand` property set to `'#1BFBBD'`. All Tailwind classes using `brand-*` cascade from this value.
- **`app/assets/stylesheets/_next-colors.scss`** — Full 12-step `--iris-*` CSS custom property scale for both light and dark themes, generated from the brand color.

### How colors cascade

The color system uses CSS custom properties (Radix UI pattern):
1. `theme/colors.js` defines the Tailwind config
2. `_next-colors.scss` defines the `--iris-*` scale variables
3. Tailwind classes (`text-iris-*`, `bg-iris-*`) reference these variables
4. Dark mode automatically switches to the dark theme scale

## Logos & Favicons

All logo/favicon files were replaced in:
- `app/assets/images/` — Main application logos
- `public/` — Favicons and PWA icons

## Product Name

### Installation config

`config/installation_config.yml`:
```yaml
INSTALLATION_NAME: AirysChat
BRAND_NAME: AirysChat
BRAND_URL: https://chat.airys.com.br
DEPLOYMENT_ENV: cloud
```

These values propagate through the UI via the `installationName` helper and the `replaceInstallationName` composable.

### Locale strings

All 645+ locale files across every supported language had "Chatwoot" replaced with "AirysChat":
- Backend: `config/locales/**/*.yml`
- Frontend: `app/javascript/dashboard/i18n/locale/**/*.json`
- Widget: `app/javascript/widget/i18n/locale/**/*.json`
- Shared: `app/javascript/shared/i18n/locale/**/*.json`
- Survey: `app/javascript/survey/i18n/locale/**/*.json`

### Preserved interpolation keys

The interpolation key `{latestChatwootVersion}` was **not** renamed — it's used programmatically in code (not user-facing) and must remain as-is across all locale files.

## Adding Your Own Brand

To re-brand for a different identity:

1. **Color:** Change `n.brand` in `theme/colors.js` and regenerate the iris scale in `_next-colors.scss`
2. **Logos:** Replace files in `app/assets/images/` and `public/`
3. **Name:** Update `INSTALLATION_NAME` and `BRAND_NAME` in `config/installation_config.yml`
4. **Locales:** Run a find-and-replace across all locale files:
   ```bash
   find config/locales app/javascript -name '*.yml' -o -name '*.json' | \
     xargs sed -i '' 's/AirysChat/YourBrand/g'
   ```
5. **Domain:** Set `BRAND_URL` in installation config and `FRONTEND_URL`/`APP_DOMAIN` env vars
