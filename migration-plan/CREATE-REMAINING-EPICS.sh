#!/bin/bash

# Navigate to epics directory
cd /home/user/chatwoot/migration-plan/epics

# Epic 08: API v1 Extended
cat > phase-3-api-layer/epic-08-api-v1-extended.md << 'EOF'
# Epic 08: API v1 Extended Endpoints

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: Medium-High
- **Dependencies**: Epic 07 (core endpoints)
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes

## Scope: ~40 Extended Controllers

### Reporting & Analytics (6)
ReportsController, DashboardController, ConversationMetricsController, AgentMetricsController, InboxMetricsController, CsatReportsController

### Integrations (6)
IntegrationsController, IntegrationsHooksController, SlackIntegrationsController, DialogflowIntegrationsController, GoogleIntegrationsController, WebhooksController

### Automation (4)
AutomationRulesController, MacrosController, CannedResponsesController, MessageTemplatesController

### Labels & Notifications (7)
LabelsController, NotificationsController, NotificationSettingsController, etc.

### Help Center (6)
PortalsController, CategoriesController, ArticlesController, etc.

### Other (11)
CustomAttributesController, AttachmentsController, NotesController, etc.

## Parallel Strategy
- Team A: Reporting, Integrations (12)
- Team B: Automation, Labels, Notifications (11)
- Team C: Help Center, Custom Attrs, Other (17)

## Estimated Time
40 controllers × 5 hours = 200 hours / 3 engineers ≈ 1.5 weeks

---
**Status**: 🟡 Ready (after Epic 07)
EOF

# Epic 09: API v2
cat > phase-3-api-layer/epic-09-api-v2.md << 'EOF'
# Epic 09: API v2 Endpoints

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (independent from v1)

## Scope: ~30 API v2 Controllers

All v2 endpoints with newer patterns and response formats.

## Key Differences from v1
- Different response format
- More RESTful patterns
- Better error handling
- Improved pagination

## Parallel Strategy
- Team A: Core v2 endpoints (15)
- Team B: Extended v2 endpoints (15)

## Estimated Time
30 controllers × 5 hours = 150 hours / 2.5 engineers ≈ 1.5 weeks

---
**Status**: 🟡 Ready (after Epic 03-06)
EOF

# Epic 10: Public API & Webhooks
cat > phase-3-api-layer/epic-10-public-api-webhooks.md << 'EOF'
# Epic 10: Public API & Webhooks

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes

## Scope: ~35 Controllers

### Public API (15)
External-facing API endpoints (no auth required or API key auth)

### Webhook Receivers (20)
- Facebook webhooks
- Instagram webhooks
- WhatsApp webhooks
- Slack webhooks
- Telegram webhooks
- Line webhooks
- Twitter webhooks
- Twilio webhooks
- Stripe webhooks
- Shopify webhooks
- + 10 more

### Platform API
Platform app endpoints

### Widget Controllers
Widget API endpoints

## Parallel Strategy
- Team A: Public API (15)
- Team B: Webhook receivers (20)

## Critical: Webhook Security
- Signature verification for all webhooks
- Replay attack prevention
- Rate limiting

## Estimated Time
35 controllers × 5 hours = 175 hours / 2.5 engineers ≈ 1.5 weeks

---
**Status**: 🟡 Ready (after Epic 03-06)
EOF

# Epic 11: Authentication & Authorization
cat > phase-4-auth-jobs/epic-11-authentication.md << 'EOF'
# Epic 11: Authentication & Authorization

## Overview
- **Duration**: 2 weeks
- **Complexity**: Very High (security-critical)
- **Dependencies**: Epic 03 (User model), Epic 07 (Auth controllers)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: No (must be done carefully)

## Scope: 15 Tasks

### JWT Implementation (4 tasks)
1. Token generation (access + refresh)
2. Token validation middleware
3. Token refresh endpoint
4. Token revocation

### Password Management (3 tasks)
1. Bcrypt hashing (12 rounds minimum)
2. Password reset flow
3. Password strength validation

### Two-Factor Authentication (3 tasks)
1. TOTP implementation
2. QR code generation
3. Backup codes

### OAuth (2 tasks)
1. Google OAuth2 integration
2. Microsoft OAuth2 integration

### SAML (1 task)
1. SAML authentication support

### Authorization (2 tasks)
1. Policy system (Pundit → CASL or custom)
2. Role-based access control (RBAC)

## Critical Security Requirements

### Password Security
- Bcrypt with 12+ rounds
- No plain text passwords ever
- Password history (prevent reuse)
- Secure password reset tokens

### JWT Security
- Short-lived access tokens (15 min)
- Long-lived refresh tokens (7 days)
- Secure token storage
- Token rotation on refresh
- Revocation support

### Session Security
- HttpOnly cookies
- Secure flag in production
- SameSite=Strict
- CSRF protection

### Rate Limiting
- Login attempts (5 per minute)
- Password reset (3 per hour)
- 2FA attempts (5 per minute)

## Testing Requirements
- ✅ 100% test coverage (no exceptions)
- ✅ Security audit
- ✅ Penetration testing
- ✅ OAuth flow validation
- ✅ 2FA flow validation

## Estimated Time
15 tasks × 6-8 hours = 100 hours / 2 engineers ≈ 2 weeks

## Risk: 🔴 VERY HIGH
Security-critical, must be perfect

---
**Status**: 🟡 Ready (after Epic 03, 07)
EOF

# Epic 12-13: Background Jobs
cat > phase-4-auth-jobs/epic-12-jobs-part1.md << 'EOF'
# Epic 12: Background Jobs - Part 1

## Overview
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes

## Scope: ~35 Jobs (User-Facing)

### Notification Jobs (10)
SendEmailNotificationJob, SendPushNotificationJob, SendSmsNotificationJob, SendWebhookNotificationJob, + 6 more

### Campaign Jobs (6)
ProcessCampaignJob, SendCampaignMessageJob, etc.

### Account Jobs (5)
CreateAccountJob, DeleteAccountJob, ExportAccountDataJob, etc.

### Agent Jobs (3)
UpdateAgentAvailabilityJob, etc.

### Contact Jobs (8)
ImportContactsJob, ExportContactsJob, MergeContactsJob, etc.

### Conversation Jobs (3)
AutoResolveConversationJob, etc.

## Parallel Strategy
- Team A: Notification, Campaign (16)
- Team B: Account, Agent (8)
- Team C: Contact, Conversation (11)

## BullMQ Setup
- Queue configuration
- Job priorities
- Retry logic
- Error handling
- Job monitoring

## Estimated Time
35 jobs × 2-3 hours = 90 hours / 3 engineers ≈ 1 week

---
**Status**: 🟡 Ready (after Epic 03-06)
EOF

cat > phase-4-auth-jobs/epic-13-jobs-part2.md << 'EOF'
# Epic 13: Background Jobs - Part 2

## Overview
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes

## Scope: ~34 Jobs (System-Level)

### Channel Jobs (12)
SyncFacebookMessagesJob, SyncInstagramMessagesJob, SyncWhatsAppMessagesJob, etc.

### Webhook Jobs (6)
DeliverWebhookJob, RetryWebhookJob, etc.

### CRM Jobs (4)
SyncCrmContactsJob, etc.

### Inbox Jobs (3)
ProcessInboxJob, etc.

### Migration Jobs (2)
MigrateDataJob, BackfillDataJob

### Internal Jobs (7)
CleanupOldDataJob, GenerateReportsJob, ProcessAnalyticsJob, UpdateCacheJob, etc.

## Parallel Strategy
- Team A: Channel, Webhook (18)
- Team B: CRM, Inbox, Migration (9)
- Team C: Internal (7)

## Estimated Time
34 jobs × 2-3 hours = 85 hours / 3 engineers ≈ 1 week

---
**Status**: 🟡 Ready (after Epic 03-06)
EOF

echo "Created Epics 08-13"

