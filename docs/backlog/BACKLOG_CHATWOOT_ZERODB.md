# Chatwoot-ZeroDB Fork: Development Backlog

**Version:** 1.0
**Created:** December 16, 2025
**Status:** Ready for Development
**Project:** Chatwoot-ZeroDB Integration

---

## Overview

This backlog contains all development tasks required to implement the Chatwoot-ZeroDB fork as outlined in the [Master Plan](planning/CHATWOOT_ZERODB_FORK_MASTER_PLAN.md). Tasks are organized by epic/phase and prioritized for sequential implementation.

**Total Story Points:** 89
**Estimated Duration:** 12 weeks
**Team Size:** 4-6 developers

---

## Epic 1: Database Migration to ZeroDB (Weeks 1-2)

**Epic Points:** 13
**Priority:** P0 (Critical)
**Dependencies:** None

### Story 1.1: Provision ZeroDB Infrastructure

**Points:** 3
**Priority:** P0
**Assignee:** DevOps Lead

**Description:**
Set up ZeroDB account, create project, and provision dedicated PostgreSQL instance for Chatwoot.

**Acceptance Criteria:**
- [ ] ZeroDB account created with credentials stored in 1Password
- [ ] Project created via API with name "Chatwoot Production"
- [ ] Dedicated PostgreSQL instance provisioned (Standard-4, 100GB)
- [ ] Connection credentials verified and documented
- [ ] pgvector extension enabled and tested
- [ ] SSL connection working

**Technical Details:**
```bash
# API endpoint for provisioning
POST https://api.ainative.studio/v1/public/{project_id}/postgres/provision

# Required parameters
{
  "instance_size": "standard-4",
  "database_name": "chatwoot_production",
  "version": "15",
  "storage_gb": 100,
  "max_connections": 200
}
```

**Files Modified:**
- None (infrastructure only)

**Testing:**
- [ ] Can connect to PostgreSQL instance via psql
- [ ] pgvector extension loaded successfully
- [ ] 200 max connections confirmed

---

### Story 1.2: Update Database Configuration

**Points:** 2
**Priority:** P0
**Dependencies:** Story 1.1

**Description:**
Update Chatwoot's database configuration to point to ZeroDB dedicated PostgreSQL instance.

**Acceptance Criteria:**
- [ ] `config/database.yml` updated with ZeroDB connection details
- [ ] Environment variables documented in `.env.example`
- [ ] Local development `.env` configured
- [ ] Production environment variables set (Railway/Heroku)
- [ ] SSL mode enabled for secure connections

**Files Modified:**
- `config/database.yml` - Update production database config
- `.env.example` - Add ZeroDB environment variables
- `README.md` - Document new environment variables

**Technical Details:**
```yaml
# config/database.yml
production:
  <<: *default
  host: <%= ENV.fetch('ZERODB_POSTGRES_HOST') %>
  port: <%= ENV.fetch('ZERODB_POSTGRES_PORT', '5432') %>
  database: <%= ENV.fetch('ZERODB_POSTGRES_DATABASE') %>
  username: <%= ENV.fetch('ZERODB_POSTGRES_USERNAME') %>
  password: <%= ENV.fetch('ZERODB_POSTGRES_PASSWORD') %>
  sslmode: require
```

**Testing:**
- [ ] Database connection works in development
- [ ] Rails console can query database
- [ ] Migrations run successfully

---

### Story 1.3: Migrate Existing Data

**Points:** 5
**Priority:** P0
**Dependencies:** Story 1.2

**Description:**
Export existing Chatwoot database and import to ZeroDB dedicated PostgreSQL instance.

**Acceptance Criteria:**
- [ ] Full database backup created with pg_dump
- [ ] Backup verified (can be restored locally)
- [ ] Data imported to ZeroDB PostgreSQL
- [ ] Row counts verified across all 84 tables
- [ ] Foreign key constraints validated
- [ ] Indexes recreated successfully
- [ ] Rollback plan documented

**Files Modified:**
- None (data migration only)

**Technical Details:**
```bash
# Backup
pg_dump -h localhost -U postgres -d chatwoot_dev \
  --clean --create --if-exists > chatwoot_backup.sql

# Restore
psql -h ${ZERODB_POSTGRES_HOST} \
     -U ${ZERODB_POSTGRES_USERNAME} \
     -d ${ZERODB_POSTGRES_DATABASE} \
     -f chatwoot_backup.sql
```

**Testing:**
- [ ] All 84 tables migrated
- [ ] Total row count matches source
- [ ] Sample queries return correct data
- [ ] Can create/update/delete test records

---

### Story 1.4: Integration Testing & Validation

**Points:** 3
**Priority:** P0
**Dependencies:** Story 1.3

**Description:**
Comprehensive testing to ensure 100% feature parity after migration.

**Acceptance Criteria:**
- [ ] All RSpec tests passing (100% pass rate)
- [ ] Manual testing checklist completed
- [ ] Core workflows tested (login, messages, reports)
- [ ] Performance benchmarks meet baseline
- [ ] No database connection errors in logs
- [ ] Migration documented in CHANGELOG

**Files Modified:**
- `docs/MIGRATION_LOG.md` - Document migration results
- `CHANGELOG.md` - Note database migration

**Testing Checklist:**
- [ ] User authentication (login/logout)
- [ ] Create conversation
- [ ] Send/receive messages
- [ ] Search contacts
- [ ] View reports/analytics
- [ ] Automation rules work
- [ ] Webhook integrations work
- [ ] File uploads/downloads work

**Performance Metrics:**
- [ ] Page load time < 2s
- [ ] Message send latency < 500ms
- [ ] Search query time < 1s

---

## Epic 2: AI Feature - Semantic Search (Weeks 3-4)

**Epic Points:** 21
**Priority:** P1 (High)
**Dependencies:** Epic 1

### Story 2.1: ZeroDB Ruby SDK Integration

**Points:** 5
**Priority:** P1
**Dependencies:** None

**Description:**
Create Ruby service layer for ZeroDB API interactions (embeddings, vector search).

**Acceptance Criteria:**
- [ ] HTTParty gem configured for ZeroDB API
- [ ] Base service class with authentication
- [ ] Embeddings API wrapper functional
- [ ] Vector storage API wrapper functional
- [ ] Search API wrapper functional
- [ ] Error handling for API failures
- [ ] Rate limiting implementation
- [ ] RSpec tests for all API methods

**Files Modified:**
- `Gemfile` - Add HTTParty if not present
- `app/services/zerodb/base_service.rb` - New base class
- `app/services/zerodb/embeddings_client.rb` - New service
- `app/services/zerodb/vector_client.rb` - New service
- `spec/services/zerodb/` - New test suite

**Technical Details:**
```ruby
module Zerodb
  class BaseService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL')

    def initialize
      @api_key = ENV['ZERODB_API_KEY']
      @project_id = ENV['ZERODB_PROJECT_ID']
    end

    private

    def headers
      {
        'X-API-Key' => @api_key,
        'Content-Type' => 'application/json'
      }
    end
  end
end
```

**Testing:**
- [ ] Can generate embeddings for sample text
- [ ] Can store vectors in ZeroDB
- [ ] Can search vectors by similarity
- [ ] API errors handled gracefully

---

### Story 2.2: Semantic Search Service

**Points:** 8
**Priority:** P1
**Dependencies:** Story 2.1

**Description:**
Implement semantic search for conversations using ZeroDB vector search.

**Acceptance Criteria:**
- [ ] Service generates embeddings for conversations
- [ ] Conversations indexed to ZeroDB on creation
- [ ] Search returns relevant results by meaning
- [ ] Results ranked by similarity score
- [ ] Filters (status, inbox, date) work
- [ ] Pagination implemented
- [ ] Background job for indexing
- [ ] Performance meets SLA (search < 1s)

**Files Modified:**
- `app/services/zerodb/semantic_search_service.rb` - New service
- `app/jobs/zerodb/index_conversation_job.rb` - New background job
- `app/models/message.rb` - Add after_create callback
- `spec/services/zerodb/semantic_search_service_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 290-391

**Testing:**
- [ ] Search "customer wants refund" finds refund conversations
- [ ] Search "billing issue" finds payment-related tickets
- [ ] Similarity threshold filters irrelevant results
- [ ] Search works across multiple accounts (isolated)

---

### Story 2.3: Search API Endpoints

**Points:** 3
**Priority:** P1
**Dependencies:** Story 2.2

**Description:**
Create REST API endpoints for semantic search in conversations.

**Acceptance Criteria:**
- [ ] POST endpoint `/api/v1/accounts/:account_id/conversations/semantic_search`
- [ ] Query parameter validation (query, limit, filters)
- [ ] JSON response with conversation objects
- [ ] Rate limiting (100 requests/minute per account)
- [ ] API documented in Swagger
- [ ] Authenticated requests only

**Files Modified:**
- `app/controllers/api/v1/accounts/conversations/semantic_search_controller.rb` - New controller
- `config/routes.rb` - Add route
- `swagger/definitions/semantic_search.yml` - API docs
- `spec/controllers/api/v1/accounts/conversations/semantic_search_controller_spec.rb` - Tests

**API Example:**
```json
POST /api/v1/accounts/1/conversations/semantic_search
{
  "query": "customer wants refund",
  "limit": 20,
  "filters": {
    "status": "open",
    "inbox_id": 5
  }
}
```

**Testing:**
- [ ] API returns 200 with valid query
- [ ] API returns 400 with missing query
- [ ] API returns 401 without authentication
- [ ] Rate limiting works

---

### Story 2.4: Frontend Semantic Search UI

**Points:** 5
**Priority:** P1
**Dependencies:** Story 2.3

**Description:**
Add semantic search interface to Chatwoot dashboard conversations page.

**Acceptance Criteria:**
- [ ] Search input with "Powered by ZeroDB AI" badge
- [ ] Debounced search (500ms delay)
- [ ] Loading state during search
- [ ] Results display with similarity scores
- [ ] Empty state for no results
- [ ] Mobile-responsive design
- [ ] Accessible (keyboard navigation, ARIA labels)

**Files Modified:**
- `app/javascript/dashboard/routes/dashboard/conversation/search/SemanticSearch.vue` - New component
- `app/javascript/dashboard/routes/dashboard/conversation/Index.vue` - Integrate component
- `app/javascript/dashboard/api/conversations.js` - Add API call
- `app/javascript/dashboard/i18n/locale/en/conversation.json` - Add translations

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 478-554

**Testing:**
- [ ] Search input appears on conversations page
- [ ] Search triggers API call after 500ms
- [ ] Results appear below search bar
- [ ] Click result navigates to conversation
- [ ] Works on mobile devices

---

## Epic 3: AI Feature - Smart Suggestions (Week 5)

**Epic Points:** 13
**Priority:** P1 (High)
**Dependencies:** Story 2.1

### Story 3.1: Canned Response Indexing Service

**Points:** 5
**Priority:** P1
**Dependencies:** Story 2.1

**Description:**
Index all canned responses to ZeroDB for semantic matching.

**Acceptance Criteria:**
- [ ] Service indexes all canned responses on account setup
- [ ] New canned responses auto-indexed on creation
- [ ] Updated canned responses re-indexed
- [ ] Deleted canned responses removed from index
- [ ] Embeddings generated for response content
- [ ] Metadata includes short_code, content
- [ ] Background job for bulk indexing

**Files Modified:**
- `app/services/zerodb/canned_response_suggester.rb` - New service
- `app/jobs/zerodb/index_canned_response_job.rb` - New job
- `app/models/canned_response.rb` - Add callbacks
- `spec/services/zerodb/canned_response_suggester_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 569-656

**Testing:**
- [ ] All existing canned responses indexed
- [ ] New response triggers indexing job
- [ ] Update re-indexes response
- [ ] Delete removes from ZeroDB

---

### Story 3.2: Suggestion API & Frontend

**Points:** 8
**Priority:** P1
**Dependencies:** Story 3.1

**Description:**
Suggest relevant canned responses based on conversation context.

**Acceptance Criteria:**
- [ ] API endpoint suggests top 5 canned responses
- [ ] Suggestions based on last 3 customer messages
- [ ] Similarity threshold 0.6+ for quality
- [ ] Frontend sidebar shows suggestions
- [ ] "Use" button inserts response into reply box
- [ ] Thumbs up/down for RLHF feedback
- [ ] Real-time updates as conversation changes

**Files Modified:**
- `app/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller.rb` - New
- `app/javascript/dashboard/components/CannedResponseSuggestions.vue` - New component
- `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue` - Integrate
- `spec/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 659-691

**Testing:**
- [ ] Suggestions appear in conversation sidebar
- [ ] Click "Use" inserts text into reply editor
- [ ] Suggestions update when new message received
- [ ] Thumbs up/down sends feedback

---

## Epic 4: AI Feature - Agent Memory (Week 6)

**Epic Points:** 13
**Priority:** P2 (Medium)
**Dependencies:** Story 2.1

### Story 4.1: Memory Storage Service

**Points:** 5
**Priority:** P2
**Dependencies:** Story 2.1

**Description:**
Store customer preferences and notes in ZeroDB Memory API.

**Acceptance Criteria:**
- [ ] Service stores memories for contacts
- [ ] Memories tagged by type (preference, note, issue)
- [ ] Importance levels (low, medium, high)
- [ ] Auto-extract insights from conversations (optional AI)
- [ ] Search memories by contact ID
- [ ] Semantic search across all memories

**Files Modified:**
- `app/services/zerodb/agent_memory_service.rb` - New service
- `app/models/contact.rb` - Add memory helpers
- `spec/services/zerodb/agent_memory_service_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 699-782

**Testing:**
- [ ] Can store memory for contact
- [ ] Can recall memories by contact ID
- [ ] Semantic search finds relevant memories
- [ ] Memories persist across sessions

---

### Story 4.2: Memory UI & Display

**Points:** 8
**Priority:** P2
**Dependencies:** Story 4.1

**Description:**
Display customer context and notes in contact sidebar.

**Acceptance Criteria:**
- [ ] Sidebar shows recent memories for contact
- [ ] "Add Note" button creates new memory
- [ ] Memories color-coded by importance
- [ ] Memories searchable within sidebar
- [ ] Memories visible to all agents in account
- [ ] Mobile-friendly design

**Files Modified:**
- `app/javascript/dashboard/components/ContactMemories.vue` - New component
- `app/javascript/dashboard/routes/dashboard/conversation/contact/ContactPanel.vue` - Integrate
- `app/controllers/api/v1/accounts/contacts/memories_controller.rb` - New API
- `spec/controllers/api/v1/accounts/contacts/memories_controller_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 785-807

**Testing:**
- [ ] Memories appear in contact sidebar
- [ ] Can add new memory via form
- [ ] Memories persist across page refresh
- [ ] Search filters memories correctly

---

## Epic 5: AI Feature - RLHF & Similar Tickets (Week 7-8)

**Epic Points:** 13
**Priority:** P2 (Medium)
**Dependencies:** Story 2.1

### Story 5.1: RLHF Feedback Collection

**Points:** 5
**Priority:** P2
**Dependencies:** Stories 2.4, 3.2

**Description:**
Collect agent feedback on AI suggestions to improve quality over time.

**Acceptance Criteria:**
- [ ] Thumbs up/down buttons on all AI suggestions
- [ ] Feedback sent to ZeroDB RLHF API
- [ ] Feedback includes prompt, response, rating
- [ ] Feedback tracked per account
- [ ] Admin dashboard shows RLHF stats
- [ ] Feedback anonymous (no PII)

**Files Modified:**
- `app/services/zerodb/rlhf_service.rb` - New service
- `app/controllers/api/v1/rlhf/feedback_controller.rb` - New API
- `app/javascript/dashboard/components/AISuggestionFeedback.vue` - New component
- `spec/services/zerodb/rlhf_service_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 815-900

**Testing:**
- [ ] Thumbs up sends rating: 5
- [ ] Thumbs down sends rating: 1
- [ ] Feedback appears in ZeroDB RLHF dashboard
- [ ] Stats API returns feedback count

---

### Story 5.2: Similar Ticket Detection

**Points:** 8
**Priority:** P2
**Dependencies:** Story 2.2

**Description:**
Automatically detect and link related conversations using vector similarity.

**Acceptance Criteria:**
- [ ] Service finds top 5 similar conversations
- [ ] Similarity threshold 0.75+ for quality
- [ ] Excludes current conversation from results
- [ ] Sidebar shows "Related Conversations"
- [ ] Click related conversation navigates to it
- [ ] Shows similarity score percentage

**Files Modified:**
- `app/services/zerodb/similar_ticket_detector.rb` - New service
- `app/controllers/api/v1/accounts/conversations/similar_controller.rb` - New API
- `app/javascript/dashboard/components/SimilarTickets.vue` - New component
- `spec/services/zerodb/similar_ticket_detector_spec.rb` - Tests

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 904-967

**Testing:**
- [ ] Similar tickets appear in sidebar
- [ ] Tickets ranked by similarity
- [ ] Click navigates to conversation
- [ ] No duplicate tickets in results

---

## Epic 6: Branding & Signup Integration (Week 9-10)

**Epic Points:** 8
**Priority:** P3 (Low)
**Dependencies:** Epics 2-5

### Story 6.1: ZeroDB Branding & CTAs

**Points:** 3
**Priority:** P3
**Dependencies:** None

**Description:**
Add "Powered by ZeroDB" badges and upgrade prompts throughout the app.

**Acceptance Criteria:**
- [ ] Badge on semantic search box
- [ ] Badge on AI suggestions panel
- [ ] Footer link to ZeroDB homepage
- [ ] Upgrade banner for heavy users (100+ searches)
- [ ] Banner links to ZeroDB pricing page
- [ ] All links include referral tracking (?ref=chatwoot)

**Files Modified:**
- `app/javascript/dashboard/components/layout/Footer.vue` - Add ZeroDB link
- `app/javascript/dashboard/routes/dashboard/conversation/search/SemanticSearch.vue` - Add badge
- `app/javascript/dashboard/components/CannedResponseSuggestions.vue` - Add badge
- `app/javascript/dashboard/components/UpgradeBanner.vue` - New component

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 996-1045

**Testing:**
- [ ] Badges visible on all AI features
- [ ] Footer link goes to https://zerodb.io?ref=chatwoot
- [ ] Upgrade banner appears after 100 searches
- [ ] Banner dismissible (stores in localStorage)

---

### Story 6.2: Developer Documentation

**Points:** 5
**Priority:** P3
**Dependencies:** All epics

**Description:**
Document ZeroDB integration for developers who want to fork or contribute.

**Acceptance Criteria:**
- [ ] `/docs/zerodb-integration.md` created
- [ ] Architecture diagrams included
- [ ] Code examples for each feature
- [ ] API endpoint documentation
- [ ] Cost calculator explanation
- [ ] Contributing guidelines updated
- [ ] README updated with ZeroDB info

**Files Modified:**
- `docs/zerodb-integration.md` - New comprehensive guide
- `README.md` - Add ZeroDB section
- `CONTRIBUTING.md` - Add ZeroDB contribution guidelines
- `docs/ARCHITECTURE.md` - Update with ZeroDB components

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 1048-1099

**Testing:**
- [ ] Documentation renders correctly on GitHub
- [ ] All code examples tested and working
- [ ] Links valid and functional
- [ ] Architecture diagrams clear

---

## Epic 7: Metrics & Analytics (Week 11)

**Epic Points:** 8
**Priority:** P3 (Low)
**Dependencies:** All epics

### Story 7.1: ZeroDB Usage Dashboard

**Points:** 5
**Priority:** P3
**Dependencies:** All AI features

**Description:**
Admin dashboard showing ZeroDB usage, costs, and performance metrics.

**Acceptance Criteria:**
- [ ] Dashboard accessible at `/super_admin/zerodb_analytics`
- [ ] Shows vector count, search count, embedding calls
- [ ] Displays estimated monthly cost
- [ ] Shows performance metrics (avg search time)
- [ ] Chart of usage over time (last 30 days)
- [ ] Export usage data as CSV

**Files Modified:**
- `app/controllers/super_admin/zerodb_analytics_controller.rb` - New controller
- `app/views/super_admin/zerodb_analytics/index.html.erb` - New view
- `app/javascript/dashboard/routes/dashboard/settings/zerodb/Index.vue` - New component
- `config/routes.rb` - Add route

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 1153-1244

**Testing:**
- [ ] Dashboard loads without errors
- [ ] Metrics display correct values
- [ ] Chart renders usage over time
- [ ] CSV export works

---

### Story 7.2: Cost Calculator Tool

**Points:** 3
**Priority:** P3
**Dependencies:** Story 7.1

**Description:**
Interactive cost calculator for estimating ZeroDB costs based on usage.

**Acceptance Criteria:**
- [ ] Calculator widget in ZeroDB dashboard
- [ ] Inputs: conversations/month, searches/day
- [ ] Outputs: estimated monthly cost, recommended tier
- [ ] Breakdown by service (embeddings, vectors, searches)
- [ ] "Upgrade" button links to ZeroDB pricing

**Files Modified:**
- `app/javascript/dashboard/components/ZeroDBCostCalculator.vue` - New component
- `app/javascript/dashboard/routes/dashboard/settings/zerodb/Index.vue` - Integrate

**Technical Details:**
Reference: `CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` lines 1761-1807

**Testing:**
- [ ] Calculator updates in real-time
- [ ] Cost calculation accurate
- [ ] Tier recommendation correct
- [ ] Upgrade link works

---

## Non-Functional Requirements

### Performance

**Acceptance Criteria:**
- [ ] Semantic search: < 1 second average
- [ ] Embedding generation: < 500ms per conversation
- [ ] Vector indexing: < 100ms per conversation
- [ ] Similar ticket detection: < 1.5 seconds
- [ ] No impact on existing features (< 5% latency increase)

**Testing:**
- [ ] Load test with 1000 concurrent searches
- [ ] Benchmark embedding generation at scale
- [ ] Profile database query performance

---

### Security

**Acceptance Criteria:**
- [ ] ZeroDB API keys stored in encrypted environment variables
- [ ] Multi-tenant isolation (account_id in all queries)
- [ ] No PII in embeddings metadata
- [ ] Rate limiting on all ZeroDB API calls
- [ ] Audit logging for AI feature usage
- [ ] GDPR-compliant data deletion

**Testing:**
- [ ] Penetration test AI endpoints
- [ ] Verify account isolation in vector search
- [ ] Test rate limiting with burst requests
- [ ] Verify audit logs capture events

---

### Monitoring & Observability

**Acceptance Criteria:**
- [ ] Application logs include ZeroDB API calls
- [ ] Error tracking for ZeroDB API failures
- [ ] Metrics dashboard for AI feature usage
- [ ] Alerts for high error rates (> 5%)
- [ ] Weekly usage reports for admins

**Tools:**
- Sentry for error tracking
- New Relic/DataDog for APM
- Custom analytics dashboard

**Testing:**
- [ ] Logs visible in Sentry
- [ ] Metrics visible in dashboard
- [ ] Alerts trigger on test failures

---

## Dependencies & External Services

### Required Services

1. **ZeroDB Account**
   - Account: chatwoot@ainative.studio
   - Project: Chatwoot Production
   - Tier: Pro ($49/month minimum)

2. **Railway/Heroku**
   - Deploy Chatwoot application
   - Environment variables configured

3. **GitHub**
   - Repository: AINative-Studio/chatwoot-zerodb
   - Issues enabled for bug tracking
   - Actions for CI/CD

### Ruby Gems

```ruby
# Add to Gemfile if not present
gem 'httparty', '~> 0.21.0'  # For ZeroDB API calls
```

### Environment Variables

```bash
# ZeroDB Configuration
ZERODB_API_KEY=your_api_key
ZERODB_PROJECT_ID=your_project_id
ZERODB_API_URL=https://api.ainative.studio/v1/public

# ZeroDB PostgreSQL
ZERODB_POSTGRES_HOST=postgres-xxx.railway.app
ZERODB_POSTGRES_PORT=5432
ZERODB_POSTGRES_DATABASE=chatwoot_production
ZERODB_POSTGRES_USERNAME=postgres_user_xxx
ZERODB_POSTGRES_PASSWORD=generated_password
```

---

## Risk Mitigation

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| ZeroDB API downtime | Low | High | Cache embeddings locally, fallback to keyword search |
| Rate limit exceeded | Medium | Medium | Implement queue, batch requests, upgrade ZeroDB tier |
| Migration data loss | Low | Critical | Full backup, test restore, rollback plan documented |
| Performance degradation | Medium | Medium | Load testing, caching layer, optimize queries |

### Business Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Low user adoption | Medium | High | Strong marketing, demos, free tier |
| ZeroDB cost too high | Low | Medium | Transparent cost calculator, usage alerts |
| License conflict | Low | Low | MIT license maintained, proper attribution |

---

## Release Plan

### Phase 1: Beta Launch (Week 8)

**Audience:** Internal team + 10 beta testers
**Features:**
- ✅ Database migration to ZeroDB
- ✅ Semantic search
- ✅ Smart canned response suggestions

**Goals:**
- Gather feedback on AI features
- Identify bugs and performance issues
- Refine UI/UX

---

### Phase 2: Public Launch (Week 12)

**Audience:** Public (GitHub release + blog post)
**Features:**
- ✅ All AI features (search, suggestions, memory, similar tickets)
- ✅ ZeroDB branding and signup integration
- ✅ Complete documentation
- ✅ Analytics dashboard

**Marketing:**
- Blog post on ZeroDB blog
- Product Hunt launch
- HackerNews post
- Twitter/LinkedIn announcements

---

## Success Metrics

### Week 12 (End of Project)

- [ ] 100% feature parity with original Chatwoot
- [ ] 5+ AI features implemented
- [ ] 500+ GitHub stars
- [ ] 10+ ZeroDB signups via referral
- [ ] 1,000+ demo site visitors

### 6 Months Post-Launch

- [ ] 100+ ZeroDB signups from Chatwoot users
- [ ] 50+ community forks
- [ ] 10+ production deployments
- [ ] $5,000+/month revenue for ZeroDB from Chatwoot users

---

## Team Assignments

### Recommended Team Structure

| Role | Responsibilities | Stories |
|------|-----------------|---------|
| **Tech Lead** | Architecture, code review, ZeroDB integration | All stories (reviewer) |
| **Backend Dev 1** | Database migration, semantic search, memory | Epic 1, Story 2.1-2.2, Epic 4 |
| **Backend Dev 2** | Smart suggestions, RLHF, similar tickets | Epic 3, Epic 5 |
| **Frontend Dev** | All Vue.js components and UI | Stories 2.4, 3.2, 4.2, 5.2 |
| **DevOps** | Infrastructure, deployment, monitoring | Story 1.1, monitoring setup |
| **QA** | Testing, documentation, validation | All testing tasks |

---

## Next Steps

### This Week (Week of Dec 16)

1. **Project Setup**
   - [ ] Fork Chatwoot to AINative-Studio/chatwoot-zerodb
   - [ ] Create ZeroDB account and project
   - [ ] Set up development environment
   - [ ] Create GitHub project board with all stories

2. **Team Kickoff**
   - [ ] Review master plan with team
   - [ ] Assign stories to developers
   - [ ] Set up Slack/Discord for communication
   - [ ] Schedule daily standups

3. **Begin Epic 1**
   - [ ] Start Story 1.1 (DevOps)
   - [ ] Start Story 1.2 (Backend Dev 1)
   - [ ] Prepare for data migration

---

## References

- [Master Plan](planning/CHATWOOT_ZERODB_FORK_MASTER_PLAN.md) - Complete project overview
- [Integration Plan](planning/CHATWOOT_ZERODB_INTEGRATION_PLAN.md) - Technical integration details
- [ZeroDB Developer Guide](/Users/aideveloper/core/docs/Zero-DB/ZeroDB_Public_Developer_Guide.md)
- [Chatwoot Architecture](/Users/aideveloper/core/docs/architecture/CHATWOOT_ARCHITECTURE_ANALYSIS.md)

---

**Document Version:** 1.0
**Last Updated:** December 16, 2025
**Status:** Ready for Development
**Total Story Points:** 89
**Estimated Duration:** 12 weeks
