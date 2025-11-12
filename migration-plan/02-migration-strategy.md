# Migration Strategy - Rails to TypeScript (v2.0)

**Version**: 2.0
**Date**: 2025-11-12
**Change**: Restructured from 11 → 22 epics for better manageability

---

## Strategic Approach

### Chosen Strategy: Fine-Grained Incremental Migration with Dual-Running

Given Chatwoot's complexity (684 Ruby files, 58 models, 145 controllers, 9+ integrations), we use a **very fine-grained epic structure** (22 epics) with **parallel execution opportunities** and **feature flagging** for gradual rollout.

### Why This Approach?

1. **Minimize Risk**: Smaller epics (1-2 weeks) reduce blast radius
2. **Enable Parallelization**: Multiple small epics can progress simultaneously
3. **Maintain Velocity**: Complete an epic every 1-2 weeks (motivating!)
4. **Easy Rollback**: Each epic is independently revertible
5. **Continuous Validation**: Tests run after each task
6. **Business Continuity**: Zero downtime during migration
7. **Better Tracking**: Clear progress visibility with 22 milestones vs 11

### Why 22 Epics (Not 11)?

**OLD PROBLEM:**
- 5 epics were 3-6 weeks long (too big!)
- Hard to track progress
- Difficult to parallelize
- High risk per epic

**NEW SOLUTION:**
- All epics are 1-2 weeks (manageable!)
- Complete an epic every 1-2 weeks
- Easy to parallelize within phases
- Lower risk per epic

---

## Epic Breakdown (22 Epics)

---

## Phase 1: Foundation (2 epics, Weeks 1-4)

### Epic 01: Infrastructure Setup
- **Duration**: 1-2 weeks
- **Complexity**: Medium
- **Dependencies**: None
- **Team Size**: 2-3 engineers
- **Can Parallelize**: No (foundation)

**Scope:**
- NestJS project creation
- TypeScript strict mode configuration
- ESLint + Prettier setup
- Database (TypeORM) connection
- Redis connection
- Logging infrastructure (Winston)
- Error handling framework
- CORS configuration
- Health check endpoints
- Development scripts

**Tasks**: 12 tasks
**Risk**: Low
**Detailed Plan**: `epics/phase-1-foundation/epic-01-infrastructure-setup.md`

---

### Epic 02: Test Infrastructure & CI/CD
- **Duration**: 1-2 weeks
- **Complexity**: Medium
- **Dependencies**: Epic 01
- **Team Size**: 2-3 engineers
- **Can Parallelize**: No (foundation)

**Scope:**
- Vitest configuration
- Test database setup
- Factory system (FactoryBot equivalent)
- Supertest for HTTP testing
- Coverage reporting (≥90%)
- Test helpers and utilities
- CI/CD pipeline (GitHub Actions)
- Pre-commit hooks (Husky)

**Tasks**: 8 tasks
**Risk**: Low
**Detailed Plan**: `epics/phase-1-foundation/epic-02-test-infrastructure.md`

---

## Phase 2: Data Layer (4 epics, Weeks 5-8)

### Epic 03: Core Models
- **Duration**: 1 week
- **Complexity**: High
- **Dependencies**: Epic 01, Epic 02
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Partially (by model)

**Scope: 8 Core Models**
1. Account (multi-tenancy root)
2. User (authentication, roles)
3. Team (agent teams)
4. TeamMember (join table)
5. Inbox (communication channels)
6. Conversation (message threads)
7. Message (conversation messages)
8. Contact (customers)

**Why These Together**: Foundation models that everything else depends on

**Tasks**: 8 models + 8 test files + factories + migrations
**Risk**: High (data integrity critical)
**Detailed Plan**: `epics/phase-2-data-layer/epic-03-core-models.md`

---

### Epic 04: Channel Models
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03 (Inbox model)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (each channel independent)

**Scope: 9 Channel Models**
1. Channel::FacebookPage
2. Channel::Instagram
3. Channel::WhatsApp
4. Channel::Slack
5. Channel::Telegram
6. Channel::Line
7. Channel::TwitterProfile
8. Channel::TwilioSms
9. Channel::Email

**Why These Together**: All inherit from Channel base, similar structure

**Parallel Opportunities:**
- Team A: Facebook, Instagram, WhatsApp (social)
- Team B: Slack, Telegram, Line (messaging)
- Team C: Twitter, Twilio, Email (other)

**Tasks**: 9 models + 9 test files + factories + migrations
**Risk**: Medium
**Detailed Plan**: `epics/phase-2-data-layer/epic-04-channel-models.md`

---

### Epic 05: Integration Models
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03 (Account, Inbox)
- **Team Size**: 2 engineers
- **Can Parallelize**: Yes (each integration independent)

**Scope: 10 Integration Models**
1. Integrations::Hook (webhooks)
2. Integrations::Slack
3. Integrations::Dialogflow
4. Integrations::Google
5. Integrations::Shopify
6. AgentBot
7. AgentBotInbox
8. WorkingHour
9. Webhook
10. ApplicationHook

**Why These Together**: All related to third-party integrations

**Tasks**: 10 models + 10 test files + factories + migrations
**Risk**: Medium
**Detailed Plan**: `epics/phase-2-data-layer/epic-05-integration-models.md`

---

### Epic 06: Supporting Models
- **Duration**: 1 week
- **Complexity**: Low-Medium
- **Dependencies**: Epic 03-05
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes (high parallelization)

**Scope: 31 Supporting Models**

**Messaging & Content (4)**
- Attachment, Note, CannedResponse, MessageTemplate

**Automation (2)**
- AutomationRule, Macro

**Analytics & Reporting (4)**
- ReportingEvent, ConversationSummary, CsatSurvey, CsatSurveyResponse

**Help Center (4)**
- Portal, Category, Article, Folder

**Custom Fields (3)**
- CustomAttribute, CustomAttributeDefinition, CustomFilter

**Labels & Tags (2)**
- Label, ConversationLabel (join table)

**Notifications (3)**
- Notification, NotificationSetting, NotificationSubscription

**Platform & API (4)**
- Platform::App, Platform::AppKey, AccessToken, ApiKeyInbox

**Other (5)**
- Avatar, DataImport, ContactInbox (join table), InstallationConfig, etc.

**Why These Together**: Less critical, fewer dependencies, can be done in parallel

**Parallel Opportunities:**
- Team A: Messaging, Automation, Analytics (10 models)
- Team B: Help Center, Custom Fields, Labels (9 models)
- Team C: Notifications, Platform, Other (12 models)

**Tasks**: 31 models + 31 test files + factories + migrations
**Risk**: Low
**Detailed Plan**: `epics/phase-2-data-layer/epic-06-supporting-models.md`

---

## Phase 3: API Layer (4 epics, Weeks 9-14)

### Epic 07: API v1 - Core Endpoints
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 03-06 (all models)
- **Team Size**: 3-4 engineers
- **Can Parallelize**: Yes (by controller group)

**Scope: ~40 Controllers**

**Account & User Management**
- AccountsController
- UsersController
- ProfilesController
- AgentsController
- AgentBotsController

**Conversations & Messages**
- ConversationsController
- MessagesController
- ConversationLabelsController
- ConversationAssignmentController

**Contacts**
- ContactsController
- ContactLabelsController
- ContactMergeController
- ContactInboxesController

**Inboxes & Channels**
- InboxesController
- InboxMembersController
- ChannelController (base)

**Teams**
- TeamsController
- TeamMembersController

**Authentication**
- SessionsController
- PasswordsController
- ConfirmationsController

**+ ~15 more core controllers**

**Why These Together**: Core CRUD operations, most frequently used APIs

**Parallel Opportunities:**
- Team A: Account, User, Agent controllers (10)
- Team B: Conversation, Message controllers (10)
- Team C: Contact, Inbox controllers (10)
- Team D: Team, Auth controllers (10)

**Tasks**: ~40 controllers + tests + DTOs + validation
**Risk**: High (API contract must match)
**Detailed Plan**: `epics/phase-3-api-layer/epic-07-api-v1-core.md`

---

### Epic 08: API v1 - Extended Endpoints
- **Duration**: 1.5 weeks
- **Complexity**: Medium-High
- **Dependencies**: Epic 07 (core endpoints)
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes (by feature area)

**Scope: ~40 Controllers**

**Reporting & Analytics**
- ReportsController
- DashboardController
- ConversationMetricsController
- AgentMetricsController

**Integrations**
- IntegrationsController
- SlackController
- DialogflowController
- GoogleController

**Automation & Workflows**
- AutomationRulesController
- MacrosController
- CannedResponsesController

**Labels & Tags**
- LabelsController
- TagsController

**Notifications**
- NotificationsController
- NotificationSettingsController
- NotificationSubscriptionsController

**Custom Attributes**
- CustomAttributesController
- CustomFiltersController

**Help Center (Portal)**
- PortalsController
- CategoriesController
- ArticlesController

**Webhooks & Events**
- WebhooksController
- EventsController

**+ ~20 more extended controllers**

**Why These Together**: Extended features, less critical than core

**Parallel Opportunities:**
- Team A: Reporting, Analytics (10)
- Team B: Integrations, Automation (15)
- Team C: Labels, Notifications, Help Center (15)

**Tasks**: ~40 controllers + tests + DTOs
**Risk**: Medium
**Detailed Plan**: `epics/phase-3-api-layer/epic-08-api-v1-extended.md`

---

### Epic 09: API v2 Endpoints
- **Duration**: 1.5 weeks
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (independent from v1)

**Scope: ~30 Controllers**

All API v2 controllers (newer API version):
- Accounts::V2Controller
- Conversations::V2Controller
- Messages::V2Controller
- Contacts::V2Controller
- Reports::V2Controller
- + ~25 more v2 controllers

**Why Separate Epic**: v2 has different patterns, can be done in parallel with v1

**Parallel Opportunities:**
- Team A: Core v2 endpoints (15)
- Team B: Extended v2 endpoints (15)

**Tasks**: ~30 controllers + tests + DTOs
**Risk**: Medium
**Detailed Plan**: `epics/phase-3-api-layer/epic-09-api-v2.md`

---

### Epic 10: Public API & Webhooks
- **Duration**: 1.5 weeks
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (by category)

**Scope: ~35 Controllers**

**Public API (~15 controllers)**
- Public::ApiController
- Public::ContactsController
- Public::MessagesController
- Public::InboxesController
- Public::PortalsController
- + ~10 more public controllers

**Webhook Receivers (~20 controllers)**
- Webhooks::FacebookController
- Webhooks::InstagramController
- Webhooks::WhatsAppController
- Webhooks::SlackController
- Webhooks::TelegramController
- Webhooks::LineController
- Webhooks::TwitterController
- Webhooks::TwilioController
- Webhooks::StripeController
- Webhooks::ShopifyController
- + ~10 more webhook controllers

**Platform API**
- Platform::ApiController
- Platform::AppsController

**Widget Controllers**
- Widget::MessagesController
- Widget::ConversationsController

**Why These Together**: External-facing APIs, similar security requirements

**Parallel Opportunities:**
- Team A: Public API (15)
- Team B: Webhook receivers (20)

**Tasks**: ~35 controllers + tests + webhook validation
**Risk**: Medium
**Detailed Plan**: `epics/phase-3-api-layer/epic-10-public-api-webhooks.md`

---

## Phase 4: Authentication & Jobs (3 epics, Weeks 15-18)

### Epic 11: Authentication & Authorization
- **Duration**: 2 weeks
- **Complexity**: Very High
- **Dependencies**: Epic 03 (User model), Epic 07 (Auth controllers)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: No (security-critical, must be thorough)

**Scope: 15 Tasks**

**JWT Implementation**
- Token generation
- Token validation
- Token refresh
- Token revocation

**Password Management**
- Bcrypt hashing (12 rounds)
- Password reset flow
- Password strength validation

**Two-Factor Authentication**
- TOTP implementation
- QR code generation
- Backup codes

**OAuth Integrations**
- Google OAuth2
- Microsoft OAuth2

**SAML Support**
- SAML authentication
- SAML configuration

**Authorization (RBAC)**
- Policy system (Pundit → CASL or custom)
- Role-based access control
- Resource-level permissions

**Session Management**
- Session storage
- Session expiration
- Logout functionality

**Why This is One Epic**: Security-critical, needs comprehensive testing, can't be split

**Tasks**: 15 tasks + extensive security testing
**Risk**: Very High (security implications)
**Detailed Plan**: `epics/phase-4-auth-jobs/epic-11-authentication.md`

---

### Epic 12: Background Jobs - Part 1
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (by job category)

**Scope: ~35 Jobs**

**Notification Jobs (10)**
- SendEmailNotificationJob
- SendPushNotificationJob
- SendSmsNotificationJob
- SendWebhookNotificationJob
- + 6 more notification jobs

**Campaign Jobs (6)**
- ProcessCampaignJob
- SendCampaignMessageJob
- ProcessCampaignScheduleJob
- + 3 more campaign jobs

**Account Jobs (5)**
- CreateAccountJob
- DeleteAccountJob
- ExportAccountDataJob
- + 2 more account jobs

**Agent Jobs (3)**
- UpdateAgentAvailabilityJob
- ProcessAgentStatsJob
- + 1 more agent job

**Contact Jobs (8)**
- ImportContactsJob
- ExportContactsJob
- MergeContactsJob
- EnrichContactJob
- UpdateContactAvatarJob
- + 3 more contact jobs

**Conversation Jobs (3)**
- AutoResolveConversationJob
- GenerateConversationTranscriptJob
- + 1 more conversation job

**Why These Together**: User-facing jobs, higher priority

**Parallel Opportunities:**
- Team A: Notification, Campaign jobs (16)
- Team B: Account, Agent jobs (8)
- Team C: Contact, Conversation jobs (11)

**Tasks**: ~35 jobs + tests + queue configuration
**Risk**: Medium
**Detailed Plan**: `epics/phase-4-auth-jobs/epic-12-jobs-part1.md`

---

### Epic 13: Background Jobs - Part 2
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (by job category)

**Scope: ~34 Jobs**

**Channel Jobs (12)**
- SyncFacebookMessagesJob
- SyncInstagramMessagesJob
- SyncWhatsAppMessagesJob
- SyncSlackMessagesJob
- SyncTelegramMessagesJob
- + 7 more channel sync jobs

**Webhook Jobs (6)**
- DeliverWebhookJob
- RetryWebhookJob
- ProcessWebhookEventJob
- + 3 more webhook jobs

**CRM Jobs (4)**
- SyncCrmContactsJob
- PushCrmDataJob
- + 2 more CRM jobs

**Inbox Jobs (3)**
- ProcessInboxJob
- UpdateInboxStatusJob
- + 1 more inbox job

**Migration Jobs (2)**
- MigrateDataJob
- BackfillDataJob

**Internal Jobs (7)**
- CleanupOldDataJob
- GenerateReportsJob
- ProcessAnalyticsJob
- UpdateCacheJob
- + 3 more internal jobs

**Why These Together**: System-level jobs, lower priority than Part 1

**Parallel Opportunities:**
- Team A: Channel, Webhook jobs (18)
- Team B: CRM, Inbox, Migration jobs (9)
- Team C: Internal jobs (7)

**Tasks**: ~34 jobs + tests + scheduling
**Risk**: Medium
**Detailed Plan**: `epics/phase-4-auth-jobs/epic-13-jobs-part2.md`

---

## Phase 5: Integrations (5 epics, Weeks 19-24)

### Epic 14: Messaging Integrations - Part 1
- **Duration**: 2 weeks
- **Complexity**: Very High
- **Dependencies**: Epic 04 (Channel models), Epic 10 (Webhooks)
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes (each integration independent)

**Scope: 3 Complex Integrations**

**Facebook Messenger**
- API client (Graph API)
- Message sending/receiving
- Webhook handling
- Media attachments
- Message templates
- Delivery reports
- Error handling
- Rate limiting

**Instagram**
- API client (Graph API)
- Message sending/receiving
- Webhook handling
- Story replies
- Media messages
- Error handling
- Rate limiting

**WhatsApp Business API**
- API client (Business API)
- Message sending/receiving
- Webhook handling
- Template messages
- Media messages
- Interactive messages
- Delivery reports
- Error handling
- Rate limiting
- Phone number validation

**Why These Together**: Most complex integrations, Meta-based APIs

**Why 2 Weeks**: WhatsApp alone is very complex, Facebook/Instagram also substantial

**Parallel Opportunities:**
- Team A: Facebook Messenger
- Team B: Instagram
- Team C: WhatsApp

**Tasks**: 3 integrations + tests + webhook validation
**Risk**: High (third-party API dependencies)
**Detailed Plan**: `epics/phase-5-integrations/epic-14-messaging-part1.md`

---

### Epic 15: Messaging Integrations - Part 2
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 04 (Channel models), Epic 10 (Webhooks)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (each integration independent)

**Scope: 4 Integrations**

**Slack**
- API client (Web API)
- Message sending/receiving
- Webhook handling
- Thread support
- Rich message formatting
- Bot commands
- Error handling
- Rate limiting

**Telegram**
- API client (Bot API)
- Message sending/receiving
- Webhook handling
- Inline keyboards
- Media messages
- Bot commands
- Error handling
- Rate limiting

**Line**
- API client (Messaging API)
- Message sending/receiving
- Webhook handling
- Rich messages
- Template messages
- Error handling
- Rate limiting

**Twitter/X**
- API client (v2 API)
- Tweet monitoring
- Direct messages
- Mention tracking
- Webhook handling
- Error handling
- Rate limiting

**Why These Together**: Medium complexity, similar patterns

**Parallel Opportunities:**
- Team A: Slack, Telegram
- Team B: Line, Twitter

**Tasks**: 4 integrations + tests + webhook validation
**Risk**: Medium
**Detailed Plan**: `epics/phase-5-integrations/epic-15-messaging-part2.md`

---

### Epic 16: Communication Integrations
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 04 (Channel models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (2 independent integrations)

**Scope: 2 Complex Integrations**

**Twilio (SMS)**
- API client (REST API)
- SMS sending/receiving
- Webhook handling (inbound messages)
- MMS support
- Delivery reports
- Number validation
- Error handling
- Rate limiting

**Email (SMTP/IMAP)**
- **Outbound (SMTP)**
  - SMTP client
  - Email sending
  - Template rendering
  - Attachment handling
  - OAuth2 SMTP (Gmail)
  - Bounce handling

- **Inbound (IMAP)**
  - IMAP client
  - Email fetching
  - Email parsing
  - Reply detection
  - Thread tracking
  - Attachment extraction
  - Spam filtering

**Why These Together**: Both are communication channels, different protocols

**Why 1.5 Weeks**: Email is complex (SMTP + IMAP), Twilio is medium

**Parallel Opportunities:**
- Team A: Twilio
- Team B: Email (SMTP + IMAP)

**Tasks**: 2 integrations + tests + email parsing
**Risk**: High (email is complex)
**Detailed Plan**: `epics/phase-5-integrations/epic-16-communication.md`

---

### Epic 17: Business Integrations
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2 engineers
- **Can Parallelize**: Yes (2 independent integrations)

**Scope: 2 Integrations**

**Stripe (Payments)**
- API client
- Customer creation
- Subscription management
- Payment processing
- Webhook handling (payment events)
- Invoice generation
- Refund processing
- Error handling

**Shopify (E-commerce)**
- API client (REST Admin API)
- Order synchronization
- Customer synchronization
- Product data fetching
- Webhook handling (order events)
- OAuth authentication
- Error handling
- Rate limiting

**Why These Together**: Business-critical integrations, similar complexity

**Parallel Opportunities:**
- Team A: Stripe
- Team B: Shopify

**Tasks**: 2 integrations + tests + webhook validation
**Risk**: High (payment processing is critical)
**Detailed Plan**: `epics/phase-5-integrations/epic-17-business.md`

---

### Epic 18: AI/ML Integrations
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 03-06 (models)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (by integration)

**Scope: 3 AI/ML Integrations**

**Dialogflow (Google)**
- API client (Dialogflow v2)
- Intent detection
- Entity extraction
- Context management
- Session handling
- Agent training
- Webhook integration
- Error handling

**OpenAI (GPT)**
- API client
- Completion API
- Chat API
- Response generation
- Content summarization
- Prompt engineering
- Token management
- Error handling
- Rate limiting
- Cost tracking

**Vector Search (pgvector)**
- Vector embeddings generation
- Similarity search
- Document indexing
- Semantic search
- Neighbor queries
- Performance optimization

**Plus: Agent Bots**
- Agent bot framework
- Response generation
- Context awareness
- Handoff logic

**Why These Together**: AI/ML features, similar patterns

**Parallel Opportunities:**
- Team A: Dialogflow
- Team B: OpenAI + Vector Search
- Team C: Agent bots

**Tasks**: 3 integrations + agent bots + tests
**Risk**: Medium (external API dependencies)
**Detailed Plan**: `epics/phase-5-integrations/epic-18-ai-ml.md`

---

## Phase 6: Real-time & Frontend (3 epics, Weeks 25-28)

### Epic 19: Real-time WebSocket Infrastructure
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 03-06 (models), Epic 07-08 (API)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: No (shared infrastructure)

**Scope: 10 Tasks**

**WebSocket Server**
- Socket.io server setup
- Connection management
- Authentication (JWT)
- Connection pool

**Rooms & Channels**
- Room management
- Channel subscriptions
- Broadcasting
- Private channels

**Presence Tracking**
- User online/offline status
- Typing indicators
- Agent availability

**Event System**
- Event emitters
- Event listeners (12 listeners from Rails)
- Event dispatchers
- Redis pub/sub integration

**Real-time Updates**
- Live message updates
- Conversation updates
- Notification broadcasts
- Inbox updates

**Performance**
- Connection pooling
- Load balancing
- Horizontal scaling
- Connection recovery

**Why This is One Epic**: Shared infrastructure, can't be easily split

**Tasks**: 10 tasks + load testing
**Risk**: High (state management, concurrency)
**Detailed Plan**: `epics/phase-6-realtime-frontend/epic-19-realtime-websocket.md`

---

### Epic 20: Frontend API Client Adaptation
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 07-10 (API endpoints)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (by module)

**Scope: API Client Updates**

**Update Axios Clients**
- Dashboard API client
- Widget API client
- Portal API client
- Survey API client

**Authentication Flows**
- Login flow
- Token refresh
- Logout flow
- Session management

**Request/Response Handling**
- Request interceptors
- Response interceptors
- Error handling
- Retry logic

**API Endpoints**
- Update all API endpoint URLs (if changed)
- Update request/response formats
- Update validation

**State Management**
- Update Vuex stores (if needed)
- Update API service modules

**Why Separate from WebSocket**: Can be done independently

**Parallel Opportunities:**
- Team A: Dashboard + Widget
- Team B: Portal + Survey
- Team C: Auth flows + Error handling

**Tasks**: Update 4 API clients + auth + error handling
**Risk**: Medium
**Detailed Plan**: `epics/phase-6-realtime-frontend/epic-20-frontend-api-client.md`

---

### Epic 21: Frontend WebSocket Client Adaptation
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 19 (WebSocket server)
- **Team Size**: 2 engineers
- **Can Parallelize**: Yes (by module)

**Scope: WebSocket Client Migration**

**ActionCable → Socket.io Client**
- Replace ActionCable client
- Socket.io client setup
- Connection management
- Reconnection logic

**Room/Channel Subscriptions**
- Update room subscriptions
- Update channel subscriptions
- Update event handlers

**Event Handlers**
- Message received
- Conversation updated
- Notification received
- Presence updated
- Typing indicator

**State Management**
- Update Vuex actions for real-time events
- Update component reactivity

**Testing**
- Connection testing
- Event testing
- Reconnection testing

**Why Separate from API Client**: Different patterns, can be done independently

**Parallel Opportunities:**
- Team A: Dashboard WebSocket
- Team B: Widget WebSocket

**Tasks**: Migrate ActionCable → Socket.io + tests
**Risk**: Medium
**Detailed Plan**: `epics/phase-6-realtime-frontend/epic-21-frontend-websocket.md`

---

## Phase 7: Deployment (1 epic, Weeks 29-30)

### Epic 22: Deployment & Cutover
- **Duration**: 2 weeks
- **Complexity**: High
- **Dependencies**: All previous epics
- **Team Size**: Full team (all hands on deck)
- **Can Parallelize**: No

**Scope: 15 Tasks**

**Deployment Infrastructure**
- Deployment scripts
- Environment configuration
- CI/CD pipeline (production)
- Docker containers

**Database**
- Migration scripts
- Data validation
- Backup procedures

**Feature Flags**
- Feature flag setup
- Gradual rollout configuration
- A/B testing setup

**Monitoring**
- Logging setup (production)
- Metrics collection (Prometheus)
- Error tracking (Sentry)
- Performance monitoring (APM)
- Alerting

**Health Checks**
- Liveness probes
- Readiness probes
- Dependency checks

**Load Testing**
- Performance testing
- Stress testing
- Capacity planning

**Security Audit**
- Security scan
- Penetration testing
- Vulnerability assessment

**Rollback Procedures**
- Rollback scripts
- Rollback testing
- Emergency procedures

**Blue-Green Deployment**
- Setup blue-green infrastructure
- Deployment automation
- Traffic switching

**Traffic Migration**
- 0% → Internal testing
- 5% → Beta users
- 25% → Early adopters
- 50% → Half traffic
- 100% → Full cutover

**Validation**
- Smoke tests
- Integration tests
- User acceptance testing
- Performance validation

**Rails Decommission**
- Monitor TypeScript stability
- Gradual Rails shutdown
- Database cleanup
- Documentation

**Post-Launch**
- Team training
- Documentation finalization
- Lessons learned
- Retrospective

**Why This is One Epic**: Deployment is a cohesive process, can't be split

**Tasks**: 15 tasks + validation + monitoring
**Risk**: Very High (production impact)
**Detailed Plan**: `epics/phase-7-deployment/epic-22-deployment-cutover.md`

---

## Epic Dependency Matrix

| Epic | Dependencies | Can Run Parallel With |
|------|-------------|----------------------|
| 01 | None | - |
| 02 | 01 | - |
| 03 | 01, 02 | - |
| 04 | 03 | 05, 06 |
| 05 | 03 | 04, 06 |
| 06 | 03, 04, 05 | - |
| 07 | 03-06 | 08, 09, 10 |
| 08 | 03-06 | 07, 09, 10 |
| 09 | 03-06 | 07, 08, 10 |
| 10 | 03-06 | 07, 08, 09 |
| 11 | 03, 07 | - |
| 12 | 03-06 | 13 |
| 13 | 03-06 | 12 |
| 14 | 04, 10 | 15, 16, 17, 18 |
| 15 | 04, 10 | 14, 16, 17, 18 |
| 16 | 04 | 14, 15, 17, 18 |
| 17 | 03-06 | 14, 15, 16, 18 |
| 18 | 03-06 | 14, 15, 16, 17 |
| 19 | 03-08 | - |
| 20 | 07-10 | 21 |
| 21 | 19 | 20 |
| 22 | All | - |

---

## Timeline Summary

| Phase | Epics | Duration | Parallel Opportunities |
|-------|-------|----------|----------------------|
| Phase 1 | 01-02 | 2-4 weeks | Low (foundation) |
| Phase 2 | 03-06 | 4 weeks | High (split by model type) |
| Phase 3 | 07-10 | 6 weeks | High (4 epics in parallel) |
| Phase 4 | 11-13 | 4 weeks | Medium (jobs can run parallel) |
| Phase 5 | 14-18 | 6 weeks | High (5 epics in parallel) |
| Phase 6 | 19-21 | 3 weeks | Medium (2 epics can run parallel) |
| Phase 7 | 22 | 2 weeks | None (all hands on deck) |
| **Total** | **22 epics** | **27-31 weeks** | **~7 months** |

---

## Parallelization Strategy

### Phase 2: Data Layer (Week 5-8)
- **Week 5**: Epic 03 (Core Models) - Team A
- **Week 6**: Epic 04 (Channels) + Epic 05 (Integrations) - Teams A + B
- **Week 7-8**: Epic 06 (Supporting) - Teams A + B + C (high parallelization)

### Phase 3: API Layer (Week 9-14)
- **Week 9-10**: Epic 07 (v1 Core) - Team A
- **Week 9-10**: Epic 09 (v2) - Team B (parallel)
- **Week 11-12**: Epic 08 (v1 Extended) - Team A
- **Week 11-12**: Epic 10 (Public/Webhooks) - Team B (parallel)

### Phase 4: Auth & Jobs (Week 15-18)
- **Week 15-16**: Epic 11 (Auth) - Team A
- **Week 17**: Epic 12 (Jobs Part 1) - Team A + B
- **Week 18**: Epic 13 (Jobs Part 2) - Team A + B

### Phase 5: Integrations (Week 19-24)
- **Week 19-20**: Epic 14 (Messaging Part 1) - Teams A + B + C (3 integrations in parallel)
- **Week 21**: Epic 15 (Messaging Part 2) - Teams A + B (2 pairs in parallel)
- **Week 22**: Epic 16 (Communication) - Teams A + B (2 in parallel)
- **Week 23**: Epic 17 (Business) - Teams A + B (2 in parallel)
- **Week 24**: Epic 18 (AI/ML) - Teams A + B + C (3 in parallel)

### Phase 6: Real-time & Frontend (Week 25-28)
- **Week 25-26**: Epic 19 (WebSocket) - Team A
- **Week 27**: Epic 20 (Frontend API) - Team A + B
- **Week 28**: Epic 21 (Frontend WS) - Team A + B (can overlap with 20)

### Phase 7: Deployment (Week 29-30)
- **Week 29-30**: Epic 22 - Full team

---

## Risk Mitigation

### High-Risk Epics

| Epic | Risk Level | Mitigation |
|------|-----------|------------|
| Epic 11 (Auth) | 🔴 Very High | Extra testing, security audit, staged rollout |
| Epic 17 (Stripe) | 🔴 Very High | Sandbox testing, manual validation, delayed rollout |
| Epic 19 (WebSocket) | 🟡 High | Load testing, connection pool management, fallback |
| Epic 14 (WhatsApp) | 🟡 High | Per-integration feature flags, webhook replay |
| Epic 22 (Deployment) | 🔴 Very High | Blue-green, gradual rollout, instant rollback |

---

## Success Metrics (Updated)

### Code Migration
- **22 epics** completed
- **58 models** migrated
- **145 controllers** migrated
- **69 jobs** migrated
- **14 integrations** migrated
- **Test coverage** ≥90%

### Performance
- API response times ≤ Rails baseline
- Job throughput ≥ Sidekiq baseline
- WebSocket capacity ≥ ActionCable baseline

### Reliability
- Zero data loss
- Zero downtime deployment
- All integrations functional
- Error rates ≤ Rails baseline

---

## Technology Stack (Final)

### Backend
- **Framework**: NestJS
- **ORM**: TypeORM
- **Background Jobs**: BullMQ
- **WebSockets**: Socket.io
- **Validation**: class-validator
- **Testing**: Vitest + Supertest

### Frontend
- **Framework**: Vue 3 (existing)
- **WebSocket Client**: Socket.io client
- **API Client**: Axios (existing)
- **State**: Vuex (existing)

### Infrastructure
- **Database**: PostgreSQL 16
- **Cache**: Redis 7
- **Monitoring**: Sentry, Prometheus, Grafana
- **CI/CD**: GitHub Actions

---

**Strategy Status**: ✅ v2.0 Complete (22 Epics)
**Next Steps**: Create all 22 detailed epic plans
