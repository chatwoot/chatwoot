# EcoRay Rebrand Implementation Plan

**Status:** Ready for implementation  
**Created:** 2026-01-17  
**Target:** Full visual rebrand from Chatwoot to EcoRay  

## 🎯 Critical Requirements

✅ **MUST NOT CHANGE:**
- Authentication/account action URLs (must remain https://live.ecoray.dk)
- Frontend URL for password reset, invites, confirmations
- Any backend code identifiers, class names, or database references
- Core application functionality

✅ **MUST CHANGE:**
- Visual branding (logos, brand names in UI)
- Page titles to "EcoRay"
- "Powered by Chatwoot" references
- Email template branding and colors
- Widget branding

---

## 📋 Architecture Overview

### Current Branding System

Chatwoot uses a centralized branding configuration system:

1. **Central Config:** [`config/installation_config.yml`](config/installation_config.yml)
   - `INSTALLATION_NAME` → Dashboard titles, page titles
   - `BRAND_NAME` → Emails, widget footer
   - `BRAND_URL` → Email footer links
   - `WIDGET_BRAND_URL` → Widget footer links
   - `LOGO`, `LOGO_DARK`, `LOGO_THUMBNAIL` → Asset paths

2. **I18n Files:** Translatable "Powered by" strings
   - Widget: `app/javascript/widget/i18n/locale/en.json` (POWERED_BY key)
   - Dashboard: `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` (BRANDING_TEXT)
   - Survey: `app/javascript/survey/i18n/locale/en.json` (POWERED_BY)

3. **Components:**
   - Widget branding: [`app/javascript/shared/components/Branding.vue`](app/javascript/shared/components/Branding.vue)
   - Layout wrapper: [`app/javascript/widget/components/layouts/ViewWithHeader.vue`](app/javascript/widget/components/layouts/ViewWithHeader.vue)

4. **Email Templates:**
   - Base layout: [`app/views/layouts/mailer/base.liquid`](app/views/layouts/mailer/base.liquid)
   - Devise templates: `app/views/devise/mailer/*.html.erb`
   - Agent notifications: `app/views/mailers/agent_notifications/**/*.liquid`

---

## 📝 Implementation Tasks

### 1. Central Configuration Update

**File:** [`config/installation_config.yml`](config/installation_config.yml:17)

```yaml
# Current values → New values
INSTALLATION_NAME: 'Chatwoot' → 'EcoRay'
BRAND_NAME: 'Chatwoot' → 'EcoRay'
BRAND_URL: 'https://www.chatwoot.com' → 'https://www.ecoray.dk' (or keep live.ecoray.dk)
WIDGET_BRAND_URL: 'https://www.chatwoot.com' → 'https://www.ecoray.dk'
```

**Impact:** Changes dashboard titles, page tab names, email footers

---

### 2. Logo Assets

**Required Files** (to be created/replaced):

| File Path | Purpose | Recommended Size |
|-----------|---------|------------------|
| `public/brand-assets/logo.svg` | Dashboard logo (light mode) | Vector (current: 2458×512px) |
| `public/brand-assets/logo_dark.svg` | Dashboard logo (dark mode) | Vector (current: 2458×512px) |
| `public/brand-assets/logo_thumbnail.svg` | Favicon, widget branding | 512×512px |
| `app/javascript/widget/assets/images/logo.svg` | Widget internal logo | Vector |

**Current logo structure:**
- Blue circle background (#47A7F6)
- White chat bubble icon
- "chatwoot" text in dark color (#273444)

**Action needed:**
- Create EcoRay logo SVGs or use existing brand assets
- Maintain same dimensions for compatibility
- Update config paths if assets are renamed

---

### 3. Widget Branding Removal/Update

#### A. Update I18n Strings (English only per AGENTS.md)

**File:** [`app/javascript/widget/i18n/locale/en.json`](app/javascript/widget/i18n/locale/en.json:60)

```json
{
  "POWERED_BY": "Powered by Chatwoot" → "Powered by EcoRay"
}
```

**File:** [`app/javascript/survey/i18n/locale/en.json`](app/javascript/survey/i18n/locale/en.json:18)

```json
{
  "POWERED_BY": "Powered by Chatwoot" → "Powered by EcoRay"
}
```

#### B. Option: Hide Widget Branding Entirely

The [`Branding.vue`](app/javascript/shared/components/Branding.vue:12) component has a `disableBranding` prop. Check if there's a Super Admin setting to enable this globally via the `DISPLAY_BRANDING` feature flag mentioned in `app/helpers/super_admin/features.yml`.

**Feature Flag (line 40):**
```yaml
display_branding:
  description: 'Disable branding on live-chat widget and external emails.'
  enabled: <%= (ChatwootHub.pricing_plan != 'community') %>
```

**Decision needed:** Hide vs. Rebrand the "Powered by" footer?

---

### 4. Dashboard I18n Updates

**File:** [`app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`](app/javascript/dashboard/i18n/locale/en/inboxMgmt.json:1024)

```json
{
  "BRANDING_TEXT": "Powered by Chatwoot" → "Powered by EcoRay"
}
```

This appears in the admin UI when configuring widget settings.

---

### 5. Email Template Branding

#### A. Base Email Layout

**File:** [`app/views/layouts/mailer/base.liquid`](app/views/layouts/mailer/base.liquid:66)

**Current styling:**
- Top border color: `#0080f8` (Chatwoot blue)
- Footer text color: `#93AFC8`

**Changes needed:**

```html
<!-- Line 66: Update border color to EcoRay brand color -->
<table class="main" ... style="border-top:3px solid #YOUR_ECORAY_COLOR;" ...>

<!-- Lines 79-86: Footer powered-by section -->
<!-- Already uses global_config['BRAND_NAME'] and global_config['BRAND_URL'] -->
<!-- Will automatically update when installation_config.yml changes -->
```

**Optional:** Replace hardcoded color `#0080f8` with your EcoRay primary color.

#### B. Devise Templates (Auth Emails)

**Files to check for hardcoded "Chatwoot" references:**
- [`app/views/devise/mailer/reset_password_instructions.html.erb`](app/views/devise/mailer/reset_password_instructions.html.erb)
- `app/views/devise/mailer/confirmation_instructions.html.erb`
- `app/views/devise/mailer/password_change.html.erb`

**Current reset password template:**
```html
<p>Hello <%= @resource.email %>!</p>
<p>Someone has requested a link to change your password...</p>
<p><%= link_to 'Change my password', frontend_url('auth/password/edit', reset_password_token: @token) %></p>
```

**Note:** Uses `frontend_url()` helper which already points to your FRONTEND_URL env var (https://live.ecoray.dk). ✅ No change needed for URLs.

**Action:** Check templates for any hardcoded "Chatwoot" brand mentions in body copy.

#### C. Danish Email Translations

**File:** [`config/locales/devise.da.yml`](config/locales/devise.da.yml)

Already exists with Danish translations for:
- Password reset subjects/messages
- Confirmation instructions
- Account locked/unlocked messages

**Check needed:** Ensure no "Chatwoot" hardcoded in subject lines.

**Subjects to verify (lines 19-26):**
```yaml
confirmation_instructions:
  subject: "Bekræftelsesinstruktioner"
reset_password_instructions:
  subject: "Nulstil adgangskodeinstruktioner"
password_change:
  subject: "Adgangskode Ændret"
```

These look generic and fine ✅

---

### 6. Widget Danish Translations

**File:** [`app/javascript/widget/i18n/locale/da.json`](app/javascript/widget/i18n/locale/da.json)

**Current line 60:**
```json
"POWERED_BY": "Drevet af Chatwoot"
```

**Change to:**
```json
"POWERED_BY": "" 
```
OR
```json
"POWERED_BY": "Drevet af EcoRay"
```

**Recommendation:** Based on the task requirement for "professional Danish widget", suggest either:
1. Empty string (hide branding)
2. "Leveret af EcoRay" (Powered by EcoRay)

**Additional Danish improvements needed:**

The current Danish translation has several English fallbacks. Update these for professional appearance:

```json
// Line 17: NOT_AVAILABLE
"NOT_AVAILABLE": "Not available" → "Ikke tilgængelig"

// Line 23: BACK_AS_SOON_AS_POSSIBLE
"BACK_AS_SOON_AS_POSSIBLE": "We will be back as soon as possible" → "Vi vender tilbage hurtigst muligt"

// Lines 29-34: REPLY_TIME messages (several still in English)
"BACK_IN_HOURS": "We will be back online in {n} hour | We will be back online in {n} hours" 
→ "Vi er tilbage om {n} time | Vi er tilbage om {n} timer"

"BACK_IN_MINUTES": "We will be back online in {time} minutes"
→ "Vi er tilbage om {time} minutter"

"BACK_AT_TIME": "We will be back online at {time}"
→ "Vi er tilbage kl. {time}"

"BACK_ON_DAY": "We will be back online on {day}"
→ "Vi er tilbage {day}"

"BACK_TOMORROW": "We will be back online tomorrow"
→ "Vi er tilbage i morgen"

"BACK_IN_SOME_TIME": "We will be back online in some time"
→ "Vi er tilbage om et øjeblik"
```

---

### 7. Favicon Update

**Files:** Standard favicon files in `public/` directory

The app uses multiple favicon sizes (referenced in [`app/views/layouts/vueapp.html.erb`](app/views/layouts/vueapp.html.erb:25)):

```
/favicon-32x32.png
/favicon-96x96.png
/favicon-16x16.png
/favicon-badge-*.png (for notification badges)
/android-icon-192x192.png
/apple-icon-*.png (various sizes)
/ms-icon-144x144.png
```

**Action needed:**
1. Create EcoRay favicon at various sizes
2. Replace all favicon PNG files
3. Update `/manifest.json` if needed (for PWA configuration)

---

### 8. Page Title Updates

**Primary file:** [`app/views/layouts/vueapp.html.erb`](app/views/layouts/vueapp.html.erb:4)

```erb
<title>
  <%= @global_config['INSTALLATION_NAME'] %>
</title>
```

**Impact:** Already uses config, will update automatically ✅

**Also check:**
- [`app/views/super_admin/devise/sessions/new.html.erb`](app/views/super_admin/devise/sessions/new.html.erb:4): `<title>SuperAdmin | Chatwoot</title>` → `SuperAdmin | EcoRay`
- [`app/views/installation/onboarding/index.html.erb`](app/views/installation/onboarding/index.html.erb:4): Same change needed

---

## 🔍 Verification Checklist

After implementation, verify:

- [ ] Dashboard page title shows "EcoRay"
- [ ] Widget footer shows correct branding (or hidden)
- [ ] Email templates show "Powered by EcoRay" (or hidden)
- [ ] Email top border color matches EcoRay brand
- [ ] Password reset emails point to https://live.ecoray.dk ✅
- [ ] Invite emails point to https://live.ecoray.dk ✅
- [ ] Confirmation emails point to https://live.ecoray.dk ✅
- [ ] Widget strings are in Danish
- [ ] No "Chatwoot" visible in UI (except code/logs)
- [ ] Favicon displays EcoRay logo
- [ ] Logo appears correctly in light/dark mode

---

## 📦 Files to Change Summary

### Configuration (1 file)
- `config/installation_config.yml` - Update INSTALLATION_NAME, BRAND_NAME, URLs

### Assets (4-8 files depending on approach)
- `public/brand-assets/logo.svg` - Dashboard logo (light)
- `public/brand-assets/logo_dark.svg` - Dashboard logo (dark)
- `public/brand-assets/logo_thumbnail.svg` - Favicon source
- `app/javascript/widget/assets/images/logo.svg` - Widget logo
- `public/favicon-*.png` (multiple) - Generated favicons at various sizes
- `public/android-icon-*.png` (optional)
- `public/apple-icon-*.png` (optional)

### I18n Files (4 files - English only per AGENTS.md)
- `app/javascript/widget/i18n/locale/en.json` - Widget POWERED_BY
- `app/javascript/widget/i18n/locale/da.json` - Widget Danish (professional improvements)
- `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` - Dashboard BRANDING_TEXT
- `app/javascript/survey/i18n/locale/en.json` - Survey POWERED_BY

### Email Templates (1-2 files)
- `app/views/layouts/mailer/base.liquid` - Update border color (line 66)
- Check: `app/views/devise/mailer/*.html.erb` for hardcoded "Chatwoot" mentions

### Page Titles (2 files)
- `app/views/super_admin/devise/sessions/new.html.erb` - SuperAdmin title
- `app/views/installation/onboarding/index.html.erb` - Onboarding title

### Total: ~15-20 files

---

## 🚀 Implementation Order

1. **Prepare assets** - Create/obtain EcoRay logos and favicons
2. **Update central config** - `installation_config.yml` (affects everything downstream)
3. **Update I18n files** - Widget and dashboard English strings
4. **Improve Danish translations** - Professional widget experience
5. **Update email templates** - Branding colors and verify no hardcoded references
6. **Update static titles** - SuperAdmin and onboarding pages
7. **Replace favicon files** - All sizes
8. **Test thoroughly** - Send test emails, check widget, verify auth flows

---

## 💡 Optional Enhancements

### Hide Branding Completely

If you want to remove "Powered by" entirely instead of rebranding:

**Option 1: Use existing feature flag**
Check if `DISPLAY_BRANDING` can be set to false in Super Admin settings.

**Option 2: Set empty strings**
```json
"POWERED_BY": ""
```

**Option 3: Set BRAND_NAME to empty**
```yaml
BRAND_NAME: ''
```

This will hide the footer in [`Branding.vue`](app/javascript/shared/components/Branding.vue:56) due to condition:
```vue
<div v-if="globalConfig.brandName && !disableBranding">
```

### Email Signature

Consider adding custom email signature/footer beyond just "Powered by":
- Support contact info
- Company address
- Unsubscribe link (for marketing emails)

---

## ⚠️ Important Notes

1. **Only update `en.json` and `en.yml`** per AGENTS.md - Community handles other languages
2. **Exception: Danish** is your primary market, so professional Danish is justified
3. **URLs are safe** - All auth flows use `frontend_url()` helper with your ENV var
4. **Test email sending** - Ensure Resend integration still works after template changes
5. **Clear browser cache** - After favicon changes
6. **Rebuild assets** - Run `pnpm build` or `pnpm dev` to recompile JavaScript

---

## 🎨 Brand Color Reference

**Current Chatwoot Colors:**
- Primary blue: `#0080f8` (email border)
- Logo blue: `#47A7F6` (circle background)
- Dark text: `#273444` (logo text)

**EcoRay Colors:** (Update as needed)
- Primary: `#YOUR_COLOR_HERE`
- Secondary: `#YOUR_COLOR_HERE`
- Logo colors: TBD

---

## 📞 Next Steps

1. **Review this plan** - Confirm approach and scope
2. **Prepare assets** - Get EcoRay logos in required formats
3. **Decision: Hide or rebrand** "Powered by" footer?
4. **Confirm brand colors** for email templates
5. **Ready to implement?** → Switch to Code mode

---

**Last Updated:** 2026-01-17  
**Prepared by:** Architect Mode
