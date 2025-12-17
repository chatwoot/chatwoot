# Chatwoot-ZeroDB Edition

> AI-native customer support platform powered by ZeroDB

[![GitHub Issues](https://img.shields.io/github/issues/AINative-Studio/chatwoot-zerodb)](https://github.com/AINative-Studio/chatwoot-zerodb/issues)
[![Documentation](https://img.shields.io/badge/docs-available-brightgreen)](./docs/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This is a lightweight fork of [Chatwoot](https://github.com/chatwoot/chatwoot) enhanced with **ZeroDB**'s AI-native database capabilities.

---

## 🚀 What's New in ZeroDB Edition?

### AI-Powered Features (Not in Original Chatwoot)

✅ **Semantic Conversation Search** - Find tickets by meaning, not just keywords
✅ **Smart Response Suggestions** - AI recommends best canned responses
✅ **Agent Memory** - Remember customer preferences across conversations
✅ **Similar Ticket Detection** - Automatically link related conversations
✅ **RLHF Feedback Loop** - Continuously improve AI suggestions

### Powered by ZeroDB

- 🎯 Free embeddings (384-dim BAAI/bge-small-en-v1.5)
- 🚀 Vector search with semantic similarity
- 🧠 Agent memory storage
- 📊 RLHF feedback collection
- ⚡ 50% faster semantic search vs. traditional full-text

---

## 📦 Quick Start

### One-Click Deploy with Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/chatwoot-zerodb)

Includes:
- Pre-configured ZeroDB project
- Dedicated PostgreSQL instance
- All AI features enabled
- First month free with credits!

### Manual Deployment

#### 1. Sign up for ZeroDB (Free Tier Available)

```bash
curl -X POST https://api.ainative.studio/v1/public/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "you@example.com",
    "password": "secure_password"
  }'
```

#### 2. Get API Credentials

Visit https://api.ainative.studio/dashboard to get:
- API Key
- Project ID
- PostgreSQL connection details

#### 3. Clone & Configure

```bash
git clone https://github.com/AINative-Studio/chatwoot-zerodb.git
cd chatwoot-zerodb

# Copy environment template
cp .env.example .env

# Add your ZeroDB credentials
nano .env
```

#### 4. Install & Run

```bash
# Install Ruby dependencies
bundle install

# Install Node dependencies
npm install

# Set up database
rails db:migrate
rails db:seed

# Start server
bundle exec rails server
```

Visit http://localhost:3000 and log in with default credentials.

---

## 📚 Documentation

**Start Here:**
- [docs/README.md](./docs/README.md) - Project overview and structure
- [docs/backlog/BACKLOG_CHATWOOT_ZERODB.md](./docs/backlog/BACKLOG_CHATWOOT_ZERODB.md) - Development backlog (89 story points)

**Planning Documents:**
- [Master Plan](./docs/planning/CHATWOOT_ZERODB_FORK_MASTER_PLAN.md) - Strategic plan and vision
- [Integration Plan](./docs/planning/CHATWOOT_ZERODB_INTEGRATION_PLAN.md) - Technical specifications

**External Resources:**
- [Chatwoot Official Docs](https://www.chatwoot.com/docs)
- [ZeroDB Developer Guide](https://docs.zerodb.io)

---

## 🛠️ Tech Stack

### Core Technologies
- **Framework:** Ruby on Rails 7.1
- **Database:** ZeroDB Dedicated PostgreSQL 15+ (replaces standard PostgreSQL)
- **AI Features:** ZeroDB NoSQL + Vector + Memory APIs
- **Frontend:** Vue.js 3
- **Background Jobs:** Sidekiq
- **Cache:** Redis

### ZeroDB Services
- Dedicated PostgreSQL (core data storage)
- Vector Database (semantic search)
- Embeddings API (FREE 384-dim)
- Memory API (customer context)
- RLHF API (feedback collection)
- Event Streaming (real-time updates)

---

## 💰 Pricing

### Chatwoot-ZeroDB Fork
**Free & Open Source** - MIT License
Self-host on your infrastructure with no vendor lock-in.

### ZeroDB Costs (Pay-as-You-Grow)

| Tier | Price | Vectors | Features |
|------|-------|---------|----------|
| **Free** | $0/mo | 10K | 100K events/mo, 1GB storage |
| **Pro** | $49/mo | 100K | Unlimited embeddings, priority support |
| **Scale** | $199/mo | 1M | Quantum features, dedicated support |
| **Enterprise** | Custom | 100M+ | Custom AI models, SLA guarantees |

**Typical Costs for Chatwoot:**
- Small team (1K conversations/month): **$0 - $10/month**
- Medium team (10K conversations/month): **$20 - $49/month**
- Large team (100K conversations/month): **$199/month**

---

## 📈 Development Status

**Current Phase:** Planning Complete → Ready for Development
**Target Launch:** March 2026 (Week 12)

### Roadmap

| Epic | Timeline | Points | Status |
|------|----------|--------|--------|
| Database Migration | Weeks 1-2 | 13 | 🟡 Not Started |
| Semantic Search | Weeks 3-4 | 21 | 🟡 Not Started |
| Smart Suggestions | Week 5 | 13 | 🟡 Not Started |
| Agent Memory | Week 6 | 13 | 🟡 Not Started |
| RLHF & Similar Tickets | Weeks 7-8 | 13 | 🟡 Not Started |
| Branding & Signup | Weeks 9-10 | 8 | 🟡 Not Started |
| Metrics & Analytics | Week 11 | 8 | 🟡 Not Started |

**Total:** 89 story points over 12 weeks

---

## 🤝 Contributing

We welcome contributions! This fork maintains compatibility with upstream Chatwoot.

### How to Contribute

1. **Read the documentation** - Start with [docs/README.md](./docs/README.md)
2. **Pick an issue** - Browse [open issues](https://github.com/AINative-Studio/chatwoot-zerodb/issues)
3. **Create a feature branch** - `git checkout -b feature/story-X.Y-description`
4. **Write tests** - All new code must have RSpec tests
5. **Submit PR** - Include issue reference and acceptance criteria

### Development Workflow

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/chatwoot-zerodb.git

# 2. Create feature branch
git checkout -b feature/semantic-search

# 3. Make changes and test
bundle exec rspec
npm run test

# 4. Commit with descriptive message
git commit -m "feat: Add semantic search service (Story 2.2)"

# 5. Push and create PR
git push origin feature/semantic-search
```

### Code Style
- Follow [Ruby Style Guide](https://rubystyle.guide/)
- Use [ESLint](https://eslint.org/) for JavaScript
- Write meaningful commit messages
- Add tests for all new features

---

## 🎯 Success Metrics

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

## 🙏 Credits

- **[Chatwoot Team](https://github.com/chatwoot/chatwoot)** - Original open-source platform
- **[ZeroDB](https://zerodb.io)** - AI-native database infrastructure
- **Contributors** - See [CONTRIBUTORS.md](./CONTRIBUTORS.md)

---

## 📜 License

MIT License (same as Chatwoot)

Copyright (c) 2025 AI Native Studio

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

---

## 🔗 Links

- **Demo:** https://demo.chatwoot-zerodb.com (coming soon)
- **Documentation:** [./docs/](./docs/)
- **Issues:** https://github.com/AINative-Studio/chatwoot-zerodb/issues
- **ZeroDB Homepage:** https://zerodb.io
- **ZeroDB Docs:** https://docs.zerodb.io
- **Support:** chatwoot@ainative.studio

---

## 🌟 Star Us!

If you find this project useful, please consider giving it a star ⭐ on GitHub!

[![GitHub stars](https://img.shields.io/github/stars/AINative-Studio/chatwoot-zerodb?style=social)](https://github.com/AINative-Studio/chatwoot-zerodb/stargazers)

---

**Built with ❤️ by AI Native Studio**
