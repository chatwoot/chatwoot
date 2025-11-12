# Chatwoot Rails to TypeScript Migration Plan

**Status**: ✅ Phase 1 Complete - Ready for Execution
**Version**: 1.0
**Date**: 2025-11-12
**Owner**: Engineering Team

---

## 📋 Quick Navigation

- [Executive Overview](./00-overview.md) - High-level project summary
- [Discovery Findings](./01-discovery-findings.md) - Detailed codebase analysis
- [Migration Strategy](./02-migration-strategy.md) - Approach and methodology
- [Testing & Security Standards](./03-testing-cicd-security.md) - Quality requirements
- [Progress Tracker](./progress-tracker.md) - Live migration status
- [Epic Plans](./epics/) - Detailed task breakdowns

---

## 🎯 Project Objectives

**Mission**: Migrate Chatwoot from Ruby on Rails to TypeScript/Node.js while maintaining 100% feature parity, zero downtime, and comprehensive test coverage.

### Success Criteria

✅ **Functional**
- 100% feature parity with Rails
- All 58 models migrated
- All 145 controllers migrated
- All 69 background jobs migrated
- All 14 integrations functional
- 973 Vue components adapted

✅ **Quality**
- Test coverage ≥90%
- ESLint passes (zero warnings)
- TypeScript strict mode
- Security audit passed

✅ **Performance**
- API response times ≤ Rails baseline
- Background job throughput ≥ Sidekiq
- WebSocket capacity ≥ ActionCable
- Database query performance maintained

✅ **Operational**
- Zero downtime deployment
- Blue-green cutover successful
- Rollback procedures tested
- Monitoring operational
- Documentation complete

---

## 📊 Project Scope

### Codebase Size

| Component | Quantity |
|-----------|----------|
| Ruby files to migrate | 684 files (614 app/ + 70 lib/) |
| Models | 58 classes |
| Controllers | 145 classes |
| Services | 140 files |
| Background Jobs | 69 jobs |
| Integrations | 14 services |
| Vue Components | 973 files (adaptation needed) |
| RSpec Tests | 618 files |
| Database Tables | 58 tables |
| Model Associations | 226 relationships |

### Technology Stack

**Current (Rails)**
- Ruby 3.4.4
- Rails 7.1
- ActiveRecord
- Sidekiq
- ActionCable
- RSpec

**Target (TypeScript)**
- Node.js 23.x
- NestJS
- TypeORM
- BullMQ
- Socket.io
- Vitest

---

## 🗺️ Migration Roadmap

### Phase 1: Discovery & Planning ✅ **COMPLETE**
- **Duration**: Week 1
- **Status**: ✅ Done
- **Deliverables**:
  - ✅ Codebase analysis (684 files analyzed)
  - ✅ Discovery findings documented
  - ✅ Migration strategy defined
  - ✅ Epic breakdown created
  - ✅ Testing standards established
  - ✅ Progress tracker set up

### Phase 2: Foundation (Weeks 2-4)
- **Epics**: 01, 02
- **Status**: 🟡 Ready to Start
- **Key Deliverables**:
  - TypeScript project structure
  - NestJS framework setup
  - Test infrastructure (Vitest)
  - CI/CD pipeline
  - Database connection
  - Redis connection

### Phase 3: Core Backend (Weeks 5-12)
- **Epics**: 03, 04, 06
- **Status**: 🟡 Not Started
- **Key Deliverables**:
  - 58 database models
  - 145 API controllers
  - 69 background jobs
  - Request validation
  - Response serialization

### Phase 4: Features (Weeks 13-20)
- **Epics**: 05, 07, 08, 10
- **Status**: 🟡 Not Started
- **Key Deliverables**:
  - Authentication system
  - 14 integrations
  - Real-time WebSocket features
  - AI/ML capabilities

### Phase 5: Integration (Weeks 21-25)
- **Epics**: 09
- **Status**: 🟡 Not Started
- **Key Deliverables**:
  - Frontend API adaptation
  - 973 Vue components updated
  - WebSocket client migration

### Phase 6: Cutover (Weeks 26-28)
- **Epics**: 11
- **Status**: 🟡 Not Started
- **Key Deliverables**:
  - Deployment automation
  - Blue-green setup
  - Traffic migration (0% → 100%)
  - Rails decommission

---

## 📚 Epic Overview

### Epic 01: Infrastructure Setup
- **Duration**: 1-2 weeks
- **Tasks**: 12 tasks
- **Status**: 🟡 Ready
- **Description**: NestJS project, TypeScript, ESLint, database/Redis connections
- **[Detailed Plan →](./epics/epic-01-infrastructure-setup.md)**

### Epic 02: Test Infrastructure & CI/CD
- **Duration**: 1-2 weeks
- **Tasks**: 8 tasks
- **Status**: 🟡 Ready (after Epic 01)
- **Description**: Vitest, factories, Supertest, CI pipeline, pre-commit hooks
- **[Detailed Plan →](./epics/epic-02-test-infrastructure.md)**

### Epic 03: Database Models & Migrations
- **Duration**: 3-4 weeks
- **Tasks**: 58 models + tests
- **Status**: 🟡 Ready (after Epic 02)
- **Description**: Migrate all ActiveRecord models to TypeORM entities
- **[Detailed Plan →](./epics/epic-03-database-models/)**

### Epic 04: API Controllers & Routes
- **Duration**: 4-5 weeks
- **Tasks**: 145 controllers + tests
- **Status**: 🟡 Not Started
- **Description**: Migrate all Rails controllers to NestJS controllers
- **[Detailed Plan →](./epics/epic-04-controllers/)**

### Epic 05: Authentication & Authorization
- **Duration**: 2-3 weeks
- **Tasks**: 15 tasks
- **Status**: 🟡 Not Started
- **Description**: JWT, OAuth, 2FA, RBAC policies
- **[Plan TBD]**

### Epic 06: Background Jobs & Queue System
- **Duration**: 3-4 weeks
- **Tasks**: 69 jobs + tests
- **Status**: 🟡 Not Started
- **Description**: Migrate Sidekiq jobs to BullMQ
- **[Plan TBD]**

### Epic 07: Third-Party Integrations
- **Duration**: 4-6 weeks
- **Tasks**: 14 integrations
- **Status**: 🟡 Not Started
- **Description**: Facebook, WhatsApp, Slack, Stripe, Dialogflow, etc.
- **[Detailed Plan →](./epics/epic-07-integrations/)**

### Epic 08: Real-Time Features (WebSockets)
- **Duration**: 2-3 weeks
- **Tasks**: 10 tasks
- **Status**: 🟡 Not Started
- **Description**: Migrate ActionCable to Socket.io
- **[Plan TBD]**

### Epic 09: Frontend Adaptation
- **Duration**: 2-3 weeks
- **Tasks**: API client updates
- **Status**: 🟡 Not Started
- **Description**: Update Vue.js frontend to use TypeScript API
- **[Plan TBD]**

### Epic 10: AI/ML Features
- **Duration**: 2-3 weeks
- **Tasks**: 8 tasks
- **Status**: 🟡 Not Started
- **Description**: Vector search, OpenAI, Dialogflow, agent bots
- **[Plan TBD]**

### Epic 11: Deployment & Cutover
- **Duration**: 1-2 weeks
- **Tasks**: 15 tasks
- **Status**: 🟡 Not Started
- **Description**: Blue-green deployment, traffic migration, validation
- **[Plan TBD]**

---

## 🎯 Guiding Principles

### 1. Test-Driven Development (TDD)
**Every task follows:**
1. Read original Rails code
2. Write TypeScript tests first (Red)
3. Implement TypeScript code (Green)
4. Refactor (Refactor)
5. Verify feature parity
6. Commit

**No exceptions.** Code without tests will not be merged.

### 2. Incremental Migration
- Small, testable increments
- Feature flags for gradual rollout
- Dual-running capability (Rails + TypeScript)
- Easy rollback for each epic

### 3. Zero Downtime
- Blue-green deployment
- Traffic shifting (0% → 5% → 25% → 50% → 100%)
- Instant rollback via feature flags
- Continuous validation

### 4. Quality Standards
- **Test Coverage**: ≥90%
- **TypeScript**: Strict mode, no `any` without justification
- **Linting**: ESLint passes (zero warnings)
- **Security**: All OWASP top 10 addressed
- **Performance**: Match or exceed Rails baseline

### 5. Documentation First
- Document before implementing
- Update docs with code
- Comprehensive API documentation
- Runbooks for operations

---

## ⚠️ Risk Management

### High-Risk Areas

| Area | Risk Level | Mitigation |
|------|-----------|------------|
| Authentication | 🔴 Very High | Extra testing, security audit, staged rollout |
| Payment Processing | 🔴 Very High | Sandbox testing, manual validation |
| Real-time (WebSockets) | 🟡 High | Load testing, connection pool management |
| Multi-channel integrations | 🟡 High | Per-integration feature flags, webhook replay |
| Database integrity | 🟡 High | Transactions, constraints, backups |

### Rollback Strategy

**Per Epic:**
- Feature flag → instant rollback
- Database migrations → reversible
- Code deployments → blue-green

**Emergency Rollback:**
1. Flip all feature flags to Rails
2. Route all traffic to Rails instances
3. Investigate TypeScript issues offline
4. **Time to rollback**: < 5 minutes

---

## 📈 Progress Tracking

**Live progress**: See [progress-tracker.md](./progress-tracker.md)

**Current Status:**
- Overall Progress: **5%** (Planning complete)
- Epics Complete: **0 / 11**
- Models Migrated: **0 / 58**
- Controllers Migrated: **0 / 145**
- Tests Written: **0 / 618+**

**Weekly Updates**: Updated every Friday in progress-tracker.md

---

## 🔧 Development Workflow

### Starting a New Task

1. **Read the epic plan** for the task
2. **Create a new branch**: `git checkout -b feature/epic-01-task-01`
3. **Read original Rails code** and tests
4. **Write TypeScript tests first** (TDD: Red)
5. **Implement TypeScript code** (TDD: Green)
6. **Refactor** (TDD: Refactor)
7. **Run tests**: `pnpm test`
8. **Run linter**: `pnpm lint:fix`
9. **Verify feature parity**
10. **Update progress tracker**
11. **Commit**: `git commit -m "feat(epic-01): complete task 01 - setup NestJS project"`
12. **Push**: `git push -u origin feature/epic-01-task-01`
13. **Create PR**

### Definition of Done (DoD)

A task is ONLY complete when:
- ✅ Tests written (TDD)
- ✅ All tests passing
- ✅ Code coverage ≥90%
- ✅ ESLint passing (zero errors/warnings)
- ✅ TypeScript strict mode passing
- ✅ Code reviewed
- ✅ Documentation updated
- ✅ Feature flag configured (if applicable)
- ✅ Progress tracker updated
- ✅ Committed with clear message

---

## 👥 Team Structure

### Recommended Team Composition

- **1 Senior Backend Engineer** (TypeScript/Node.js expert)
- **2 Backend Engineers** (Rails + TypeScript)
- **1 Frontend Engineer** (Vue.js expert)
- **1 QA Engineer** (Test automation)
- **0.5 DevOps Engineer** (CI/CD, infrastructure)

### Parallel Work Opportunities

- **Phase 3**: Database models can be split across 3 teams
- **Phase 3**: API controllers can be split by version (v1, v2, public)
- **Phase 4**: Integrations can be done independently
- **Phase 5**: Frontend modules can be done independently

---

## 📞 Support & Communication

### Documentation
- **Primary Docs**: This folder (`migration-plan/`)
- **API Docs**: Auto-generated (Swagger/OpenAPI)
- **Architecture Decisions**: `ARCHITECTURE.md` (to be created)

### Questions & Issues
- **Epic Questions**: Comment in epic markdown file
- **Technical Blockers**: Raise in daily standup
- **Architecture Decisions**: Discuss with tech lead

### Daily Standup
- **What did I complete yesterday?**
- **What am I working on today?**
- **Any blockers?**
- **Progress tracker updated?**

---

## 🚀 Getting Started

### For New Team Members

1. **Read this README** (you're here!)
2. **Read [00-overview.md](./00-overview.md)**
3. **Read [01-discovery-findings.md](./01-discovery-findings.md)**
4. **Read [02-migration-strategy.md](./02-migration-strategy.md)**
5. **Read [03-testing-cicd-security.md](./03-testing-cicd-security.md)**
6. **Pick an epic** from [progress-tracker.md](./progress-tracker.md)
7. **Read the epic plan** (in `epics/` folder)
8. **Start with Epic 01** if all are available

### Prerequisites

- Node.js 23.x
- pnpm 10.x
- PostgreSQL 16
- Redis 7
- Git
- Understanding of Rails (to read original code)
- TypeScript experience

---

## 📚 Additional Resources

### External Documentation
- [NestJS Docs](https://docs.nestjs.com/)
- [TypeORM Docs](https://typeorm.io/)
- [Vitest Docs](https://vitest.dev/)
- [BullMQ Docs](https://docs.bullmq.io/)
- [Socket.io Docs](https://socket.io/docs/)

### Chatwoot Resources
- [Chatwoot GitHub](https://github.com/chatwoot/chatwoot)
- [Chatwoot Docs](https://www.chatwoot.com/docs)
- [Chatwoot API Docs](https://www.chatwoot.com/developers/api)

---

## 📝 Changelog

### v1.0 (2025-11-12)
- ✅ Initial discovery complete
- ✅ Strategy documented
- ✅ Epic 01, 02, 03 detailed plans created
- ✅ Testing standards established
- ✅ Progress tracker initialized

---

## 🎬 Next Steps

### Immediate (Week 2)
1. ✅ **Review and approve this plan** with team
2. ⬜ **Begin Epic 01**: Infrastructure Setup
3. ⬜ **Set up TypeScript project**
4. ⬜ **Configure tooling** (ESLint, Prettier, etc.)

### Short-term (Weeks 2-4)
1. ⬜ Complete Epic 01
2. ⬜ Complete Epic 02
3. ⬜ Begin Epic 03 (Database Models)

### Medium-term (Weeks 5-12)
1. ⬜ Complete Epic 03
2. ⬜ Complete Epic 04 (API Controllers)
3. ⬜ Begin Epic 05 (Authentication)

---

## ✅ Sign-off

**Planning Phase Complete**: ✅

**Approved By:**
- [ ] Tech Lead
- [ ] Engineering Manager
- [ ] Product Manager
- [ ] DevOps Lead

**Ready for Execution**: ⬜ Pending approval

---

**Last Updated**: 2025-11-12
**Next Review**: 2025-11-19 (weekly)
**Questions?** Open an issue or contact the tech lead.

---

**Let's build something great! 🚀**
