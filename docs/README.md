# Chatwoot-ZeroDB Fork Documentation

**Project:** Chatwoot-ZeroDB Integration
**Status:** Planning Phase → Ready for Development
**Last Updated:** December 16, 2025

---

## Overview

This directory contains all planning and technical documentation for the Chatwoot-ZeroDB fork project. The goal is to create a lightweight fork of Chatwoot enhanced with ZeroDB's AI-native database capabilities.

---

## Documentation Structure

### 📋 Planning Documents

1. **[backlog/BACKLOG_CHATWOOT_ZERODB.md](backlog/BACKLOG_CHATWOOT_ZERODB.md)** - Development Backlog
   - **Purpose:** Complete backlog of all development tasks
   - **Audience:** Development team
   - **Contents:** 89 story points across 7 epics, 12-week timeline
   - **Use:** Daily development planning and sprint tracking

2. **[planning/CHATWOOT_ZERODB_FORK_MASTER_PLAN.md](planning/CHATWOOT_ZERODB_FORK_MASTER_PLAN.md)** - Master Plan
   - **Purpose:** High-level strategic plan and vision
   - **Audience:** Stakeholders, team leads, investors
   - **Contents:**
     - Executive summary and goals
     - Complete architecture design
     - 5-phase implementation plan
     - Cost analysis and ROI projections
     - Risk mitigation strategies
   - **Use:** Project overview and decision-making reference

3. **[planning/CHATWOOT_ZERODB_INTEGRATION_PLAN.md](planning/CHATWOOT_ZERODB_INTEGRATION_PLAN.md)** - Integration Plan
   - **Purpose:** Detailed technical integration specifications
   - **Audience:** Backend developers, architects
   - **Contents:**
     - ZeroDB API integration details
     - Database migration procedures
     - Service layer architecture
     - API endpoint specifications
   - **Use:** Technical implementation reference

---

## Quick Start for Developers

### 1. Read the Master Plan First
Start with `planning/CHATWOOT_ZERODB_FORK_MASTER_PLAN.md` to understand:
- What we're building and why
- Strategic goals and success metrics
- Overall architecture

### 2. Review the Backlog
Open `backlog/BACKLOG_CHATWOOT_ZERODB.md` to see:
- All development tasks organized by epic
- Story points and time estimates
- Acceptance criteria for each task
- Dependencies between tasks

### 3. Understand Integration Details
Read `planning/CHATWOOT_ZERODB_INTEGRATION_PLAN.md` for:
- Specific API implementation patterns
- Code examples and best practices
- Service layer design

---

## Project Timeline

**Total Duration:** 12 weeks (3 months)
**Total Story Points:** 89

| Epic | Timeline | Points | Status |
|------|----------|--------|--------|
| Epic 1: Database Migration | Weeks 1-2 | 13 | 🟡 Not Started |
| Epic 2: Semantic Search | Weeks 3-4 | 21 | 🟡 Not Started |
| Epic 3: Smart Suggestions | Week 5 | 13 | 🟡 Not Started |
| Epic 4: Agent Memory | Week 6 | 13 | 🟡 Not Started |
| Epic 5: RLHF & Similar Tickets | Weeks 7-8 | 13 | 🟡 Not Started |
| Epic 6: Branding & Signup | Weeks 9-10 | 8 | 🟡 Not Started |
| Epic 7: Metrics & Analytics | Week 11 | 8 | 🟡 Not Started |

---

## AI Features Being Built

### 1. **Semantic Conversation Search** 🔍
- Find conversations by meaning, not just keywords
- Powered by ZeroDB vector search + free embeddings
- Example: Search "customer wants refund" → finds all refund-related tickets

### 2. **Smart Canned Response Suggestions** 💡
- AI recommends relevant canned responses based on conversation context
- Saves agents 30% time finding the right response
- Powered by ZeroDB semantic search

### 3. **Agent Memory & Context** 🧠
- Remember customer preferences across all conversations
- Store and recall notes, preferences, past issues
- Powered by ZeroDB Memory API

### 4. **RLHF Feedback Loop** 📊
- Collect agent feedback on AI suggestions
- Continuously improve AI quality over time
- Powered by ZeroDB RLHF API

### 5. **Similar Ticket Detection** 🔗
- Automatically find and link related conversations
- Help agents reference past solutions
- Powered by ZeroDB vector similarity

---

## Tech Stack

### Core Technologies
- **Framework:** Ruby on Rails 7.1
- **Database:** ZeroDB Dedicated PostgreSQL (replaces standard PostgreSQL)
- **AI Features:** ZeroDB NoSQL + Vector + Memory APIs
- **Frontend:** Vue.js 3
- **Jobs:** Sidekiq (background processing)

### ZeroDB Services Used
- Dedicated PostgreSQL (core data)
- Vector Database (semantic search)
- Embeddings API (FREE 384-dim)
- Memory API (customer context)
- RLHF API (feedback collection)
- Event Streaming (real-time updates)

---

## Environment Setup

### Required Environment Variables

```bash
# ZeroDB Configuration
ZERODB_API_KEY=your_api_key
ZERODB_PROJECT_ID=your_project_id
ZERODB_API_URL=https://api.ainative.studio/v1/public

# ZeroDB Dedicated PostgreSQL
ZERODB_POSTGRES_HOST=postgres-xxx.railway.app
ZERODB_POSTGRES_PORT=5432
ZERODB_POSTGRES_DATABASE=chatwoot_production
ZERODB_POSTGRES_USERNAME=postgres_user_xxx
ZERODB_POSTGRES_PASSWORD=generated_password
```

### Getting Started

1. **Clone the repository**
   ```bash
   cd /Users/aideveloper
   # Repository: chatwoot-test (currently tracking upstream Chatwoot)
   # Will be forked to: AINative-Studio/chatwoot-zerodb
   ```

2. **Set up ZeroDB account**
   - Sign up at https://api.ainative.studio
   - Create project "Chatwoot Production"
   - Get API credentials

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Add ZeroDB credentials to .env
   ```

4. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

5. **Set up database**
   ```bash
   rails db:migrate
   rails db:seed
   ```

---

## Success Metrics

### Week 12 Targets (End of Development)
- ✅ 100% feature parity with original Chatwoot
- ✅ 5 new AI-powered features live
- ✅ 500+ GitHub stars
- ✅ 10+ ZeroDB signups via Chatwoot referral

### 6-Month Targets
- ✅ 100+ ZeroDB signups from Chatwoot users
- ✅ 50+ community forks
- ✅ 10+ production deployments
- ✅ $5,000+/month revenue for ZeroDB

---

## Team Structure

| Role | Responsibilities |
|------|-----------------|
| Tech Lead | Architecture decisions, code review, ZeroDB integration |
| Backend Dev 1 | Database migration, semantic search, agent memory |
| Backend Dev 2 | Smart suggestions, RLHF, similar tickets |
| Frontend Dev | All Vue.js components and UI for AI features |
| DevOps | Infrastructure, deployment, monitoring |
| QA | Testing, documentation, validation |

---

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Read the documentation** - Understand the master plan and architecture
2. **Pick a story from the backlog** - See `backlog/BACKLOG_CHATWOOT_ZERODB.md`
3. **Create a feature branch** - Use naming: `feature/story-X.Y-description`
4. **Write tests** - All new code must have RSpec tests
5. **Submit PR** - Include story reference and acceptance criteria checklist

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/story-2.1-zerodb-sdk

# 2. Make changes
# ... code ...

# 3. Run tests
bundle exec rspec
npm run test

# 4. Commit and push
git add .
git commit -m "feat: Add ZeroDB Ruby SDK integration (Story 2.1)"
git push origin feature/story-2.1-zerodb-sdk

# 5. Create PR on GitHub
```

---

## External References

### ZeroDB Documentation
- [ZeroDB Public Developer Guide](/Users/aideveloper/core/docs/Zero-DB/ZeroDB_Public_Developer_Guide.md)
- [ZeroDB Tools Quick Reference](/Users/aideveloper/core/docs/ZERODB_TOOLS_QUICK_REFERENCE.md)
- API Docs: https://api.ainative.studio/docs

### Chatwoot Documentation
- [Official Chatwoot Docs](https://www.chatwoot.com/docs)
- [Chatwoot GitHub](https://github.com/chatwoot/chatwoot)
- [Chatwoot Architecture Analysis](/Users/aideveloper/core/docs/architecture/CHATWOOT_ARCHITECTURE_ANALYSIS.md)

---

## Support & Communication

### Internal Team
- **Slack Channel:** #chatwoot-zerodb
- **Daily Standups:** 10:00 AM PT
- **Sprint Planning:** Mondays 2:00 PM PT
- **Retrospectives:** Fridays 4:00 PM PT

### GitHub
- **Issues:** https://github.com/AINative-Studio/chatwoot-zerodb/issues
- **Project Board:** https://github.com/AINative-Studio/chatwoot-zerodb/projects/1
- **Discussions:** https://github.com/AINative-Studio/chatwoot-zerodb/discussions

### External Support
- **ZeroDB Support:** support@ainative.studio
- **Chatwoot Community:** https://discord.gg/cJXdrwS

---

## Project Status

**Current Phase:** Planning Complete → Ready for Development
**Next Milestone:** Epic 1 (Database Migration) - Start Week of Dec 16
**Target Launch:** March 2026 (Week 12)

### This Week's Focus (Dec 16-20)
1. Fork Chatwoot repository to AINative-Studio/chatwoot-zerodb
2. Create ZeroDB account and provision PostgreSQL instance
3. Set up development environment
4. Begin Epic 1: Database Migration

---

## License

This fork maintains Chatwoot's **MIT License** with proper attribution.

- **Chatwoot:** MIT License - https://github.com/chatwoot/chatwoot
- **ZeroDB Integration:** MIT License
- **Contribution:** All contributions must be MIT licensed

---

**Document Version:** 1.0
**Last Updated:** December 16, 2025
**Maintained By:** AI Native Studio Team
**Contact:** chatwoot@ainative.studio
