# Discovery Findings - Chatwoot Codebase Analysis

## Executive Summary

Chatwoot is a **large-scale, enterprise-grade** customer engagement platform with:
- **684 Ruby files** (614 in app/, 70 in lib/)
- **973 Vue 3 components**
- **Complex multi-tenancy** architecture
- **9+ third-party integrations**
- **Real-time communication** features
- **AI/ML capabilities** with vector search
- **Comprehensive test suite** (618 RSpec files)

## Directory Structure Analysis

### Backend (Ruby/Rails)

```
app/
├── controllers/      145 controller classes
│   ├── api/v1/      Primary API endpoints
│   ├── api/v2/      Newer API version
│   ├── public/      Public-facing APIs
│   └── webhooks/    Webhook receivers
├── models/          58 ActiveRecord models
│   ├── channel/     Multi-channel support
│   ├── concerns/    Shared model behavior
│   └── integrations/ Third-party integrations
├── services/        140 service objects (42 categories)
│   ├── facebook/
│   ├── whatsapp/
│   ├── instagram/
│   ├── slack/
│   ├── telegram/
│   ├── twitter/
│   ├── twilio/
│   ├── google/
│   ├── microsoft/
│   └── [many more]
├── jobs/            69 background jobs
│   ├── account/
│   ├── campaigns/
│   ├── channels/
│   ├── contacts/
│   ├── conversations/
│   ├── notification/
│   └── webhooks/
├── channels/        ActionCable channels
│   └── room_channel.rb
├── listeners/       12 event listeners (Wisper pub/sub)
├── mailers/         Email notification system
├── builders/        Response builders
├── finders/         Query objects
├── presenters/      Data presentation layer
├── policies/        Pundit authorization
└── dispatchers/     Event dispatchers
```

### Frontend (Vue 3 + JavaScript)

```
app/javascript/
├── dashboard/       Main application
│   ├── api/
│   ├── components/
│   ├── components-next/ (New component library)
│   ├── store/       Vuex state management
│   ├── routes/
│   └── i18n/
├── widget/          Customer-facing chat widget
├── portal/          Help center/knowledge base
├── survey/          CSAT surveys
├── shared/          Shared utilities
└── v3/              New version components
```

### Libraries (lib/)

```
lib/
├── custom_exceptions/  Custom error classes
├── email_reply_parser/
├── integrations/
├── redis/
├── tasks/             Rake tasks
└── [70 files total]
```

## Database Schema Complexity

### Models (58 total)

**Core Models:**
- Account (multi-tenancy root)
- User
- Conversation
- Message
- Contact
- Inbox
- Team
- AgentBot

**Channel Models:**
- Channel::FacebookPage
- Channel::TwitterProfile
- Channel::TwilioSms
- Channel::Email
- Channel::WebWidget
- Channel::Api
- Channel::Telegram
- Channel::Line
- Channel::Whatsapp
- Channel::Sms

**Integration Models:**
- Integrations::Hook (webhooks)
- Integrations::Slack
- Integrations::Dialogflow
- Integrations::Google
- Integrations::Shopify

**Association Complexity:**
- 226 total associations (has_many, belongs_to, has_one)
- Polymorphic associations present
- Complex through associations
- Self-referential relationships

## Service Layer Architecture

### Service Categories (42 directories)

1. **Account Management**: Account creation, updates, deletion
2. **Auto Assignment**: Agent workload balancing
3. **Automation Rules**: Workflow automation
4. **Contacts**: Contact management, import, merge
5. **Conversations**: Thread management, assignment
6. **CRM Integrations**: LeadSquared, others
7. **Data Import**: Bulk import services
8. **Email**: SMTP/IMAP handling
9. **Geocoding**: Location from IP
10. **Labels**: Tag management
11. **Liquid Templates**: Dynamic content
12. **LLM Formatting**: AI response formatting
13. **Macros**: Quick actions
14. **Mailbox**: Email inbox processing
15. **Message Templates**: Canned responses
16. **Messages**: Message processing
17. **MFA**: Two-factor authentication
18. **Notification**: Push, email, SMS notifications
19. **Widget**: Chat widget logic
20. **Channel-specific services** (Facebook, WhatsApp, Instagram, Slack, etc.)

## Background Jobs Analysis

### Job Categories (69 jobs across 11 categories)

1. **Account Jobs**
   - Account deletion
   - Data cleanup
   - Export generation

2. **Agent Bot Jobs**
   - Bot responses
   - AI processing

3. **Campaign Jobs**
   - Campaign execution
   - Message scheduling

4. **Channel Jobs**
   - Channel synchronization
   - Status updates
   - Message fetching (Twilio, WhatsApp)

5. **Contact Jobs**
   - Contact import
   - Contact enrichment
   - Avatar processing

6. **Conversation Jobs**
   - Conversation routing
   - Auto-resolution
   - Transcript generation

7. **CRM Jobs**
   - Sync with external CRMs

8. **Inbox Jobs**
   - Inbox configuration
   - Channel updates

9. **Notification Jobs**
   - Push notifications
   - Email notifications
   - SMS notifications

10. **Webhook Jobs**
    - Webhook delivery
    - Retry logic

11. **Migration Jobs**
    - Data migrations
    - Schema updates

## Integration Ecosystem

### Communication Channels (9)

| Integration | Files | Complexity | API Version |
|------------|-------|------------|-------------|
| Facebook Messenger | 25+ | High | Graph API |
| Instagram | 20+ | High | Graph API |
| WhatsApp | 30+ | Very High | Business API |
| Slack | 15+ | Medium | Web API |
| Telegram | 10+ | Medium | Bot API |
| Line | 8+ | Medium | Messaging API |
| Twitter/X | 15+ | High | v2 API |
| Twilio | 12+ | Medium | REST API |
| Email (SMTP/IMAP) | 20+ | High | Native protocols |

### Third-Party Services (10+)

1. **Dialogflow** (Google) - AI chatbot
2. **OpenAI** - GPT integration
3. **Stripe** - Payment processing
4. **Shopify** - E-commerce integration
5. **Microsoft OAuth** - Authentication
6. **Google OAuth** - Authentication
7. **Google Cloud Storage** - File storage
8. **AWS S3** - File storage
9. **Azure Blob** - File storage
10. **LeadSquared** - CRM integration
11. **Linear** - Project management
12. **Notion** - Documentation

### Monitoring & APM (7)

- Sentry (error tracking)
- Datadog
- New Relic
- Scout APM
- Elastic APM
- PostHog (analytics)
- Web Push Notifications (FCM)

## Real-Time Features

### ActionCable Implementation

**Channels:**
- `RoomChannel` - Main communication channel
- Presence tracking
- Typing indicators
- Live updates
- Notification broadcasts

**Event Listeners (12):**
- ActionCableListener
- AgentBotListener
- AutomationRuleListener
- CampaignListener
- CsatSurveyListener
- HookListener
- InstallationWebhookListener
- NotificationListener
- ParticipationListener
- ReportingEventListener
- WebhookListener

**Pub/Sub Pattern:**
- Uses Wisper gem for event-driven architecture
- Redis for pub/sub messaging
- ActionCable for WebSocket delivery

## Authentication & Authorization

### Auth Stack

1. **Devise** - Core authentication
   - Session management
   - Password reset
   - Email confirmation
   - Account locking

2. **Devise Token Auth** - API authentication
   - JWT token generation
   - Token refresh
   - Token validation

3. **Devise Two Factor** - 2FA support
   - TOTP (Time-based OTP)
   - QR code generation

4. **Pundit** - Authorization
   - Policy objects
   - Role-based permissions
   - Resource-level access control

5. **OAuth Integrations**
   - Google OAuth2
   - Microsoft OAuth2
   - SAML

### User Roles

- SuperAdmin (platform-wide)
- Administrator (account-level)
- Agent
- Custom roles with granular permissions

## AI/ML Features

### Capabilities

1. **Vector Search**
   - pgvector extension
   - Neighbor gem for similarity
   - Document embeddings

2. **OpenAI Integration**
   - GPT completions
   - Response generation
   - Content summarization

3. **Dialogflow**
   - Intent detection
   - Entity extraction
   - Conversation flows

4. **Custom AI Agents**
   - ai-agents gem
   - LLM schema validation

## Email System

### Components

1. **Inbound Email**
   - ActionMailbox
   - IMAP fetching
   - Email parsing
   - Reply detection
   - Thread tracking

2. **Outbound Email**
   - Conversation replies
   - Notifications (agent, admin, team)
   - SMTP delivery
   - OAuth2 SMTP (Gmail)

3. **Email Templates**
   - Liquid templating
   - Internationalization
   - Dynamic content

## Test Infrastructure

### Test Suite

- **618 RSpec files**
- **36MB** of test code
- Test types:
  - Model specs
  - Controller specs
  - Request specs
  - Service specs
  - Job specs
  - Integration specs
  - System specs

### Test Tools

- RSpec (testing framework)
- FactoryBot (fixtures)
- Webmock (HTTP mocking)
- Database Cleaner
- SimpleCov (coverage)
- Test-Prof (profiling)

## Frontend Architecture

### Vue 3 Application

**Component Count:** 973 Vue files

**Architecture:**
- Vuex for state management
- Vue Router for routing
- Vite for building
- Composition API + `<script setup>`
- Tailwind CSS for styling
- i18n for internationalization

**Key Modules:**
- Dashboard (main app)
- Widget (customer chat)
- Portal (help center)
- Survey (CSAT)
- SuperAdmin pages

## Configuration & Environment

### Configuration Files

- `config/database.yml`
- `config/cable.yml` (ActionCable)
- `config/storage.yml` (ActiveStorage)
- `config/environments/` (env-specific)
- `.env` files (secrets)

### Environment Variables (50+)

- Database credentials
- Redis URLs
- API keys for integrations
- OAuth credentials
- Storage configuration
- APM tokens
- Feature flags

## Deployment Infrastructure

### Current Setup

- **Web Server**: Puma
- **Process Manager**: Foreman/Overmind
- **Background Jobs**: Sidekiq
- **Asset Pipeline**: Vite (via vite_rails)
- **Platform**: Heroku-compatible (12-factor)

### Health Checks

- Sidekiq health endpoint
- Database connectivity
- Redis connectivity
- Storage availability

## Complexity Assessment

| Area | Complexity | Reason |
|------|-----------|--------|
| Authentication | **High** | Multi-provider, 2FA, JWT, sessions |
| Multi-Channel | **Very High** | 9 channels, different APIs, webhooks |
| Real-time | **High** | ActionCable, pub/sub, presence |
| Background Jobs | **Medium** | 69 jobs, but standard patterns |
| Database | **High** | 58 models, 226 associations, polymorphic |
| Services | **High** | 140 service classes, complex business logic |
| AI/ML | **Medium** | Vector search, OpenAI, Dialogflow |
| Email | **High** | Inbound/outbound, IMAP, threading |
| Frontend | **Medium** | Vue 3 (modern), needs API adaptation |
| Testing | **High** | 618 specs to migrate, maintain coverage |

## Migration Challenges Identified

### Technical Challenges

1. **ActionCable → Socket.io/WS**
   - Different connection models
   - Presence tracking
   - Broadcasting patterns

2. **ActiveRecord → TypeORM/Prisma**
   - Association syntax
   - Query builder differences
   - Migration format

3. **Devise → Passport/JWT**
   - Session handling
   - Token management
   - 2FA integration

4. **Sidekiq → Bull/BullMQ**
   - Job interface changes
   - Scheduling syntax
   - Error handling

5. **ActiveStorage → Multer/S3**
   - File upload handling
   - Direct uploads
   - Variants/transformations

6. **ActionMailbox → Custom IMAP**
   - Email ingestion
   - Routing logic

### Business Logic Challenges

1. **Multi-Tenancy**
   - Account isolation
   - Data segregation
   - Query scoping

2. **Complex Permissions**
   - Pundit policies → Custom
   - Role hierarchies
   - Resource-level access

3. **Event-Driven Architecture**
   - Wisper → EventEmitter
   - Listener patterns
   - Async processing

4. **Integration APIs**
   - 9 channel APIs
   - Webhook handling
   - Rate limiting

### Data Migration Challenges

1. **Zero Downtime**
   - Dual-write strategy
   - Data synchronization
   - Consistency guarantees

2. **Schema Compatibility**
   - Rails conventions → TypeScript
   - Migration rollback

3. **Binary Data**
   - ActiveStorage files
   - Avatar processing

## Recommended Migration Order

Based on dependencies:

1. ✅ **Discovery & Planning** (COMPLETE)
2. ⬜ **Test Infrastructure** (enables TDD)
3. ⬜ **Database Layer** (foundation)
4. ⬜ **Authentication** (security-critical)
5. ⬜ **Core API Controllers** (business logic)
6. ⬜ **Background Jobs** (async processing)
7. ⬜ **Integrations** (external dependencies)
8. ⬜ **Real-time Features** (complex)
9. ⬜ **Frontend Adaptation** (API changes)
10. ⬜ **AI/ML Features** (advanced)
11. ⬜ **Deployment** (cutover)

## Next Steps

1. Create detailed migration strategy
2. Design epic breakdown with tasks
3. Set up TypeScript project structure
4. Implement test infrastructure
5. Begin Epic 01 execution

---

**Discovery Status**: ✅ Complete
**Confidence Level**: High
**Ready for Strategy Phase**: Yes
