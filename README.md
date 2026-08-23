<div align="center">
  <img src="./public/brand-assets/logo.svg#gh-light-mode-only" alt="ChatPaw" width="420"/>
  <img src="./public/brand-assets/logo_dark.svg#gh-dark-mode-only" alt="ChatPaw" width="420"/>

  ### *Customer conversations with a soul.*
  **«گفتگو با مشتری‌ها، با یک رفیق دیجیتال»**

  [![License: MIT](https://img.shields.io/badge/License-MIT-1fe0b5.svg)](./LICENSE)
  ![Fork of Chatwoot](https://img.shields.io/badge/fork%20of-Chatwoot%20v4.17-1ba5ff)
  ![Platform](https://img.shields.io/badge/self--hosted-privacy--first-ffc857)
</div>

---

# ChatPaw 🐾

**ChatPaw** (چت‌پا) is a free, open-source customer conversation platform + CRM — forked from [Chatwoot](https://github.com/chatwoot/chatwoot), rebuilt with a pet-themed soul, deep RTL/Persian support, and an AI layer that connects to **any OpenAI-compatible router** (OpenRouter / LiteLLM / OmniRoute / NineRouter / Ollama / Groq / vLLM).

Everything is unlimited and self-hosted. No per-seat pricing, no forced cloud calls, no locked AI.

> ChatPaw یک پلتفرم گفتگوی مشتری متن‌باز و رایگان است؛ فورکی از Chatwoot با هویت جدید، پشتیبانی کامل فارسی و RTL، لایه هوش مصنوعی آزاد و ویجت تم‌محور با حالت مَسکات.

---

## 💬 About / درباره ما

We believe customer conversations deserve better than paywalled AI and locked features. ChatPaw started as a fork of Chatwoot `v4.17.0` with one mission: **take the best open-source support desk in the world and make it truly free, personal, and local-first** — with the polish of Goftino-style UX, native Persian/RTL experience, and BYOR (Bring Your Own Router) AI that never phones home.

| | |
|---|---|
| 🏠 | Self-hosted, privacy-first — `docker compose up` and you're done |
| ♾️ | Unlimited operators, conversations, archives, history |
| 🤖 | AI included free — connect any OpenAI-compatible endpoint |
| 🐾 | Pet-themed widget & desktop mascot (*Pawly*) |
| 🌍 | RTL-first: Persian, Arabic, English as first-class citizens |

*ما معتقدیم گفتگو با مشتری نباید گروگان پلن‌های پولی باشد. ChatPaw یعنی همه‌ی امکانات، رایگان و روی سرور خودت.*

---

## ✨ Highlights

### 💬 Omnichannel Support Desk
Live chat, email, Facebook, Instagram, WhatsApp, Telegram, SMS, Line and more — all inboxes unified in one powerful dashboard.

### 🧠 BYOR — Bring Your Own Router AI
Connect **any OpenAI-compatible API**: OpenRouter, LiteLLM, OmniRoute, NineRouter, Ollama, Groq, vLLM… with per-account config, fallback chains and cost tracking. Your keys stay in your env — never in plaintext DB.

### 📚 Native RAG with pgvector
Feed your Help Center articles to your own AI agent. Grounded answers with citations, no external SaaS.

### 🎨 Theme-driven Widget
`theme.json` controls colors, icon, motion presets, sounds, position, RTL, department picker, multi-step pre-chat form and **pet-mode** — where the mascot itself is the chat bubble.

### 🐾 Desktop Pet (*Pawly*)
A floating Tauri-based mascot on the operator's desktop: hops and notifies on new conversations, click to open inbox.

### 🗂️ Everything else you expect
Teams, labels, automation rules, macros, canned responses, campaigns, reports & CSAT, help center portal, SLA, audit logs, SSO, platform APIs, webhooks, Slack integration…

---

## 🚀 Quick start

```bash
# dev stack
docker compose -f docker-compose.yaml up -d postgres redis mailhog
overmind start -f Procfile.dev
# → dashboard: http://localhost:3000

# production, single command
docker compose -f docker-compose.production.yaml up
```

## 🛣 Roadmap

| Phase | Scope | Status |
|---|---|---|
| P0 | Enterprise detox, rebrand, tokens, docs | ✅ done |
| P1 | Dashboard reskin + RTL + fa i18n | ⏳ next |
| P2 | Widget revamp (themes, voice notes, dept picker) | ☐ |
| P3 | Goftino parity backend (worktime, ban rules, NPS…) | ☐ |
| P4 | AI layer (`chatpaw_ai` engine, RAG, copilot) | ☐ |
| P5 | Desktop pet (Tauri) | ☐ |
| P6 | Flow builder & launch | ☐ |

See [`PLANNING.md`](./PLANNING.md) for the full plan.

## 🌳 Branching

git-flow, base branch `develop`. Stable releases are tagged from `master`.
Upstream sync: monthly merge from `chatwoot/chatwoot` via the `upstream` remote.

## 🔒 Security

Please report vulnerabilities through [`SECURITY.md`](./SECURITY.md).

## 📄 License

MIT — see [`LICENSE`](./LICENSE). This project is a fork of [Chatwoot](https://github.com/chatwoot/chatwoot); upstream copyright notice is preserved as required by the MIT license.

---

<div align="center">

*ChatPaw* © 2026, ChatPaw contributors · upstream © 2017–2026 Chatwoot Inc · MIT

🐾 *Customer conversations with a soul.*

</div>
