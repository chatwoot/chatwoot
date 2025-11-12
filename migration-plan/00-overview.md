# Chatwoot Rails to TypeScript Migration - Executive Overview

## Project Scope

**Objective**: Complete migration of Chatwoot from Ruby on Rails to TypeScript/Node.js while maintaining 100% feature parity, test coverage, and operational stability.

## Codebase Statistics

| Component | Count/Size |
|-----------|-----------|
| Ruby Files (app/) | 614 files |
| Ruby Files (lib/) | 70 files |
| Vue Components | 973 files |
| Controllers | 145 classes |
| Models | 58 classes |
| Model Associations | 226 relationships |
| Background Jobs | 69 jobs |
| Service Classes | 140 files (42 categories) |
| Integration Files | 189 files |
| RSpec Tests | 618 test files |
| Total Size (app/) | 34MB |
| Total Size (spec/) | 36MB |

## Technology Stack

### Current (Ruby/Rails)
- **Framework**: Rails 7.1
- **Language**: Ruby 3.4.4
- **Database**: PostgreSQL with pgvector
- **Cache/Jobs**: Redis + Sidekiq
- **Real-time**: ActionCable
- **Frontend**: Vue 3 + Vite
- **Testing**: RSpec

### Target (TypeScript/Node.js)
- **Framework**: NestJS or Express with TypeScript
- **Language**: TypeScript 5.x
- **Database**: PostgreSQL with TypeORM/Prisma
- **Cache/Jobs**: Redis + Bull/BullMQ
- **Real-time**: Socket.io or native WebSockets
- **Frontend**: Vue 3 + Vite (preserve)
- **Testing**: Vitest/Jest

## Key Subsystems

1. **Authentication & Authorization**
   - Devise-based authentication
   - JWT token management
   - Two-factor authentication (2FA)
   - OAuth integrations (Google, Microsoft)
   - Pundit for authorization

2. **Multi-Channel Communication**
   - Facebook Messenger
   - Instagram
   - WhatsApp
   - Slack
   - Telegram
   - Line
   - Twitter/X
   - SMS (Twilio)
   - Email (SMTP/IMAP)

3. **AI & ML Features**
   - OpenAI integration
   - Dialogflow (Google)
   - Vector search (pgvector)
   - Response bots

4. **Real-time Features**
   - ActionCable channels
   - WebSocket connections
   - Live updates
   - Presence tracking

5. **Background Processing**
   - 69 Sidekiq jobs
   - Scheduled cron jobs
   - Email processing
   - Webhook delivery
   - Integration syncs

6. **Enterprise Features**
   - Multi-tenancy (Accounts)
   - RBAC (Role-Based Access Control)
   - Audit logging
   - Advanced reporting
   - Subscription/billing (Stripe)

## Migration Strategy

### Approach: Fine-Grained Incremental Migration

Given the complexity and size, we'll use a **fine-grained epic structure** with:
- 11 major epics
- 50+ sub-tasks
- Parallel execution opportunities
- Feature flagging for gradual rollout
- Dual-running capability (Rails + TypeScript side-by-side)

### Epic Breakdown (High-Level)

1. **Epic 01**: Discovery & Infrastructure Setup
2. **Epic 02**: Test Infrastructure & CI/CD
3. **Epic 03**: Database Models & Migrations
4. **Epic 04**: API Controllers & Routes
5. **Epic 05**: Authentication & Authorization System
6. **Epic 06**: Background Jobs & Queue System
7. **Epic 07**: Third-Party Integrations
8. **Epic 08**: Real-time Features (WebSockets)
9. **Epic 09**: Frontend Adaptation
10. **Epic 10**: AI/ML Features
11. **Epic 11**: Deployment & Cutover

## Success Criteria

- ✅ 100% feature parity
- ✅ 100% test coverage maintained
- ✅ Performance equal or better than Rails
- ✅ All integrations functional
- ✅ Zero downtime deployment
- ✅ Complete documentation
- ✅ Team knowledge transfer

## Timeline Estimate

- **Discovery & Planning**: 1 week (CURRENT)
- **Infrastructure Setup**: 1-2 weeks
- **Core Backend Migration**: 8-12 weeks
- **Integration Migration**: 4-6 weeks
- **Real-time Features**: 2-3 weeks
- **Frontend Adaptation**: 2-3 weeks
- **Testing & QA**: 3-4 weeks
- **Deployment & Cutover**: 1-2 weeks

**Total Estimated Duration**: 22-33 weeks (5-8 months)

## Risk Assessment

### High Risk Areas
- Authentication system (security-critical)
- Payment processing (Stripe integration)
- Real-time WebSocket features
- Multi-channel integrations (breaking changes)
- Database migrations (data integrity)

### Mitigation Strategies
- TDD for all components
- Feature flags for gradual rollout
- Comprehensive integration tests
- Staging environment validation
- Rollback plans for each epic
- Blue-green deployment strategy

## Dependencies & Constraints

- Must maintain backward compatibility during migration
- Cannot break existing API contracts
- Must support existing Vue 3 frontend
- Database schema must remain compatible
- Third-party integrations must not be disrupted

## Resource Requirements

- **Senior Backend Engineer**: 1 FTE (TypeScript/Node.js expert)
- **Backend Engineer**: 2 FTE (Rails + TypeScript knowledge)
- **Frontend Engineer**: 1 FTE (Vue 3 expertise)
- **QA Engineer**: 1 FTE (test automation)
- **DevOps Engineer**: 0.5 FTE (CI/CD, infrastructure)

---

**Status**: Phase 1 - Discovery Complete
**Next Steps**: Create detailed epic plans and begin Epic 01
