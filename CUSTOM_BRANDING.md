# Custom branding

## Brand configuration

The brand lives in the installation config, and there are two ways to set it:

- **The super admin:** **Settings → Branding** (`/super_admin/app_config?config=branding`) edits every key in the table below. What is saved there is what the installation shows, and it stays when the containers restart.
- **The environment:** set the variables on the Rails container and run `bundle exec rails branding:update`, for example in a `post_start` hook. This seeds the brand: until the Branding page is saved for the first time, the task writes every key from the environment, and an unset variable puts its key back to the default. Once the page is saved, the installation records it (`BRANDING_EDITED_IN_SUPER_ADMIN`) and the task leaves the whole brand as the page left it, so the next container start never undoes it.

```yaml
environment:
  INSTALLATION_NAME: "Chatwoot fazer.ai"
  BRAND_NAME: "My Company"
  LOGO_THUMBNAIL: "https://fazer.ai/logo-thumbnail.svg"
  LOGO: "https://fazer.ai/logo.svg"
```

To apply the environment again over the saved values, run the task once with `BRANDING_FORCE=true`. It writes every key from the environment and hands the brand back to it, until the page is saved again:

```bash
BRANDING_FORCE=true \
BRAND_NAME="My Company" \
bundle exec rails branding:update
```

### With `CW_EDITION=ee`

With Enterprise loaded, the Branding page is not offered. Enterprise runs exactly as upstream publishes it, and it owns these keys: custom branding is one of its premium features, and on an installation whose Chatwoot plan is `community` its plan reconciliation (`Internal::ReconcilePlanConfigService`) puts every key in `enterprise/config/premium_installation_config.yml` back to its default whenever a Rails process boots and once a day. The fork does not change that behavior, so on that plan a brand set through the database does not last. That includes a brand saved on the Branding page: turning Enterprise on resets it, and turning Enterprise off again does not bring it back. To restore it, save it again on the Branding page, or run `branding:update` with `BRANDING_FORCE=true`.

| Environment variable | Default Value                               | Description                                                           |
| :--------------------| :------------------------------------------ | :-------------------------------------------------------------------- |
| `INSTALLATION_NAME`  | `Chatwoot`                                  | The installation-wide name used in the dashboard, title, etc.         |
| `LOGO_THUMBNAIL`     | `/brand-assets/logo_thumbnail.svg`          | The thumbnail used for favicon (512px X 512px).                       |
| `LOGO`               | `/brand-assets/logo.svg`                    | The logo used on the dashboard, login page, etc.                      |
| `LOGO_DARK`          | `/brand-assets/logo_dark.svg`               | The logo used on the dashboard, login page, etc. for dark mode.       |
| `LOGO_EMAIL`         | _(empty)_                                   | The logo shown at the top of outgoing emails. **PNG, JPG or GIF only** — email clients do not render SVG. A relative path resolves against `FRONTEND_URL`. Left empty, `LOGO` is used when it is one of those formats, and no logo is shown otherwise. |
| `BRAND_URL`          | `https://www.chatwoot.com`                  | The URL used in emails under the section “Powered By”.                |
| `WIDGET_BRAND_URL`   | `https://www.chatwoot.com`                  | The URL used in the widget under the section “Powered By”.            |
| `BRAND_NAME`         | `Chatwoot`                                  | The name used in emails and the widget.                               |
| `BRAND_COLOR`        | `#1f93ff`                                   | The hex colour used in emails and for the PWA theme.                  |
| `TERMS_URL`          | `https://www.chatwoot.com/terms-of-service` | The terms of service URL displayed on the Signup Page.                |
| `PRIVACY_URL`        | `https://www.chatwoot.com/privacy-policy`   | The privacy policy URL displayed in the app.                          |
| `DISPLAY_MANIFEST`   | `true`                                      | Display default Chatwoot metadata like favicons and upgrade warnings. |

## Per-account branding

The configuration above is installation-wide, which is what a single-tenant install wants. An installation that hosts several companies usually wants the opposite: an account's emails should carry that account's brand, not the installation owner's.

Enable the `branded_email_templates` feature for the account, then set the brand under **Settings → General → Email branding**:

| Field         | Falls back to                                                |
| :------------ | :----------------------------------------------------------- |
| Brand name    | `BRAND_NAME`                                                 |
| Brand website | `BRAND_URL`                                                  |
| Brand color   | `BRAND_COLOR`                                                |
| Email logo    | `LOGO_EMAIL`, then `LOGO` when it is a raster format         |

The fallback is field by field, so an account that sets only a colour keeps the installation's name and logo. An account that sets nothing behaves exactly as before.

The email logo is uploaded rather than referenced by URL, and is served by this installation, so the link inside an email does not expire the way a signed storage URL would. PNG, JPG and GIF only, up to 2 MB: no mail client renders SVG.

### On the CSAT survey page

The public survey page a contact opens from a CSAT request wears the same brand, resolved from the conversation:

| Field         | Where it shows                                                            |
| :------------ | :------------------------------------------------------------------------ |
| Brand name    | The browser tab, and the "Powered by" line in the footer                  |
| Brand website | Where that footer line links                                              |
| Brand color   | The confirm and submit buttons, the selected rating, and the focus rings  |
| Email logo    | The footer mark, and the top of the page when the inbox has no avatar     |

Enable `disable_branding` on the account (a premium Chatwoot Enterprise feature, which needs a Chatwoot Enterprise license and `CW_EDITION=ee`) to drop the footer line entirely, the same way the widget and the help center portal already honour it.

> [!NOTE]
> This covers what a customer of the account sees: their email, and the public survey page. The dashboard, the login page, the favicon, the PWA manifest and the widget are the installation's own surfaces and always use the installation branding.

## Favicon and other assets

Update the favicon files in the [`public/`](public/) folder.

Can also be done by creating a zip file with relevant files, and running [`deployment/extract_brand_assets.sh`](deployment/extract_brand_assets.sh) to override the existing favicons with your own.
In this case, the zip file should be a flat archive containing the following files:

```
android-icon-36x36.png
android-icon-48x48.png
android-icon-72x72.png
android-icon-96x96.png
android-icon-144x144.png
android-icon-192x192.png
apple-icon-57x57.png
apple-icon-60x60.png
apple-icon-72x72.png
apple-icon-76x76.png
apple-icon-114x114.png
apple-icon-120x120.png
apple-icon-144x144.png
apple-icon-152x152.png
apple-icon-180x180.png
apple-icon.png
apple-icon-precomposed.png
apple-touch-icon.png
apple-touch-icon-precomposed.png
favicon-16x16.png
favicon-32x32.png
favicon-96x96.png
favicon-512x512.png
favicon-badge-16x16.png
favicon-badge-32x32.png
favicon-badge-96x96.png
ms-icon-70x70.png
ms-icon-144x144.png
ms-icon-150x150.png
ms-icon-310x310.png
```

> [!NOTE]
> You can include other assets in the zip file, and use them when running the rake task for `LOGO_THUMBNAIL`, `LOGO`, and `LOGO_DARK`.
> See [Brand configuration](#brand-configuration).
