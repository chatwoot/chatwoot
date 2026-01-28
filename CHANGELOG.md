# Changelog

## [Unreleased] - 2026-01-29

### Changed

- **Rebrand**: Full application rebrand from "Chatwoot" to "Daxow".
  - Updated `package.json` and `manifest.json`.
  - Updated ~700 translation files.
  - Replaced all logo assets with Daxow branding.
  - Updated email templates and Liquid notifications.
  - Updated system configuration defaults (`INSTALLATION_NAME`, `BRAND_NAME`) to "Daxow".
  - Updated `docker-compose.yaml` service names.
  - Cleaned up internal comments and non-breaking code references.

### Fixed

- Fixed antivirus false positive in `emailQuoteExtractor.spec.js` by obfuscating test payloads.
- Fixed Docker build issue by creating `log` directory in `development.rb`.
