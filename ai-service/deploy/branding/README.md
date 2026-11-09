# Pronto branding

Our Chatwoot runs under the name **Pronto** for internal use (DEV-Johnstocker/chatwoot#1).
The rebrand changes only Chatwoot's installation settings in the database. No
Chatwoot file is edited, so upstream updates merge as before.

Applied to production on 2026-11-09.

## Files

| File | Setting | What it is |
|---|---|---|
| `logo.svg` | `LOGO` | Wordmark, indigo `#3300AA`, for light mode |
| `logo_dark.svg` | `LOGO_DARK` | Same shape in lavender `#C9C2FF`, for dark mode |
| `logo_thumbnail.svg` | `LOGO_THUMBNAIL` | The "p" on a white rounded square: favicon and sidebar icon |
| `hide-paid-features.html` | `DASHBOARD_SCRIPTS` | Hides paid-plan features we cannot use on the free edition |
| `build_values.py` | | Builds `values.json` from the files above |
| `pronto_branding.rb` | | Backs up and applies the settings inside the Rails container |

Other settings it writes: `INSTALLATION_NAME` and `BRAND_NAME` = Pronto,
`BRAND_URL` and `WIDGET_BRAND_URL` = the site URL, and `DISPLAY_MANIFEST` = off.
`DISPLAY_MANIFEST` has to be off: when it is on, Chatwoot also lists its own
favicon PNGs, and browsers show those in the tab instead of ours. Turning it
off also removes "install as app" and the unread dot on the tab icon.

The email sender is an environment variable, not a database setting:
`MAILER_SENDER_EMAIL=Pronto <noreply@johnstockeraistudio.com>` in the Dokploy
environment. It takes effect after a redeploy.

## Apply

Production writes need the owner's go-ahead (AGENTS.md §1). Back up first.

```bash
python3 build_values.py https://pronto.johnstockeraistudio.com > values.json
# copy pronto_branding.rb and values.json into the rails container at /tmp/pronto/, then:
bundle exec rails runner /tmp/pronto/pronto_branding.rb backup /tmp/pronto/backup.json
bundle exec rails runner /tmp/pronto/pronto_branding.rb apply  /tmp/pronto/values.json
```

Keep `backup.json` outside the container (production keeps one under `/root/backups/`).

## Roll back

```bash
bundle exec rails runner /tmp/pronto/pronto_branding.rb apply /tmp/pronto/backup.json
```

The change shows at the next page load. No restart is needed.

## What it hides

`hide-paid-features.html` removes these from the dashboard and sends direct
visits back to the conversation list: Calls, SLA (report and settings),
Security (SAML), Custom roles, Captain, and the Voice and WhatsApp Call inbox
types. The server already refuses these on the free edition; this only removes
the menus and upgrade screens. Webhooks stay: ai-service depends on them.

## Not covered

- The Super Admin portal: its logo and "Chatwoot" text are fixed in Chatwoot's
  views and it does not load `DASHBOARD_SCRIPTS`.
- Built-in "Chatwoot" text in some menus and default email templates.
- Terms and privacy links (`TERMS_URL`, `PRIVACY_URL`) still point to chatwoot.com.
