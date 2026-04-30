# djc-chat Branding Guide

How to rebrand Chatwoot → djc-chat. Split into **runtime (no rebuild)** and **bake-in (rebuild image)**.

---

## 1. Runtime branding — env vars only (fastest path)

Set these in `deploy/.env` and restart containers — no image rebuild needed.

```bash
# Identity
INSTALLATION_NAME=djc-chat
BRAND_NAME=djc-chat

# Asset paths (relative to public/, can be overridden)
LOGO=/brand-assets/logo.svg
LOGO_DARK=/brand-assets/logo_dark.svg
LOGO_THUMBNAIL=/brand-assets/logo_thumbnail.svg

# Marketing URLs
WIDGET_BRAND_URL=https://djc.ai
TERMS_URL=https://djc.ai/terms
PRIVACY_URL=https://djc.ai/privacy
```

Defaults live in [config/installation_config.yml](../config/installation_config.yml) (lines 17–42). Premium overrides at [enterprise/config/premium_installation_config.yml](../enterprise/config/premium_installation_config.yml) (lines 2–15).

These env vars cover: page titles, email "from" labels, mailer headers, dashboard top-bar text, widget brand line.

Apply on the droplet:

```bash
cd /opt/djc-chat
nano .env       # add the vars above
docker compose up -d --force-recreate rails sidekiq
```

---

## 2. Logo swap — runtime via volume mount (no rebuild)

The image ships with stock Chatwoot SVGs at `/app/public/brand-assets/`. Override them by mounting a folder over that path.

### Steps

1. **Drop your logos** into `/opt/djc-chat/branding/` on the droplet:
   - `logo.svg` — full color logo (used in dashboard header)
   - `logo_dark.svg` — version for dark backgrounds
   - `logo_thumbnail.svg` — small icon (square aspect ratio)

2. **Edit [deploy/docker-compose.yaml](../deploy/docker-compose.yaml)** — add a bind mount under the `base` service's `volumes:`:

   ```yaml
   volumes:
     - storage_data:/app/storage
     - ./branding:/app/public/brand-assets:ro
   ```

3. Restart:

   ```bash
   docker compose up -d --force-recreate rails
   ```

This works for SVGs referenced via `LOGO`/`LOGO_DARK`/`LOGO_THUMBNAIL`. **Does NOT cover** items in section 3.

---

## 3. Bake-in branding — requires image rebuild

These assets are bundled into the JS bundle / Docker image and need a rebuild + new tag.

### Files to replace

| What | Path | Format |
|---|---|---|
| Public logo | [public/brand-assets/logo.svg](../public/brand-assets/logo.svg) | SVG |
| Public dark logo | [public/brand-assets/logo_dark.svg](../public/brand-assets/logo_dark.svg) | SVG |
| Public thumbnail | [public/brand-assets/logo_thumbnail.svg](../public/brand-assets/logo_thumbnail.svg) | SVG, square |
| Dashboard bubble | [app/javascript/dashboard/assets/images/bubble-logo.svg](../app/javascript/dashboard/assets/images/bubble-logo.svg) | SVG |
| Design system logo | [app/javascript/design-system/images/logo.png](../app/javascript/design-system/images/logo.png) | PNG |
| Design system dark | [app/javascript/design-system/images/logo-dark.png](../app/javascript/design-system/images/logo-dark.png) | PNG |
| Design system thumb | [app/javascript/design-system/images/logo-thumbnail.svg](../app/javascript/design-system/images/logo-thumbnail.svg) | SVG |
| Widget logo | [app/javascript/widget/assets/images/logo.svg](../app/javascript/widget/assets/images/logo.svg) | SVG |
| Favicon 16 | [public/favicon-16x16.png](../public/favicon-16x16.png) | PNG |
| Favicon 32 | [public/favicon-32x32.png](../public/favicon-32x32.png) | PNG |
| Favicon 96 | [public/favicon-96x96.png](../public/favicon-96x96.png) | PNG |
| Favicon 512 | [public/favicon-512x512.png](../public/favicon-512x512.png) | PNG |

### Files to edit

**[public/manifest.json](../public/manifest.json)**
- Line 2: `"name": "Chatwoot"` → `"djc-chat"`
- Line 3: `"short_name": "Chatwoot"` → `"djc-chat"`
- Line 42: `"background_color": "#1f93ff"` → your brand hex
- Update `theme_color` to match

**[theme/colors.js](../theme/colors.js)**
- Line 229: `brand: '#2781F6'` → your brand hex
- Lines 17–30: `woot` palette uses `@radix-ui/colors blue` — swap for a matching palette if the brand color is far from blue

### Rebuild flow

1. Replace assets locally on `develop`
2. Commit:
   ```bash
   git add public/brand-assets public/favicon-* public/manifest.json theme/colors.js \
           app/javascript/dashboard/assets/images/bubble-logo.svg \
           app/javascript/design-system/images app/javascript/widget/assets/images/logo.svg
   git commit -m "feat: rebrand to djc-chat"
   git push
   ```
3. Trigger workflow https://github.com/daveckw/chatwoot/actions/workflows/docker-publish.yml with tag `2`
4. On droplet: bump image tag in [deploy/docker-compose.yaml](../deploy/docker-compose.yaml) and:
   ```bash
   docker compose pull
   docker compose up -d
   ```

---

## 4. i18n strings (optional)

50+ locale files reference "Chatwoot" by name (e.g. `app/javascript/dashboard/i18n/locale/en/login.json` line 3: "Login to Chatwoot").

These are translation **values**, so swapping them only affects user-facing text and doesn't break anything. If you only support English, edit [app/javascript/dashboard/i18n/locale/en/](../app/javascript/dashboard/i18n/locale/en/). To find all references:

```bash
grep -r "Chatwoot" app/javascript/dashboard/i18n/locale/en/
```

Bulk replace across English locales:

```bash
find app/javascript/dashboard/i18n/locale/en -type f -name "*.json" \
  -exec sed -i 's/Chatwoot/djc-chat/g' {} +
```

(Review the diff before committing — some keys reference the company "Chatwoot Inc." in attribution strings you may want to keep.)

---

## 5. What I need from you to execute Phase 3

- [ ] Logo SVG (full color) — square or wide, ideally vector
- [ ] Logo SVG dark variant (white/light version for dark backgrounds)
- [ ] Square thumbnail / icon (used in chat bubbles, browser tabs)
- [ ] Brand color hex (e.g. `#2781F6`)
- [ ] Favicon source — high-res PNG (1024×1024+) or SVG; I'll generate the 4 sizes
- [ ] Confirm domain/URLs for `WIDGET_BRAND_URL`, `TERMS_URL`, `PRIVACY_URL`

Drop these in `branding-source/` (gitignored) and I'll wire everything up.
