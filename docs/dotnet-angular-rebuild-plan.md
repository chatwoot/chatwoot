# Chatwoot Feature Audit & .NET + Angular Rebuild Plan

## Context

Chatwoot is a full-featured open-source customer engagement platform built with Ruby on Rails (backend) and Vue.js (frontend). This plan provides a comprehensive feature inventory extracted from the codebase, organized for rebuilding the application using **.NET 8 (ASP.NET Core)** for the backend and **Angular 17+** for the frontend.

---

## 1. COMPLETE FEATURE INVENTORY

### 1.1 Channels (3 — Scoped Down)

| Channel | Source File | Description |
|---------|-----------|-------------|
| **Web Widget** | `app/models/channel/web_widget.rb` | Embeddable live chat widget for websites |
| **Email** | `app/models/channel/email.rb` | Email channel (IMAP inbound / SMTP outbound) |
| **API** | `app/models/channel/api.rb` | Custom channel via REST API (allows third-party integrations) |

### 1.2 Conversation Management

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Conversations CRUD** | `app/models/conversation.rb`, `conversations_controller.rb` | Create, view, update, resolve, reopen conversations |
| **Message Types** | `app/models/message.rb` | Incoming, outgoing, activity, template messages |
| **Attachments** | `app/models/attachment.rb` | File/image/video/audio attachments on messages |
| **Assignments** | `app/models/conversation.rb` | Assign to agents, teams, or auto-assign |
| **Labels** | `app/models/label.rb` | Tag conversations and contacts with labels |
| **Participants/Watchers** | `app/models/conversation_participant.rb` | Add participants to watch conversations |
| **Mentions** | `app/models/mention.rb` | @mention agents in conversations |
| **CSAT Surveys** | `app/models/csat_survey_response.rb` | Customer satisfaction surveys after resolution |
| **Custom Filters/Views** | `app/models/custom_filter.rb` | Save filtered conversation views |
| **Bulk Actions** | `bulk_actions_controller.rb` | Bulk assign, label, resolve, status change |
| **Conversation Actions** | `app/services/action_service.rb` | Mute, snooze, priority, typing indicators |
| **Draft Messages** | `store/modules/draftMessages.js` | Save message drafts per conversation |
| **Conversation Search** | `store/modules/conversationSearch.js` | Search within and across conversations |

### 1.3 Contact Management

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Contacts CRUD** | `app/models/contact.rb`, `contacts_controller.rb` | Create, view, update, merge contacts |
| **Contact Inboxes** | `app/models/contact_inbox.rb` | Track which channels a contact uses |
| **Contact Notes** | `app/models/note.rb` | Add private notes to contacts |
| **Contact Labels** | `store/modules/contactLabels.js` | Label/tag contacts |
| **Contact Conversations** | `store/modules/contactConversations.js` | View all conversations for a contact |
| **Custom Attributes** | `app/models/custom_attribute_definition.rb` | Define custom fields for contacts & conversations |
| **Contact Search** | `app/services/search_service.rb` | Full-text search across contacts |
| **Contact Import** | `app/models/data_import.rb` | CSV import of contacts |
| **Contact IP Lookup** | `app/jobs/contact_ip_lookup_job.rb` | Geo-locate contacts by IP |
| **Contact Merge** | `app/services/contacts/` | Merge duplicate contacts |
| **Companies** | `enterprise/app/models/company.rb` | Company/organization entity (Enterprise) |

### 1.4 Inbox Management

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Inbox CRUD** | `app/models/inbox.rb`, `inboxes_controller.rb` | Create and configure inboxes per channel |
| **Inbox Members** | `app/models/inbox_member.rb` | Assign agents to inboxes |
| **Working Hours** | `app/models/working_hour.rb` | Business hours per inbox |
| **Assignment Policies** | `app/models/assignment_policy.rb` | Round-robin, load-balanced assignment |
| **CSAT Templates** | `inbox_csat_templates_controller.rb` | Custom CSAT survey templates per inbox |

### 1.5 Team Management

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Teams CRUD** | `app/models/team.rb` | Create and manage teams |
| **Team Members** | `app/models/team_member.rb` | Add/remove agents from teams |
| **Team Assignment** | `team_members_controller.rb` | Assign conversations to teams |

### 1.6 Agent & User Management

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **User/Agent CRUD** | `app/models/user.rb`, `agents_controller.rb` | Manage agent accounts |
| **Account Users** | `app/models/account_user.rb` | Multi-account user membership |
| **Roles** | `app/models/account_user.rb` | Administrator, Agent roles |
| **Custom Roles** | `enterprise/app/models/custom_role.rb` | Custom role definitions (Enterprise) |
| **Agent Bots** | `app/models/agent_bot.rb` | Bot agents for automation |
| **Agent Bot Inboxes** | `app/models/agent_bot_inbox.rb` | Assign bots to inboxes |
| **Notification Settings** | `app/models/notification_setting.rb` | Per-agent notification preferences |
| **Notification Subscriptions** | `app/models/notification_subscription.rb` | Push notification subscriptions |
| **Profiles** | `profiles_controller.rb` | Agent profile management |
| **MFA** | `app/services/mfa/` | Multi-factor authentication |

### 1.7 Automation & Workflows

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Automation Rules** | `app/models/automation_rule.rb` | Event-driven automation rules (conditions + actions) |
| **Macros** | `app/models/macro.rb` | Saved action sequences for quick execution |
| **Campaigns** | `app/models/campaign.rb` | Ongoing/one-off campaigns (proactive messages) |
| **Canned Responses** | `app/models/canned_response.rb` | Pre-written response templates |

### 1.8 AI / Captain (Enterprise)

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Captain Assistants** | `enterprise/app/models/captain/assistant.rb` | AI assistants for conversations |
| **Captain Documents** | `enterprise/app/models/captain/document.rb` | Knowledge base documents for AI |
| **Captain Scenarios** | `enterprise/app/models/captain/scenario.rb` | AI interaction scenarios |
| **Captain Custom Tools** | `enterprise/app/models/captain/custom_tool.rb` | Custom tools for AI assistants |
| **Copilot** | `enterprise/app/models/copilot_thread.rb` | AI copilot for agents |
| **Article Embeddings** | `enterprise/app/models/article_embedding.rb` | Vector embeddings for knowledge base |
| **Captain Inbox** | `enterprise/app/models/captain_inbox.rb` | AI-enabled inbox settings |
| **LLM Integration** | `lib/integrations/llm_base_service.rb` | Base LLM service integration |

### 1.9 Help Center / Knowledge Base

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Portals** | `app/models/portal.rb` | Knowledge base portals |
| **Articles** | `app/models/article.rb` | Help center articles |
| **Categories** | `app/models/category.rb` | Article categories |
| **Related Categories** | `app/models/related_category.rb` | Cross-linked categories |
| **Folders** | `app/models/folder.rb` | Article organization |
| **Portal Frontend** | `app/javascript/portal/` | Public-facing help center SPA |

### 1.10 Reporting & Analytics

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Reports** | `store/modules/reports.js` | Conversation, agent, inbox, team, label reports |
| **Summary Reports** | `store/modules/summaryReports.js` | Summary/overview reports |
| **CSAT Reports** | `store/modules/csat.js` | Customer satisfaction reports |
| **Reporting Events** | `app/models/reporting_event.rb` | Event tracking for analytics |
| **Audit Logs** | `store/modules/auditlogs.js` | Activity audit trail (Enterprise) |

### 1.11 Integrations (2 — Scoped Down)

| Integration | Key Files | Description |
|-------------|-----------|-------------|
| **Webhooks** | `app/models/webhook.rb`, `app/jobs/webhook_job.rb`, `app/listeners/webhook_listener.rb` | Outgoing webhook events on conversation/message/contact lifecycle events |
| **Dialogflow** | `lib/integrations/dialogflow/`, `app/services/automation_rules/` | Google Dialogflow chatbot — auto-responds to customer messages using NLU |

### 1.12 Platform API

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Platform Apps** | `app/models/platform_app.rb` | Third-party platform app registration |
| **Platform Permissibles** | `app/models/platform_app_permissible.rb` | Platform app permissions |
| **Platform API** | `app/controllers/platform/` | External platform API for multi-tenant operations |

### 1.13 Authentication & Security

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Authentication** | `app/models/user.rb` (Devise) | Email/password auth with Devise |
| **Access Tokens** | `app/models/access_token.rb` | API token management |
| **SSO/SAML** | `enterprise/app/models/account_saml_settings.rb` | SAML SSO (Enterprise) |
| **MFA/2FA** | `app/services/mfa/` | Multi-factor authentication |
| **Authorization** | `app/policies/` | Pundit policy-based authorization (23+ policies) |
| **Super Admin** | `app/models/super_admin.rb` | Super admin access |

### 1.14 Real-Time Features

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **WebSocket (ActionCable)** | `app/channels/room_channel.rb` | Real-time message delivery |
| **ActionCable Broadcasting** | `app/jobs/action_cable_broadcast_job.rb` | Broadcast events to connected clients |
| **Typing Indicators** | `store/modules/conversationTypingStatus.js` | Real-time typing status |
| **Presence** | Via ActionCable | Online/offline agent status |

### 1.15 Notifications

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **In-App Notifications** | `app/models/notification.rb` | In-app notification system |
| **Push Notifications** | `app/models/notification_subscription.rb` | Browser/mobile push |
| **Email Notifications** | `app/mailers/` | Email notifications for conversations |
| **Agent Notifications** | `app/mailers/agent_notifications/` | Agent-specific email alerts |
| **Admin Notifications** | `app/mailers/administrator_notifications/` | Admin email alerts |
| **Team Notifications** | `app/mailers/team_notifications/` | Team-level email alerts |

### 1.16 Widget (Customer-Facing)

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Chat Widget** | `app/javascript/widget/` | Embeddable website chat widget |
| **Widget API** | `app/controllers/api/v1/widget/` | Widget-specific API endpoints |
| **Pre-chat Forms** | Widget configuration | Collect info before chat starts |
| **CSAT Survey UI** | `app/javascript/survey/` | Post-conversation satisfaction survey |

### 1.17 Administration

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Account Management** | `app/models/account.rb` | Multi-tenant account management |
| **Installation Config** | `app/models/installation_config.rb` | Global installation settings |
| **Super Admin Panel** | `app/controllers/super_admin/` | Instance-level administration |
| **Custom Domains** | `enterprise/app/controllers/custom_domains_controller.rb` | Custom domain support (Enterprise) |
| **Email Templates** | `app/models/email_template.rb` | Customizable email templates |
| **Account Seeding** | `app/services/internal/` | Dev/test data seeding |

### 1.18 Background Processing & Events

| Feature | Key Files | Description |
|---------|-----------|-------------|
| **Event System** | `app/listeners/` | 12+ event listeners (ActionCable, automation, bots, campaigns, CSAT, hooks, notifications, webhooks) |
| **Background Jobs** | `app/jobs/` | 30+ Sidekiq background jobs |
| **Scheduled Tasks** | `trigger_scheduled_items_job.rb` | Scheduled campaign/automation triggers |
| **Webhook Delivery** | `app/jobs/webhook_job.rb` | Async webhook event delivery |
| **Email Processing** | `app/services/email/`, `app/services/imap/` | Inbound/outbound email processing |

---

## 2. .NET + ANGULAR REBUILD ARCHITECTURE

### 2.1 Backend — .NET 8 (ASP.NET Core)

| Chatwoot Component | .NET Equivalent |
|-------------------|-----------------|
| Rails MVC / API Controllers | ASP.NET Core Minimal APIs or Controllers |
| ActiveRecord Models | Entity Framework Core (Code-First) |
| Sidekiq Background Jobs | Hangfire or .NET BackgroundService + MassTransit/RabbitMQ |
| ActionCable (WebSockets) | ASP.NET Core SignalR |
| Devise (Auth) | ASP.NET Core Identity + JWT Bearer tokens |
| Pundit (Authorization) | Policy-based Authorization (`IAuthorizationHandler`) |
| ActiveStorage (File Uploads) | Azure Blob Storage / AWS S3 via `IFormFile` + custom storage service |
| ActionMailer | FluentEmail or MailKit |
| Redis Cache | StackExchange.Redis / IDistributedCache |
| PostgreSQL | Npgsql + EF Core PostgreSQL provider |
| Rack Middleware | ASP.NET Core Middleware pipeline |
| Rails Event Listeners | MediatR (CQRS pattern) for domain events |
| Liquid Templates | Fluid (Liquid template engine for .NET) |
| Geocoder | MaxMind GeoIP2 .NET SDK |

### 2.2 Frontend — Angular 17+

| Chatwoot Component | Angular Equivalent |
|-------------------|-------------------|
| Vue.js 3 Dashboard SPA | Angular 17+ with standalone components |
| Vuex/Pinia Store | NgRx (Redux pattern) or Angular Signals |
| Vue Router | Angular Router with lazy-loaded modules |
| Vue i18n | @ngx-translate/core |
| Tailwind CSS | Tailwind CSS (framework-agnostic) |
| Chart.js (reports) | ngx-charts or Chart.js with ng2-charts |
| Widget (Vue SPA) | Angular Elements (Web Components) for embeddable widget |
| Portal (Vue SPA) | Separate Angular app or Angular SSR (for SEO) |

### 2.3 Proposed Project Structure

```
/src
├── ChatwootApi/                          # ASP.NET Core Web API
│   ├── Controllers/
│   │   ├── Api/V1/Accounts/             # Account-scoped endpoints
│   │   ├── Api/V1/Widget/               # Widget API
│   │   ├── Platform/                     # Platform API
│   │   └── SuperAdmin/                   # Admin endpoints
│   ├── Hubs/                             # SignalR Hubs (real-time)
│   ├── Middleware/                        # Auth, tenant, rate-limiting
│   └── Program.cs
├── Chatwoot.Core/                        # Domain layer
│   ├── Entities/                         # EF Core entities (50+ models)
│   ├── Interfaces/                       # Repository & service contracts
│   ├── Enums/
│   └── Events/                           # Domain events (MediatR)
├── Chatwoot.Application/                 # Application/service layer
│   ├── Services/                         # Business logic services
│   │   ├── Conversations/
│   │   ├── Contacts/
│   │   ├── Channels/                     # WebWidget, Email, Api
│   │   ├── Automations/
│   │   ├── Integrations/                 # Webhooks, Dialogflow
│   │   ├── Reporting/
│   │   └── AI/                           # Captain/Copilot (Enterprise)
│   ├── Commands/                         # CQRS commands
│   ├── Queries/                          # CQRS queries
│   ├── EventHandlers/                    # MediatR event handlers
│   └── BackgroundJobs/                   # Hangfire jobs
├── Chatwoot.Infrastructure/             # Data access & external services
│   ├── Persistence/                      # EF Core DbContext, migrations
│   ├── Repositories/
│   ├── ExternalServices/                 # Email (MailKit), Dialogflow SDK, LLM
│   └── Identity/                         # Auth & Identity
├── Chatwoot.Enterprise/                 # Enterprise overlay (separate assembly)
│   ├── Captain/                          # AI assistants, copilot, documents
│   ├── CustomRoles/                      # Custom role definitions & permissions
│   └── SAML/                             # SAML SSO identity provider
├── chatwoot-dashboard/                   # Angular 17+ Dashboard
│   ├── src/app/
│   │   ├── core/                         # Guards, interceptors, services
│   │   ├── shared/                       # Shared components, pipes
│   │   ├── features/
│   │   │   ├── conversations/
│   │   │   ├── contacts/
│   │   │   ├── inboxes/
│   │   │   ├── reports/
│   │   │   ├── settings/
│   │   │   ├── captain/
│   │   │   ├── help-center/
│   │   │   └── notifications/
│   │   └── store/                        # NgRx state management
├── chatwoot-widget/                      # Angular Elements (Web Component)
└── chatwoot-portal/                      # Angular SSR (Help Center)
```

---

## 3. PHASED IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Weeks 1–4)
- [ ] .NET solution scaffolding (Clean Architecture)
- [ ] EF Core DbContext with all 50+ entities & migrations (PostgreSQL)
- [ ] ASP.NET Core Identity setup (registration, login, JWT, refresh tokens)
- [ ] Multi-tenancy (Account-scoped data isolation)
- [ ] SignalR hub for real-time messaging
- [ ] Angular project setup with routing, NgRx, Tailwind, i18n
- [ ] Basic auth flows (login, register, forgot password)

### Phase 2: Core Messaging (Weeks 5–8)
- [ ] Conversation model & CRUD APIs
- [ ] Message model with attachments (S3/Azure Blob)
- [ ] Web Widget channel (first channel)
- [ ] Real-time message delivery via SignalR
- [ ] Agent assignment (manual + round-robin)
- [ ] Angular conversation list & chat UI
- [ ] Embeddable widget (Angular Elements)
- [ ] Typing indicators & presence

### Phase 3: Contact & Inbox Management (Weeks 9–11)
- [ ] Contact CRUD, search, merge, import (CSV)
- [ ] Custom attributes for contacts & conversations
- [ ] Inbox CRUD & configuration
- [ ] Inbox members & working hours
- [ ] Labels for conversations & contacts
- [ ] Teams & team members
- [ ] Angular settings pages (inboxes, teams, agents, labels)

### Phase 4: Additional Channels (Weeks 12–13)
- [ ] Email channel (IMAP inbound + SMTP outbound via MailKit)
- [ ] API channel (custom REST channel for third-party systems)

### Phase 5: Automation & Productivity (Weeks 17–19)
- [ ] Canned responses
- [ ] Macros (saved action sequences)
- [ ] Automation rules engine (event → conditions → actions)
- [ ] Campaigns (ongoing + one-off)
- [ ] CSAT surveys
- [ ] Bulk actions on conversations
- [ ] Custom filters / saved views

### Phase 6: Integrations (Weeks 18–19)
- [ ] Webhook system (register webhooks, fire events on conversation/message/contact lifecycle)
- [ ] Dialogflow chatbot integration (connect Dialogflow agent to inbox, auto-respond to messages)

### Phase 7: Reporting & Help Center (Weeks 20–22)
- [ ] Reporting events pipeline
- [ ] Conversation/agent/inbox/team/label reports
- [ ] CSAT reports
- [ ] Summary/overview reports
- [ ] Help Center portals, articles, categories
- [ ] Public help center Angular SSR app

### Phase 8: Notifications & Administration (Weeks 23–24)
- [ ] In-app notification system
- [ ] Push notifications (Web Push)
- [ ] Email notifications (agent, admin, team)
- [ ] Notification preferences
- [ ] Super Admin panel
- [ ] Account settings & branding
- [ ] Audit logs
- [ ] Agent bots

### Phase 9: Enterprise Features (Weeks 25–28)
- [ ] Custom Roles & granular permissions
- [ ] SAML SSO (identity provider integration)
- [ ] Captain AI assistants (create, configure, connect to inboxes)
- [ ] Captain documents & knowledge base (upload, embed, vector search)
- [ ] Captain scenarios & custom tools
- [ ] Copilot for agents (AI-assisted replies, suggestions)

### Phase 10: Platform API & Polish (Weeks 29–31)
- [ ] Platform API (multi-tenant external API)
- [ ] Platform apps & permissions
- [ ] MFA/2FA
- [ ] Rate limiting & security hardening
- [ ] Performance optimization
- [ ] E2E testing
- [ ] Documentation

---

## 4. KEY DATA ENTITIES (50+ Models to Migrate)

**Core:** Account, User, AccountUser, AccessToken, SuperAdmin, InstallationConfig
**Messaging:** Conversation, Message, Attachment, ConversationParticipant, Mention
**Contacts:** Contact, ContactInbox, Note, CustomAttributeDefinition, DataImport
**Channels (3):** WebWidget, Email, Api
**Inbox:** Inbox, InboxMember, WorkingHour, AssignmentPolicy
**Teams:** Team, TeamMember
**Automation:** AutomationRule, Macro, Campaign, CannedResponse
**Labels:** Label
**Notifications:** Notification, NotificationSetting, NotificationSubscription
**Reporting:** ReportingEvent, CsatSurveyResponse
**Integrations:** Integrations::Hook, Webhook
**Help Center:** Portal, Article, Category, RelatedCategory, Folder
**Platform:** PlatformApp, PlatformAppPermissible
**Bots:** AgentBot, AgentBotInbox
**Filters:** CustomFilter
**Enterprise:** CustomRole, AccountSamlSettings, Captain::Assistant, Captain::Document, Captain::Scenario, Captain::CustomTool, CaptainInbox, CopilotThread, CopilotMessage, ArticleEmbedding

---

## 5. VERIFICATION / TESTING STRATEGY

- **Unit Tests:** xUnit + Moq for .NET services; Jasmine/Karma for Angular components
- **Integration Tests:** WebApplicationFactory for API endpoint testing
- **E2E Tests:** Playwright or Cypress for full workflow testing
- **Key flows to verify:**
  1. Agent login → view conversations → reply to message → see real-time update
  2. Widget loads on external site → customer sends message → agent sees it in real-time
  3. Create inbox (Web Widget / Email / API) → configure → receive message through channel
  4. Email channel: inbound IMAP pickup → creates conversation → agent replies → SMTP outbound
  5. API channel: external system sends message via REST → conversation created → reply sent back
  6. Automation rule triggers on new conversation → auto-assigns to team
  7. Contact search, merge, and custom attributes work correctly
  8. Reports load with correct aggregated data
  9. Help center article CRUD and public portal rendering
  10. Webhook fires on conversation/message/contact events
  11. Dialogflow bot auto-responds to customer messages in connected inbox
  12. CSAT survey sent after resolution and responses recorded
