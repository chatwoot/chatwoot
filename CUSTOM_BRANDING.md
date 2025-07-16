# Custom branding

## Brand configuration

Export environment variables and run rake task with `bundle exec rails branding:update`.

> [!IMPORTANT]
> Unset environment variables are reset to default values.

```bash
INSTALLATION_NAME="Chatwoot fazer.ai" \
BRAND_NAME="My Company" \
LOGO_THUMBNAIL="https://fazer.ai/logo-thumbnail.svg" \
LOGO="https://fazer.ai/logo.svg" \
bundle exec rails branding:update
```

| Environment variable | Default Value                               | Description                                                           |
| :--------------------| :------------------------------------------ | :-------------------------------------------------------------------- |
| `INSTALLATION_NAME`  | `Chatwoot`                                  | The installation-wide name used in the dashboard, title, etc.         |
| `LOGO_THUMBNAIL`     | `/brand-assets/logo_thumbnail.svg`          | The thumbnail used for favicon (512px X 512px).                       |
| `LOGO`               | `/brand-assets/logo.svg`                    | The logo used on the dashboard, login page, etc.                      |
| `LOGO_DARK`          | `/brand-assets/logo_dark.svg`               | The logo used on the dashboard, login page, etc. for dark mode.       |
| `BRAND_URL`          | `https://www.chatwoot.com`                  | The URL used in emails under the section “Powered By”.                |
| `WIDGET_BRAND_URL`   | `https://www.chatwoot.com`                  | The URL used in the widget under the section “Powered By”.            |
| `BRAND_NAME`         | `Chatwoot`                                  | The name used in emails and the widget.                               |
| `TERMS_URL`          | `https://www.chatwoot.com/terms-of-service` | The terms of service URL displayed on the Signup Page.                |
| `PRIVACY_URL`        | `https://www.chatwoot.com/privacy-policy`   | The privacy policy URL displayed in the app.                          |
| `DISPLAY_MANIFEST`   | `true`                                      | Display default Chatwoot metadata like favicons and upgrade warnings. |

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
