# Migration Strategy - Rails to TypeScript

## Strategic Approach

### Chosen Strategy: Fine-Grained Incremental Migration with Dual-Running

Given Chatwoot's complexity (684 Ruby files, 58 models, 145 controllers, 9+ integrations), we'll use a **fine-grained epic structure** with **parallel execution opportunities** and **feature flagging** for gradual rollout.

### Why This Approach?

1. **Minimize Risk**: Smaller, testable increments reduce blast radius
2. **Enable Parallelization**: Multiple epics can progress simultaneously
3. **Maintain Velocity**: Team can continue feature development
4. **Easy Rollback**: Each epic is independently revertible
5. **Continuous Validation**: Tests run after each task
6. **Business Continuity**: Zero downtime during migration

---

## Epic Breakdown (Fine-Grained)

### Epic 01: Discovery & Infrastructure Setup
**Duration**: 1-2 weeks
**Complexity**: Medium
**Dependencies**: None
**Parallel**: N/A (must complete first)

**Scope:**
- Project structure
- TypeScript configuration
- Build tooling (esbuild/vite)
- Linting (ESLint + Prettier)
- Package management
- Environment configuration

**Risk**: Low

---

### Epic 02: Test Infrastructure & CI/CD
**Duration**: 1-2 weeks
**Complexity**: Medium
**Dependencies**: Epic 01
**Parallel**: N/A

**Scope:**
- Vitest/Jest setup
- Test utilities and helpers
- Factory setup (equivalent to FactoryBot)
- Database test setup
- CI/CD pipeline configuration
- Coverage reporting

**Risk**: Low

---

### Epic 03: Database Models & Migrations
**Duration**: 3-4 weeks
**Complexity**: High
**Dependencies**: Epic 01, Epic 02
**Parallel**: Can split into sub-groups

**Sub-Epics:**
- **3.1**: Core Models (User, Account, Conversation, Message)
- **3.2**: Channel Models (9 channel types)
- **3.3**: Integration Models (Slack, Dialogflow, etc.)
- **3.4**: Supporting Models (Label, Tag, CustomAttribute, etc.)

**Scope:**
- TypeORM/Prisma schemas
- Model associations
- Validations
- Scopes and query methods
- Database migrations
- Seed data

**Risk**: High (data integrity critical)

**Parallel Opportunities:**
- User/Account models (Team A)
- Conversation/Message models (Team B)
- Channel models (Team C)

---

### Epic 04: API Controllers & Routes
**Duration**: 4-5 weeks
**Complexity**: Very High
**Dependencies**: Epic 03 (models complete)
**Parallel**: Yes (by API version)

**Sub-Epics:**
- **4.1**: API v1 Controllers (primary)
- **4.2**: API v2 Controllers (newer)
- **4.3**: Public API Controllers
- **4.4**: Internal/Admin Controllers
- **4.5**: Webhook Controllers

**Scope:**
- NestJS controllers (or Express routers)
- Request validation (DTOs)
- Response serialization
- Error handling
- Pagination
- Filtering/searching

**Risk**: High (API contract must match)

**Parallel Opportunities:**
- v1 API (Team A)
- v2 API (Team B)
- Public/Webhook APIs (Team C)

---

### Epic 05: Authentication & Authorization System
**Duration**: 2-3 weeks
**Complexity**: Very High
**Dependencies**: Epic 03 (User model), Epic 04 (Auth controllers)
**Parallel**: No (security-critical, must be thorough)

**Scope:**
- JWT token management
- Passport strategies (or custom)
- Session handling
- Password hashing (bcrypt)
- Two-factor authentication (TOTP)
- OAuth integrations (Google, Microsoft)
- SAML support
- Authorization policies (Pundit → CASL or custom)
- Role-based access control

**Risk**: Very High (security implications)

**Testing Requirements:**
- 100% coverage
- Penetration testing
- OAuth flow validation

---

### Epic 06: Background Jobs & Queue System
**Duration**: 3-4 weeks
**Complexity**: High
**Dependencies**: Epic 03 (models)
**Parallel**: Yes (by job category)

**Sub-Epics:**
- **6.1**: Job Infrastructure (Bull/BullMQ setup)
- **6.2**: Account & Agent Jobs
- **6.3**: Campaign & Notification Jobs
- **6.4**: Channel Sync Jobs
- **6.5**: Webhook Delivery Jobs
- **6.6**: CRM Integration Jobs
- **6.7**: Scheduled/Cron Jobs

**Scope:**
- Migrate 69 Sidekiq jobs to Bull/BullMQ
- Job queues and priorities
- Retry logic
- Error handling
- Job scheduling (cron)
- Job monitoring/UI

**Risk**: Medium (standard patterns)

**Parallel Opportunities:**
- Notification jobs (Team A)
- Channel jobs (Team B)
- Webhook jobs (Team C)

---

### Epic 07: Third-Party Integrations
**Duration**: 4-6 weeks
**Complexity**: Very High
**Dependencies**: Epic 03, Epic 06 (for async jobs)
**Parallel**: Yes (each integration independent)

**Sub-Epics:**
- **7.1**: Facebook Messenger Integration
- **7.2**: Instagram Integration
- **7.3**: WhatsApp Integration
- **7.4**: Slack Integration
- **7.5**: Telegram Integration
- **7.6**: Line Integration
- **7.7**: Twitter/X Integration
- **7.8**: Twilio (SMS) Integration
- **7.9**: Email (SMTP/IMAP) Integration
- **7.10**: Dialogflow Integration
- **7.11**: OpenAI Integration
- **7.12**: Stripe Integration
- **7.13**: Shopify Integration
- **7.14**: Other Integrations (Linear, Notion, etc.)

**Scope:**
- API clients for each service
- Webhook receivers
- Event handlers
- Message formatters/parsers
- Rate limiting
- Error recovery

**Risk**: High (third-party dependencies, rate limits)

**Parallel Opportunities:**
- Messaging integrations (Team A)
- Business integrations (Team B)
- AI integrations (Team C)

---

### Epic 08: Real-Time Features (WebSockets)
**Duration**: 2-3 weeks
**Complexity**: High
**Dependencies**: Epic 03, Epic 04
**Parallel**: No (infrastructure is shared)

**Scope:**
- Socket.io or native WebSocket server
- Connection management
- Room/channel management
- Presence tracking
- Typing indicators
- Live updates
- Broadcast system
- Event listeners (migrate 12 Wisper listeners)

**Risk**: High (state management, concurrency)

---

### Epic 09: Frontend Adaptation
**Duration**: 2-3 weeks
**Complexity**: Medium
**Dependencies**: Epic 04 (API changes)
**Parallel**: Yes (by module)

**Sub-Epics:**
- **9.1**: API Client Updates
- **9.2**: WebSocket Client Updates
- **9.3**: Authentication Flow Updates
- **9.4**: Component Updates (if needed)
- **9.5**: Store/State Updates
- **9.6**: i18n Updates

**Scope:**
- Update Axios clients to match new API
- Update ActionCable → Socket.io client
- Update authentication flows
- Update any backend-dependent components
- Test all user flows

**Risk**: Medium (well-defined interface)

**Parallel Opportunities:**
- Dashboard (Team A)
- Widget (Team B)
- Portal/Survey (Team C)

---

### Epic 10: AI/ML Features
**Duration**: 2-3 weeks
**Complexity**: High
**Dependencies**: Epic 03, Epic 07 (OpenAI, Dialogflow)
**Parallel**: Partially (different AI features)

**Scope:**
- Vector search (pgvector)
- OpenAI GPT integration
- Response generation
- Content summarization
- Dialogflow intent handling
- Agent bots
- LLM formatting

**Risk**: Medium (external API dependencies)

---

### Epic 11: Deployment & Cutover
**Duration**: 1-2 weeks
**Complexity**: High
**Dependencies**: All previous epics
**Parallel**: No

**Scope:**
- Deployment scripts
- Environment configuration
- Database migration scripts
- Feature flag management
- Monitoring setup
- Health checks
- Load testing
- Rollback procedures
- Blue-green deployment
- Traffic switching
- Decommission Rails app

**Risk**: High (production impact)

---

## Dependency Matrix

| Epic | Depends On | Can Run Parallel With |
|------|-----------|----------------------|
| 01   | None      | N/A |
| 02   | 01        | N/A |
| 03   | 01, 02    | Split into sub-epics |
| 04   | 03        | Split by API version |
| 05   | 03, 04    | No (security-critical) |
| 06   | 03        | Split by job category |
| 07   | 03, 06    | Each integration independent |
| 08   | 03, 04    | No (shared infrastructure) |
| 09   | 04        | Split by module |
| 10   | 03, 07    | Partial |
| 11   | All       | No |

---

## Migration Techniques

### 1. Dual-Running Architecture

**Strategy**: Run Rails and TypeScript side-by-side during migration

**Implementation:**
- Feature flags to route traffic
- Shared database (read/write from both)
- Dual-write for critical data
- API gateway to route requests
- Gradual traffic shifting

**Rollback:** Instant (flip feature flag)

### 2. Test-Driven Development (TDD)

**Process for Each Task:**
1. Read original Ruby code + RSpec tests
2. Write TypeScript tests first (Red)
3. Implement TypeScript code (Green)
4. Refactor (Refactor)
5. Verify feature parity
6. Commit

**Coverage Target:** 100% (match or exceed RSpec)

### 3. API Contract Testing

**Approach:**
- Document existing Rails API responses
- Create integration tests
- Ensure TypeScript API matches exactly
- Use contract testing tools (Pact, etc.)

### 4. Feature Flagging

**Tools:** LaunchDarkly, Unleash, or custom

**Flags:**
- `use_typescript_auth` (Epic 05)
- `use_typescript_api_v1` (Epic 04)
- `use_typescript_websocket` (Epic 08)
- `use_typescript_[integration]` (Epic 07)

**Rollout Strategy:**
- 0% → Internal testing
- 5% → Beta users
- 25% → Early adopters
- 50% → Half traffic
- 100% → Full cutover

### 5. Data Migration Strategy

**Approach:** Schema compatibility

**Process:**
- TypeScript uses existing PostgreSQL schema
- No data migration required (same DB)
- Dual-write to ensure consistency
- Eventually decommission Rails

**Constraints:**
- Cannot change column names during migration
- Cannot change data types during migration
- Can add new columns/tables for TypeScript-specific needs

---

## Risk Mitigation

### High-Risk Areas

| Area | Risk Level | Mitigation |
|------|-----------|------------|
| Authentication | Very High | Extra testing, security audit, staged rollout |
| Payment (Stripe) | Very High | Sandbox testing, manual validation, delayed rollout |
| Real-time (WebSockets) | High | Load testing, connection pool management, fallback |
| Multi-channel integrations | High | Per-integration feature flags, webhook replay |
| Database integrity | High | Transactions, constraints, validation, backups |

### Rollback Plans

**Per Epic:**
- Feature flag → instant rollback
- Database migrations → reversible
- Code deployments → blue-green
- Traffic routing → gradual shift

**Emergency Rollback:**
- Flip all feature flags to Rails
- Route all traffic to Rails instances
- Investigate TypeScript issues offline

---

## Parallelization Strategy

### Phase 1: Foundation (Weeks 1-4)
- **Sequential**: Epics 01 → 02 → 03
- **Team Size**: 2-3 engineers

### Phase 2: Core Backend (Weeks 5-12)
- **Parallel**:
  - Team A: Epic 04.1 (API v1)
  - Team B: Epic 04.2 (API v2)
  - Team C: Epic 06 (Background Jobs)
- **Team Size**: 3-4 engineers

### Phase 3: Features (Weeks 13-20)
- **Parallel**:
  - Team A: Epic 07 (Messaging integrations)
  - Team B: Epic 08 (Real-time)
  - Team C: Epic 05 (Auth) → Epic 10 (AI)
- **Team Size**: 3-4 engineers

### Phase 4: Integration (Weeks 21-25)
- **Parallel**:
  - Team A: Epic 09 (Frontend)
  - Team B: Epic 07 (Remaining integrations)
  - Team C: Epic 11 prep (Deployment)
- **Team Size**: 3-4 engineers

### Phase 5: Cutover (Weeks 26-28)
- **Sequential**: Epic 11
- **Team Size**: Full team (all hands on deck)

---

## Technology Stack Decisions

### Backend Framework: **NestJS**

**Why NestJS:**
- TypeScript-first
- Decorators (similar to Rails)
- Modular architecture
- Built-in DI container
- Great for large applications
- Good documentation
- Active community

**Alternative:** Express + TypeScript (more manual setup)

### ORM: **TypeORM**

**Why TypeORM:**
- TypeScript decorators
- Migration support
- Similar to ActiveRecord
- PostgreSQL-optimized
- Supports transactions

**Alternative:** Prisma (better DX, but different patterns)

### Background Jobs: **BullMQ**

**Why BullMQ:**
- Redis-based (like Sidekiq)
- Job priorities
- Retry logic
- Cron jobs
- UI dashboard
- TypeScript support

**Alternative:** Bee-Queue (simpler, less features)

### WebSockets: **Socket.io**

**Why Socket.io:**
- Rooms/namespaces
- Fallback support
- Client libraries
- Wide adoption
- Good performance

**Alternative:** Native WebSocket (more manual)

### Validation: **class-validator**

**Why class-validator:**
- Decorator-based
- Works with NestJS
- Similar to ActiveModel validations

### Testing: **Vitest + Supertest**

**Why Vitest:**
- Fast (Vite-powered)
- Jest-compatible
- Native TypeScript
- ESM support

**Supertest:** HTTP integration testing

---

## Success Metrics

### Code Quality
- ✅ 100% TypeScript (no `any` types without justification)
- ✅ ESLint passing (zero warnings)
- ✅ Prettier formatted
- ✅ Test coverage ≥ current Rails coverage

### Performance
- ✅ API response times ≤ Rails
- ✅ Background job processing ≥ Sidekiq throughput
- ✅ WebSocket connection capacity ≥ ActionCable

### Reliability
- ✅ Zero data loss
- ✅ Zero downtime deployment
- ✅ All integrations functional
- ✅ Error rates ≤ Rails baseline

### Feature Parity
- ✅ 100% of Rails features migrated
- ✅ All API endpoints functional
- ✅ All background jobs running
- ✅ All integrations working

---

## Timeline & Milestones

### Month 1: Foundation
- ✅ Week 1: Discovery (COMPLETE)
- ⬜ Week 2-3: Epic 01 (Infrastructure)
- ⬜ Week 4: Epic 02 (Test Infrastructure)

### Month 2-3: Database & API
- ⬜ Week 5-7: Epic 03 (Database Models)
- ⬜ Week 8-12: Epic 04 (API Controllers)

### Month 4: Jobs & Auth
- ⬜ Week 13-15: Epic 06 (Background Jobs)
- ⬜ Week 16-18: Epic 05 (Authentication)

### Month 5-6: Integrations & Real-time
- ⬜ Week 19-24: Epic 07 (Integrations)
- ⬜ Week 22-24: Epic 08 (Real-time)

### Month 7: AI & Frontend
- ⬜ Week 25-27: Epic 10 (AI/ML)
- ⬜ Week 28-30: Epic 09 (Frontend)

### Month 8: Deployment
- ⬜ Week 31-32: Epic 11 (Cutover)
- ⬜ Week 33-34: Monitoring & Stabilization

---

## Next Steps

1. ✅ Discovery complete
2. ✅ Strategy documented
3. ⬜ Create detailed epic plans (next)
4. ⬜ Begin Epic 01: Infrastructure Setup

---

**Strategy Status**: ✅ Complete
**Approval Required**: Yes (before execution)
**Estimated Total Duration**: 32-34 weeks (~8 months)
