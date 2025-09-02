<img src="./.github/screenshots/header.png#gh-light-mode-only" width="100%" alt="Header light mode"/>
<img src="./.github/screenshots/header-dark.png#gh-dark-mode-only" width="100%" alt="Header dark mode"/>

___

# WeaveSmart Chat (WSC) — Fork Overview

This repository is a productised fork of Chatwoot tailored for UK/EU SMEs. It preserves Chatwoot core while adding an extension layer under the Rails engine `Weave::Core` (mounted at `/wsc`). All new endpoints live under this namespace and are documented via OpenAPI with a TypeScript SDK consumed by the web app.

Stack & Standards (WSC)
- Backend: Ruby on Rails (Chatwoot base) + engine `Weave::Core`.
- Frontend: Vue 3 with Vuetify (dashboard/admin) and Anime.js for micro‑animations. Default locale: English (UK).
- Data stores: PostgreSQL; Redis for cache/queues/WebSocket.
- CI/CD: GitHub Actions. `develop` → staging; `main` → production. Release tags `vX.Y.Z` with automated changelog.
- Contracts: OpenAPI for WSC endpoints; TS SDK auto‑generated.
  - SDK generation runs on `pnpm install` and in CI; see `pnpm sdk:wsc`.
- Security/Ops: 2FA (owner/admin), CSP + SRI, per‑tenant/channel/module rate limits, structured JSON logs with `tenantId` and `traceId`, health checks, Sentry, Prometheus, daily backups with weekly restore test.
- Design system: Primary `#8127E8`, accent `#FF6600`; brand fonts; light/dark themes.
- Performance budgets: Widget ≤ 100KB gz; dashboard route bundle ≤ 200KB gz; API p95 ≤ 300ms (read) / ≤ 600ms (write) on staging data.

Feature Flags & Plans (scaffold)
- Plans: basic, pro, premium, app, custom. Plans are stored in `weave_core_account_plans` (engine).
- Feature toggles: per‑account overrides in `weave_core_feature_toggles`; defaults derived from the plan.
- API: `GET/PATCH /wsc/api/accounts/:account_id/features` (Chatwoot auth; admin required for PATCH).
- OpenAPI: `swagger/wsc/openapi.yaml`; generate TS SDK via `pnpm sdk:wsc` into `app/javascript/sdk/wsc/`.
 - Migrations: engine migrations auto‑append; run `bundle exec rails db:migrate`.
 - Admin UI (minimal): visit `/app/accounts/:accountId/settings/weave` to view/update feature toggles.

Rate Limiting (per tenant/channel/module)
- Implemented via Rack::Attack in the engine (no core edits):
  - Per‑account RPM for all account‑scoped APIs.
  - Messaging writes (conversations/messages) per account.
  - WhatsApp inbound webhooks per account (scoped via phone → channel → account).
  - Widget writes per account (scoped via `website_token`).
- Limits are plan‑based defaults (Basic/Pro/Premium/App/Custom) and can be tuned in code.
- 429 responses may be returned when thresholds are exceeded.

Structured JSON Logs
- Enabled via Lograge JSON (`LOGRAGE_ENABLED=true`).
- Payload includes `tenantId` (when available) and `traceId` (request id) for correlation.
- Sidekiq logs remain JSON-formatted; future work may add correlation fields to jobs.

2FA (owner/admin)
- Engine adds user 2FA fields and endpoints:
  - `GET /wsc/api/profile/two_factor/setup` → returns secret + otpauth URL.
  - `POST /wsc/api/profile/two_factor/enable` with `{ code }` → enables and returns backup codes.
  - `POST /wsc/api/profile/two_factor/disable` with `{ code | backup_code }`.
- Enforcement (admins): set `WSC_2FA_ENFORCE=true` to require 2FA for administrator requests to account‑scoped APIs. Non‑account routes are not enforced.

UK Formatting
- Default locale `en‑GB` in dashboard and widget. Helpers in `app/javascript/weave/format.ts`:
  - `formatDateTimeUK(date)` (DD/MM/YYYY, 24h)
  - `formatDateUK(date)`
  - `formatCurrencyGBP(amount)` (GBP £)

Contributions must use UK English, DD/MM/YYYY, 24h time, and GBP (£).

# Chatwoot

The modern customer support platform, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.

<p>
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/e6e3f66332c91e5a4c0c/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fuptime.json" alt="uptime"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fresponse-time.json" alt="response time"></a>
  <a href="https://artifacthub.io/packages/helm/chatwoot/chatwoot"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/artifact-hub" alt="Artifact HUB"></a>
</p>


<p>
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img width="150" alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
  <a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
     <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
  </a>
</p>

<img src="./.github/screenshots/dashboard.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="./.github/screenshots/dashboard-dark.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

---

Chatwoot is the modern, open-source, and self-hosted customer support platform designed to help businesses deliver exceptional customer support experience. Built for scale and flexibility, Chatwoot gives you full control over your customer data while providing powerful tools to manage conversations across channels.

### ✨ Captain – AI Agent for Support

Supercharge your support with Captain, Chatwoot’s AI agent. Captain helps automate responses, handle common queries, and reduce agent workload—ensuring customers get instant, accurate answers. With Captain, your team can focus on complex conversations while routine questions are resolved automatically. Read more about Captain [here](https://chwt.app/captain-docs).

### 💬 Omnichannel Support Desk

Chatwoot centralizes all customer conversations into one powerful inbox, no matter where your customers reach out from. It supports live chat on your website, email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS etc.

### 📚 Help center portal

Publish help articles, FAQs, and guides through the built-in Help Center Portal. Enable customers to find answers on their own, reduce repetitive queries, and keep your support team focused on more complex issues.

### 🗂️ Other features

#### Collaboration & Productivity

- Private Notes and @mentions for internal team discussions.
- Labels to organize and categorize conversations.
- Keyboard Shortcuts and a Command Bar for quick navigation.
- Canned Responses to reply faster to frequently asked questions.
- Auto-Assignment to route conversations based on agent availability.
- Multi-lingual Support to serve customers in multiple languages.
- Custom Views and Filters for better inbox organization.
- Business Hours and Auto-Responders to manage response expectations.
- Teams and Automation tools for scaling support workflows.
- Agent Capacity Management to balance workload across the team.

#### Customer Data & Segmentation
- Contact Management with profiles and interaction history.
- Contact Segments and Notes for targeted communication.
- Campaigns to proactively engage customers.
- Custom Attributes for storing additional customer data.
- Pre-Chat Forms to collect user information before starting conversations.

#### Integrations
- Slack Integration to manage conversations directly from Slack.
- Dialogflow Integration for chatbot automation.
- Dashboard Apps to embed internal tools within Chatwoot.
- Shopify Integration to view and manage customer orders right within Chatwoot.
- Use Google Translate to translate messages from your customers in realtime.
- Create and manage Linear tickets within Chatwoot.

#### Reports & Insights
- Live View of ongoing conversations for real-time monitoring.
- Conversation, Agent, Inbox, Label, and Team Reports for operational visibility.
- CSAT Reports to measure customer satisfaction.
- Downloadable Reports for offline analysis and reporting.


## Documentation

Detailed documentation is available at [chatwoot.com/help-center](https://www.chatwoot.com/help-center).

## Translation process

The translation process for Chatwoot web and mobile app is managed at [https://translate.chatwoot.com](https://translate.chatwoot.com) using Crowdin. Please read the [translation guide](https://www.chatwoot.com/docs/contributing/translating-chatwoot-to-your-language) for contributing to Chatwoot.

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`.

## Deployment

### Heroku one-click deploy

Deploying Chatwoot to Heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://www.chatwoot.com/docs/environment-variables) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables.


### DigitalOcean 1-Click Kubernetes deployment

Chatwoot now supports 1-Click deployment to DigitalOcean as a kubernetes app.

<a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
  <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
</a>

### Other deployment options

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.

## Community

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.

## Contributors

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2025, Chatwoot Inc - Released under the MIT License.
CI/CD & Ops
- Deploys: GitHub Actions deploy to Railway
  - Staging on `develop` via `.github/workflows/deploy_staging.yml` (requires secrets: `RAILWAY_TOKEN`, `RAILWAY_SERVICE_ID_STAGING`, `RAILWAY_ENV_ID_STAGING`).
  - Production on `main` via `.github/workflows/deploy_prod.yml` (requires prod equivalents).
- Releases: Automated via Release Please (`.github/workflows/release_please.yml`), generating tags `vX.Y.Z` and CHANGELOG.
- Backups: Daily `pg_dump` (`.github/workflows/db_backup.yml`) and weekly restore test (`.github/workflows/db_restore_test.yml`). Configure `DATABASE_URL` secret.
- Observability: `/wsc/metrics` exposes Prometheus text format; enable Lograge JSON for structured logs.
- CSP: Baseline CSP is available via engine (`WSC_CSP_ENABLED=true`), report‑only by default.

## Environments & Policies Implementation

Staging Environment
- Staging is clearly marked with a prominent amber banner in the UI when `Rails.env.staging?` is true
- Staging data can be reset via `rake wsc:staging:reset` command (staging environment only)
- Demo tenants are seeded via `rake wsc:staging:seed` with WeaveCode Demo Ltd, Acme Corp UK, and London SME Solutions
- Admin credentials: admin1@weavecode.demo, admin2@weavecode.demo, admin3@weavecode.demo (password: DemoPassword123!)

Environment Variables
- All secrets are managed via Railway environment variables (see .env.example for reference)
- No hardcoded secrets detected in codebase - all configuration uses ENV fetches
- Production secrets should be configured in Railway dashboard

UK English & Formatting
- Default locale set to `en_GB` across all Vue applications (dashboard, widget, admin)
- UK English compliance enforced: "colour" instead of "color" in helper functions
- Date/time formatting via `formatDateTimeUK()`, `formatDateUK()` (DD/MM/YYYY, 24h)
- Currency formatting via `formatCurrencyGBP()` with £ symbol
- All new UI text, logs, and documentation must use UK English spellings

WhatsApp Integration Policies
- Non-dismissable risk banner displays for third-party WhatsApp connections (provider != 'whatsapp_cloud')
- Banner includes link to WeaveCode FAQ about official API migration
- Automatic email notifications sent when switching between official/unofficial providers
- Official API confirmation emails sent to account administrators upon migration to whatsapp_cloud provider
- Email templates use UK English and emphasise reliability benefits of official API

## Definition of Ready / Done Implementation

Definition of Ready (DoR)
- Feature request template enforces clear scope, testable acceptance criteria, and feature flag identification
- Environment variables must be documented with defaults in .env.example
- Database migrations planned using expand/contract pattern for zero-downtime deployments
- All new features require appropriate per-tenant and per-plan feature flags

Definition of Done (DoD)
- Comprehensive PR template with code quality, testing, documentation, and release process checklists
- Performance budgets automatically enforced: widget ≤100KB gz, dashboard ≤200KB gz
- API response time SLA monitoring: p95 ≤300ms (read), ≤600ms (write)
- UK English compliance validation in commit messages and code
- Conventional commit format enforced via Husky pre-commit hooks (`feat:`, `fix:`, `chore:`, etc.)
- CHANGELOG.md automatically updated via Release Please on main branch merges

Testing Framework
- Frontend: Vitest with 316 test files, coverage reports available via `pnpm test:coverage`
- Backend: RSpec with 569 test files, run via `bundle exec rspec`
- Linting: ESLint for JavaScript/Vue, RuboCop for Ruby
- Size limits: Automated via size-limit package in CI/CD
- Git hooks prevent direct pushes to main/develop branches, enforce conventional commits

## RBAC (Role-Based Access Control)

### Overview

WeaveSmart Chat implements a comprehensive tenant-scoped RBAC system that extends Chatwoot's base functionality with granular permissions and role hierarchy. The system supports both system-defined roles and custom roles with fine-grained permission control.

### Role Hierarchy

| Role | Hierarchy Level | Description |
|------|-----------------|-------------|
| **Owner** | 150 | Full system access, including feature flag management |
| **Administrator** | 100 | Nearly full access, except feature flag management |
| **Finance** | 75 | Billing, reporting, and financial data access |
| **Agent** | 50 | Customer-facing operations and assigned conversations |
| **Support** | 25 | Limited support and knowledge base access |

### Permission Categories

#### 1. Conversations (12 permissions)
- `conversation_view_all` - View all account conversations
- `conversation_view_assigned` - View assigned conversations only  
- `conversation_view_participating` - View conversations you're participating in
- `conversation_manage_all` - Full conversation management
- `conversation_manage_assigned` - Manage only assigned conversations
- `conversation_assign` - Assign conversations to team members
- `conversation_transfer` - Transfer conversations between agents
- `conversation_resolve` - Mark conversations as resolved
- `conversation_reopen` - Reopen resolved conversations
- `conversation_private_notes` - Add private team notes
- `conversation_export` - Export conversation data

#### 2. Contacts (8 permissions)
- `contact_view` - View contact information
- `contact_create` - Create new contacts
- `contact_update` - Edit contact details
- `contact_delete` - Delete contacts
- `contact_merge` - Merge duplicate contacts
- `contact_export` - Export contact data
- `contact_import` - Import contact data
- `contact_custom_attributes` - Manage custom contact fields

#### 3. Team Management (7 permissions)
- `team_view` - View team member information
- `team_invite` - Invite new team members
- `team_manage` - Full team management capabilities
- `user_profile_update` - Update user profiles
- `role_assign` - Assign roles to team members
- `role_create` - Create custom roles
- `role_manage` - Manage existing roles

#### 4. Reporting & Analytics (6 permissions)
- `report_view` - Access basic reports
- `report_advanced` - Access advanced analytics
- `report_export` - Export report data
- `report_custom` - Create custom reports
- `analytics_view` - View analytics dashboard
- `analytics_export` - Export analytics data

#### 5. Billing (7 permissions)
- `billing_view` - View billing information
- `billing_manage` - Manage billing settings
- `invoice_view` - View invoices
- `invoice_download` - Download invoices
- `payment_methods` - Manage payment methods
- `subscription_manage` - Manage subscription plans
- `usage_view` - View usage metrics

#### 6. Settings (7 permissions)
- `settings_account` - Manage account settings
- `settings_channels` - Configure channels
- `settings_integrations` - Manage integrations
- `settings_webhooks` - Configure webhooks
- `settings_automation` - Manage automation rules
- `settings_security` - Manage security settings
- `settings_advanced` - Advanced configuration

#### 7. Knowledge Base (7 permissions)
- `kb_view` - View knowledge base content
- `kb_article_create` - Create articles
- `kb_article_edit` - Edit articles
- `kb_article_delete` - Delete articles
- `kb_category_manage` - Manage categories
- `kb_portal_manage` - Manage portals
- `kb_publish` - Publish content

#### 8. Channels (6 permissions)
- `channel_view` - View channel information
- `channel_create` - Create new channels
- `channel_configure` - Configure channels
- `channel_delete` - Delete channels
- `integration_manage` - Manage integrations
- `webhook_manage` - Manage webhooks

#### 9. System (4 permissions)
- `audit_log_view` - View audit logs
- `system_info_view` - View system information
- `feature_flags_view` - View feature flags
- `feature_flags_manage` - Manage feature flags (Owner only)

### Default Role Permissions

#### Owner (150)
- All 64 permissions including `feature_flags_manage`
- Cannot be managed by other roles
- Primary owner cannot be deleted or have role changed

#### Administrator (100)  
- All permissions except `feature_flags_manage`
- Can manage all other roles except owners
- Full system administration capabilities

#### Finance (75)
- All billing and reporting permissions
- Account settings management
- Team view access
- No conversation or customer-facing permissions

#### Agent (50)
- Assigned conversation management
- Contact viewing and updating  
- Knowledge base contribution
- Team view access
- No administrative permissions

#### Support (25)
- Limited conversation access (assigned only)
- Contact viewing
- Knowledge base contribution
- No management or administrative permissions

### Custom Roles

The system supports custom roles that can:
- Have any combination of the 64 available permissions
- Be assigned a custom hierarchy level (1-149)
- Include custom display name and colour
- Override individual user permissions (grant/revoke)

### Usage Examples

#### Backend Permission Checking
```ruby
# Using RbacService
RbacService.check_permission(account_user, 'conversation_manage_all')

# Using AccountUser model
account_user.has_permission?('billing_view')
account_user.can_manage_user?(target_user)

# Using RbacPolicy  
policy = RbacPolicy.new(account_user, conversation)
policy.manage_conversation?
```

#### Frontend Permission Guards
```javascript
// Using useRbac composable
import { useRbac } from '@/composables/useRbac'

const { hasPermission, canViewBilling, userRole } = useRbac()

// Check specific permission
if (hasPermission('team_invite')) {
  // Show invite button
}

// Check feature-specific permissions
if (canViewBilling()) {
  // Show billing menu
}

// Role-based display
const roleClass = userRole.value === 'owner' ? 'role-owner' : 'role-standard'
```

#### Custom Role Creation
```javascript
const customRole = {
  name: 'Customer Success Manager',
  description: 'Manages customer relationships and success metrics',
  role_color: '#10B981',
  role_hierarchy: 60,
  permissions: [
    'conversation_view_all',
    'conversation_manage_assigned', 
    'contact_view',
    'contact_update',
    'report_view',
    'report_advanced',
    'team_view'
  ]
}
```

### Security Features

- **Privilege Escalation Prevention**: Users cannot assign roles higher than their own hierarchy
- **Permission Override System**: Individual users can have permissions granted or revoked
- **Audit Logging**: All permission changes are logged with timestamps and context
- **Policy-based Authorization**: Centralized permission checking through RbacPolicy class
- **Frontend Guards**: UI elements hidden/shown based on user permissions

### File Structure

- **Models**: `app/models/account_user.rb`, `enterprise/app/models/custom_role.rb`
- **Policies**: `app/policies/rbac_policy.rb`
- **Services**: `app/services/rbac_service.rb`  
- **Frontend**: `app/javascript/dashboard/composables/useRbac.js`
- **UI Components**: `app/javascript/dashboard/routes/dashboard/settings/customRoles/`
- **Tests**: `spec/models/rbac_system_spec.rb`
- **Migrations**: `db/migrate/20250902130000_enhance_rbac_system.rb`

The RBAC system ensures secure, scalable permission management across all WeaveSmart Chat features while maintaining compatibility with existing Chatwoot functionality.

## WhatsApp Integration Risk Disclaimer

### ⚠️ Legal Notice: Unofficial WhatsApp Integrations

**IMPORTANT DISCLAIMER**: WeaveSmart Chat provides connectivity to both official and third-party WhatsApp services. The use of unofficial/third-party WhatsApp integrations carries significant risks and limitations:

#### Risks and Limitations

- **Service Disruption**: Third-party WhatsApp providers can be suspended, terminated, or experience outages without notice
- **Number Suspension**: WhatsApp may permanently suspend your business phone number for using unauthorised third-party services
- **Terms of Service Violations**: Third-party integrations may violate WhatsApp Business Terms of Service
- **Data Security**: Messages transmitted through third-party providers pass through non-Facebook servers
- **Feature Limitations**: Access to new WhatsApp Business features may be delayed or unavailable
- **Support Limitations**: Official WhatsApp support is not available for third-party integrations

#### Official WhatsApp Business Cloud API

WeaveCode **strongly recommends** using only the official WhatsApp Business Cloud API for:
- ✅ Direct connection to Facebook's infrastructure
- ✅ Full compliance with WhatsApp Business policies
- ✅ Guaranteed service reliability and uptime
- ✅ Access to latest features and security updates
- ✅ Official Meta/Facebook support

#### Liability Disclaimer

**WeaveCode Ltd is not responsible for:**
- Service disruptions or outages from third-party WhatsApp providers
- WhatsApp number suspensions or bans resulting from unofficial integrations
- Data loss, message delivery failures, or security breaches
- Business impact or revenue loss from third-party service issues
- Compliance violations resulting from use of unofficial integrations

**By using unofficial WhatsApp integrations, you acknowledge and accept these risks entirely at your own responsibility.**

#### Persistent Risk Warning

A non-dismissible risk warning banner will display in your dashboard when unofficial WhatsApp integrations are detected. This warning can only be removed by migrating to the official WhatsApp Business Cloud API.

#### Migration Support

For assistance migrating to official WhatsApp Business Cloud API, visit: https://weavecode.co.uk/faq/whatsapp-official-api

---

*This disclaimer was last updated: September 2025*

## Rate Limiting System

### Overview

WeaveSmart Chat implements comprehensive, tenant-scoped rate limiting to control costs, ensure system stability, and provide fair usage across all accounts. The system uses plan-based limits with admin override capabilities and provides detailed monitoring and friendly error messages.

### Rate Limit Categories

#### 1. Account-level Limits (`account_rpm`)
General API requests per account per minute across all endpoints under `/api/v1/accounts/{id}/` and `/api/v2/accounts/{id}/`

#### 2. Messaging Writes (`messaging_write_rpm`)  
Conversation and message creation/updates under `/api/v1/accounts/{id}/conversations` (POST/PATCH/PUT only)

#### 3. Widget Writes (`widget_write_rpm`)
Customer-facing widget API calls under `/api/v1/widget/messages` (scoped by `website_token`)

#### 4. WhatsApp Inbound (`whatsapp_inbound_rpm`)
Incoming WhatsApp webhook processing per phone number (mapped to account via channel lookup)

#### 5. Reports (`reports_rpm`)
Analytics and reporting endpoints under `/api/v2/accounts/{id}/reports` (GET only)

### Plan-based Rate Limits

| Plan | Account RPM | Messaging RPM | Widget RPM | WhatsApp RPM | Reports RPM |
|------|-------------|---------------|------------|--------------|-------------|
| **Basic** | 300 | 120 | 60 | 60 | 60 |
| **Pro** | 600 | 240 | 90 | 120 | 120 |  
| **Premium** | 1,200 | 480 | 120 | 240 | 240 |
| **App** | 300 | 60 | 60 | 30 | 30 |
| **Custom** | 1,200 | 480 | 120 | 240 | 240 |

### Rate Limit Features

#### Friendly Error Messages
When rate limits are exceeded, users receive contextual 429 responses with:
- Plan-specific messaging with upgrade suggestions
- Module-specific guidance (e.g., "Reports are rate-limited to maintain system performance")
- Retry-after timing (60 seconds)
- Current account limits and usage information
- Upgrade availability flags for lower-tier plans

```json
{
  "error": "Rate limit exceeded",
  "message": "You have reached your Basic plan rate limit. Consider upgrading to Pro for higher limits, or wait a minute before trying again.",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60,
  "account_limits": {
    "account_rpm": 300,
    "messaging_write_rpm": 120
  },
  "upgrade_available": true
}
```

#### Admin Override System
Super administrators can create temporary rate limit overrides for specific accounts:

**Override Properties:**
- **Category**: Which rate limit to override (account_rpm, messaging_write_rpm, etc.)
- **Override Limit**: New limit in requests per minute (1-10,000)
- **Duration**: 1 hour, 24 hours, 1 week, or 1 month
- **Reason**: Emergency, maintenance, traffic spike, customer request, testing, or other
- **Notes**: Additional context for the override
- **Auto-expiry**: Overrides automatically expire and revert to plan limits

**Admin Interface:**
- Dashboard at `/admin/rate-limits` showing all accounts and usage
- Per-account management at `/admin/rate-limits/{account_id}`
- Real-time usage monitoring with colour-coded indicators
- Active override management with immediate expiry options
- Historical override audit trail

#### Usage Monitoring
- **Real-time tracking**: Current usage per category per account
- **Percentage calculations**: Usage as percentage of current limits
- **Visual indicators**: Colour-coded usage bars (green < 70%, yellow < 90%, red ≥ 90%)
- **High usage alerts**: Identification of accounts approaching limits
- **Override impact**: Separate tracking of base vs. override limits

#### Burst Handling and Cooldown
- **Sliding window**: 1-minute rolling window for all rate limits
- **Burst tolerance**: Accounts can briefly exceed limits within the window
- **Automatic reset**: Limits fully reset every minute
- **Gradual recovery**: Partial capacity recovery as window slides
- **Concurrent safety**: Thread-safe implementation for high-concurrency scenarios

### Technical Implementation

#### Backend Components
- **Rack::Attack**: Core throttling mechanism with Redis backing
- **RateLimits Service**: Plan lookup, override management, usage tracking
- **RateLimitOverride Model**: Database storage for admin overrides with validation
- **Custom Middleware**: Enhanced 429 response formatting with context
- **Exception Handling**: Automatic throttle exception catching in controllers

#### Frontend Components
- **RateLimitNotification.vue**: User-friendly rate limit notifications
- **Admin Dashboard**: Full-featured management interface for super admins
- **Usage Indicators**: Real-time usage bars and alerts
- **Upgrade Prompts**: Contextual upgrade suggestions for eligible plans

#### Cache Strategy
- **Plan caching**: 5-minute cache for account plan lookups
- **Override caching**: 1-minute cache for active overrides (cleared on changes)
- **Usage tracking**: Real-time Redis counters with automatic cleanup
- **Performance optimisation**: Minimal database queries during rate limit checks

### Configuration and Deployment

#### Environment Variables
```bash
# Enable/disable rate limiting (production default: true)
ENABLE_RACK_ATTACK=true

# Redis connection for rate limit storage
REDIS_URL=redis://localhost:6379/0

# General Rack::Attack settings
RACK_ATTACK_LIMIT=3000  # IP-based fallback limit
RACK_ATTACK_ALLOWED_IPS="127.0.0.1,::1"  # Bypass IPs
```

#### Monitoring and Alerting
- **Structured logging**: All rate limit hits logged with account/plan context
- **Metrics exposure**: Usage statistics available via admin dashboard
- **Prometheus integration**: Rate limit metrics via `/wsc/metrics` endpoint
- **Alert thresholds**: Notification system for high usage accounts

#### Testing Strategy
- **Burst testing**: Verify limits under concurrent load
- **Cooldown verification**: Ensure proper reset behaviour  
- **Plan switching**: Test limit changes when plans are upgraded/downgraded
- **Override functionality**: Admin interface and expiry testing
- **Edge cases**: Expired overrides, missing plans, concurrent requests

### Usage Examples

#### Checking Current Limits (Ruby)
```ruby
# Get all limits for an account
limits = Weave::Core::RateLimits.current_limits_for_account(account_id)

# Get usage percentage
usage = Weave::Core::RateLimits.usage_percentage_for_account(account_id, :account_rpm)

# Create admin override
Weave::Core::RateLimits.create_override!(
  account_id,
  'messaging_write_rpm',
  500,
  1.day.from_now,
  'emergency_traffic_spike',
  admin_user.id
)
```

#### Frontend Usage Monitoring (JavaScript)
```javascript
// Check if rate limited response
if (error.response?.status === 429) {
  const data = error.response.data;
  
  // Show friendly notification
  showRateLimitNotification({
    message: data.message,
    upgradeAvailable: data.upgrade_available,
    retryAfter: data.retry_after
  });
}
```

### Performance Impact

#### Minimal Overhead
- **Average latency**: < 2ms per request for rate limit checks
- **Memory usage**: ~1KB per active account in Redis
- **Database impact**: Plan lookups cached, overrides queried only when present
- **Scaling**: Linear scaling with Redis cluster support

#### Capacity Planning
- **Redis requirements**: ~100MB RAM per 10,000 active accounts
- **Network overhead**: ~100 bytes per request for rate limit headers
- **Admin dashboard**: Efficiently paginated for large account volumes

The rate limiting system ensures fair resource allocation while maintaining excellent user experience through contextual messaging and flexible admin controls.
