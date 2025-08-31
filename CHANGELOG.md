# Changelog

All notable changes to WeaveSmart Chat will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Staging environment banner for clear environment identification
- Staging data reset and demo seed commands (`rake wsc:staging:reset`, `rake wsc:staging:seed`)
- Non-dismissable risk banner for WhatsApp unofficial connections
- Email notifications for WhatsApp provider changes (official/unofficial)
- UK English formatting helpers (`formatDateTimeUK`, `formatCurrencyGBP`)
- Definition of Ready/Done templates for consistent development practices
- Conventional commit validation via Husky pre-commit hooks

### Changed
- Updated PR template with comprehensive Definition of Done checklist
- Enhanced README with environment & policies implementation details
- Enforced UK English spellings across codebase (`colour` vs `color`)

### Security
- Environment variables audit completed - no hardcoded secrets found
- CSP and SRI security headers implemented and documented

## [1.0.0] - Initial WeaveSmart Chat Fork

### Added
- Initial fork of Chatwoot with WSC-specific customisations
- Weave::Core Rails engine for clean extension layer
- Feature flag system with per-tenant and per-plan controls
- API performance monitoring (p95 ≤300ms read, ≤600ms write)
- WeaveCode branding (primary #8127E8, accent #FF6600)
- Railway deployment configuration for staging and production
- Multi-stage Docker setup for optimised builds
- OpenAPI specification with TypeScript SDK generation
- UK English as default locale (en_GB)
- Performance budgets (widget ≤100KB gz, dashboard ≤200KB gz)
- 2FA scaffold for owner/admin roles
- Rate limiting per tenant/channel/module
- Structured JSON logging with tenant/trace IDs
- Prometheus metrics and Sentry error tracking
- Daily backups with weekly restore tests