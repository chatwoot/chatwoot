# Release Checklist: Staging → Production (Master)

**Date:** 2026-02-16
**Branch:** `staging` → `master`
**Commits:** 80+ commits (Aloo AI, Storefront, Calendly, Macros, and more)

---

## Pre-Release

- [ ] Take a full **database backup** of production
- [ ] Notify the team about the planned release and potential downtime
- [ ] Confirm all features are tested and approved on staging

---

## Database Migrations (32 migrations)

> Migrations include table creation, table drops, and HNSW vector index builds.
> Plan for extended migration time due to vector index creation.

- [ ] Run migrations in a maintenance window
  ```bash
  bundle exec rake db:migrate
  ```
- [ ] Verify all 32 migrations complete successfully

### Destructive Migrations (irreversible)

These drop tables — ensure they are no longer needed:

- [ ] `drop_captain_tables` (captain_custom_tools, captain_scenarios, captain_inboxes, etc.)
- [ ] `drop_aloo_message_feedbacks`
- [ ] `drop_aloo_memories_table`
- [ ] `drop_aloo_conversation_contexts_table`
- [ ] `drop_aloo_traces_table`

---

## Environment & Secrets

### Required for Aloo AI

- [ ] `ALOO_OPENAI_API_KEY` — set in production env
- [ ] `ALOO_ANTHROPIC_API_KEY` — set in production env (if using Claude)
- [ ] `ALOO_GEMINI_API_KEY` — set in production env (if using Gemini)
- [ ] `ALOO_DEEPSEEK_API_KEY` — set in production env (if using DeepSeek)

### Required for Voice Features

- [ ] `ELEVENLABS_API_KEY` — set in production env (skip if not using voice)

### Required for Calendly Integration

- [ ] `CALENDLY_CLIENT_ID` — set via installation config or env
- [ ] `CALENDLY_CLIENT_SECRET` — set via installation config or env

---

## Deployment

- [ ] Update `k8s/production/` image tags to new version (v1.0.93)
  - `k8s/production/rails-deployment.yaml`
  - `k8s/production/sidekiq-deployment.yaml`
  - `k8s/production/vite-deployment.yaml`
- [ ] Verify `bundle install` completes in Docker build (new gems: `turbo-rails`, `pdf-reader`, `roo`, `roo-xls`, `docx`, `ruby_llm-agents`)
- [ ] Build and push Docker images
- [ ] Deploy to production cluster

---

## Sidekiq & Background Jobs

- [ ] Verify Sidekiq picks up the updated `config/schedule.yml`
- [ ] Confirm new scheduled job is registered:
  - `Aloo::RefreshWebsiteDocumentsJob` — weekly, Sunday 3:00 AM UTC
- [ ] Verify new job queues are processed:
  - `Aloo::ResponseJob`
  - `Aloo::ProcessDocumentJob`
  - `Aloo::AudioTranscriptionJob`
  - `Aloo::VoiceReplyJob`
  - `Integrations::Calendly::WebhookJob`
  - `RequestAiResponseJob`

---

## Feature Flags

- [ ] `aloo` feature flag is **enabled by default** — decide if gradual rollout is needed
  - To disable initially: update `config/features.yml` → `enabled: false` before deploy
- [ ] `captain_integration` and `captain_integration_v2` flags removed — confirm no active usage

---

## Post-Release Verification

- [ ] Application boots without errors
- [ ] Run a health check: `GET /health`
- [ ] Verify Aloo AI assistant page loads in dashboard
- [ ] Verify Storefront routes work: `/store/:account_id`
- [ ] Verify Calendly settings page loads (if configured)
- [ ] Verify Macros feature toggle works
- [ ] Check Sidekiq dashboard for failed jobs
- [ ] Monitor error tracking (Sentry/equivalent) for 30 minutes post-deploy
- [ ] Verify catalog/product pages still function correctly
- [ ] Test a conversation with Aloo AI assistant on a staging-equivalent inbox

---

## Rollback Plan

If critical issues arise:

1. Revert K8s deployments to previous image tags
2. **Do NOT** roll back migrations — the table drops are irreversible
3. If migration-related issues occur, fix forward with a new migration
4. Keep the DB backup available for at least 48 hours post-release
