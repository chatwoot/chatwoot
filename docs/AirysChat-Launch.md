<!-- AirysChat Launch Readiness Review -->
# AirysChat — Launch Readiness Review

After reviewing all documentation and implementing the missing pieces, here's the current status.

---

## ✅ What's Done (Phases 0–10 Complete)

### Core Platform (Phases 0–9)
- Custom branding, Stripe billing, LLM abstraction, AI Agent engine (RAG + tools + voice), Agent Builder UI, Docker deployment, testing, security hardening, and production hardening.

### Phase 10: Launch Readiness (Implemented)

#### 1. Stripe Plan Sync
- **`rake saas:sync_plans_to_stripe`** — Creates Stripe Products + Prices for each `Saas::Plan` and stores the IDs back. Skips free plans and already-synced plans.
- File: `saas/lib/tasks/saas_plans.rake`

#### 2. Full Stripe Webhook Event Handling
All critical webhook events are now processed in `Saas::StripeWebhookJob`:

| Event | Handler | Action |
|-------|---------|--------|
| `checkout.session.completed` | `StripeService.handle_checkout_completed` | Routes to subscription.created |
| `customer.subscription.created` | `StripeService.handle_subscription_event` | Creates/updates subscription + limits |
| `customer.subscription.updated` | `StripeService.handle_subscription_event` | Updates plan + sends plan_changed email |
| `customer.subscription.deleted` | `StripeService.handle_subscription_event` | Cancels + sends cancellation email |
| `customer.subscription.trial_will_end` | `handle_trial_will_end` | Sends trial expiring email |
| `invoice.payment_succeeded` | `handle_payment_succeeded` | Re-activates past_due/unpaid accounts |
| `invoice.payment_failed` | `handle_payment_failed` | Marks past_due (1-2 fails) or unpaid/suspended (3+ fails) + sends email |

#### 3. Account Suspension on Payment Failure
- After **3 failed payment attempts**, account status is set to `unpaid` (suspended).
- `Saas::Account::PlanUsageAndLimits` now returns **zero limits** for `past_due`, `unpaid`, and `canceled` subscriptions — blocking new agent/inbox creation and AI usage.
- When payment succeeds again, subscription is automatically re-activated.

#### 4. Usage Limit Enforcement
- **Agent limit**: Enforced in `AgentsController#validate_limit` via `usage_limits[:agents]` ✅
- **Inbox limit**: Enforced in `InboxesController#validate_limit` via `usage_limits[:inboxes]` ✅
- **AI tokens**: Enforced via `ai_usage_exceeded?` → 402 in `LlmController` ✅
- **Suspended accounts**: `PlanUsageAndLimits` returns `{agents: 0, inboxes: 0}` for suspended subscriptions, preventing any new resource creation.
- **UpgradePage**: Works via `isOnChatwootCloud` (DEPLOYMENT_ENV=cloud) — shows upgrade lock screen when limits are exceeded.

#### 5. SaaS Lifecycle Emails
`Saas::BillingMailer` with 6 email templates (Liquid format, using `mailer/base` layout):

| Email | Trigger | Template |
|-------|---------|----------|
| Welcome | Account creation (`after_create_commit`) | `welcome.liquid` |
| Trial expiring | Stripe `trial_will_end` webhook + daily cron (3 days, 1 day) | `trial_expiring.liquid` |
| Payment failed | Stripe `invoice.payment_failed` webhook | `payment_failed.liquid` |
| Usage alert | Daily cron at 80% and 100% thresholds | `usage_alert.liquid` |
| Subscription canceled | Stripe `customer.subscription.deleted` webhook | `subscription_canceled.liquid` |
| Plan changed | Stripe `customer.subscription.updated` webhook (when plan differs) | `plan_changed.liquid` |

#### 6. Scheduled Jobs (sidekiq-cron)
Added to `config/schedule.yml`:

| Job | Cron | Purpose |
|-----|------|---------|
| `Saas::TrialReminderJob` | Daily 08:00 UTC | Sends trial expiration reminders (3 days + 1 day before) |
| `Saas::ExpireTrialsJob` | Daily 09:00 UTC | Downgrades expired trials to Free plan |
| `Saas::UsageAlertJob` | Daily 10:00 UTC | Sends AI token usage alerts at 80%/100% (idempotent per billing period) |

#### 7. Limits API Enhancement
`GET /saas/api/v1/accounts/:id/limits` now returns both:
- SaaS-specific data (`plan`, `subscription`, `usage` with `ai_usage_percentage`)
- UpgradePage-compatible `limits` shape (`agents/inboxes` as `{allowed, consumed}` pairs)

---

## 📋 Remaining Pre-Launch Checklist

### Must Do Before Launch

```markdown
1. [ ] Run `rake saas:seed_plans` then `rake saas:sync_plans_to_stripe` in production
2. [ ] Configure production SMTP and test all 6 email templates
3. [ ] Register Stripe webhook endpoint with these events:
       checkout.session.completed, customer.subscription.created,
       customer.subscription.updated, customer.subscription.deleted,
       customer.subscription.trial_will_end, invoice.payment_succeeded,
       invoice.payment_failed
4. [ ] Set STRIPE_WEBHOOK_SECRET env var in production
5. [ ] Test full flow: signup → free plan → checkout → upgrade → use AI → hit limit → upgrade
6. [ ] Verify DEPLOYMENT_ENV=cloud in InstallationConfig (needed for UpgradePage)
```

### Nice to Have Post-Launch

```markdown
7. [ ] AI token overage billing (Stripe Usage Records instead of hard block)
8. [ ] Onboarding wizard for new accounts (first inbox, first agent)
9. [ ] Super Admin: manual subscription management UI
10. [ ] Terms of Service + Privacy Policy pages
11. [ ] Account deletion flow
12. [ ] Referral/coupon system
```

---

## Files Changed/Created

### New Files
- `saas/app/mailers/saas/billing_mailer.rb` — 6-method lifecycle mailer
- `saas/app/views/saas/billing_mailer/welcome.liquid`
- `saas/app/views/saas/billing_mailer/trial_expiring.liquid`
- `saas/app/views/saas/billing_mailer/payment_failed.liquid`
- `saas/app/views/saas/billing_mailer/usage_alert.liquid`
- `saas/app/views/saas/billing_mailer/subscription_canceled.liquid`
- `saas/app/views/saas/billing_mailer/plan_changed.liquid`
- `saas/app/jobs/saas/trial_reminder_job.rb` — daily trial expiration reminders
- `saas/app/jobs/saas/usage_alert_job.rb` — daily AI usage threshold alerts
- `saas/app/jobs/saas/expire_trials_job.rb` — daily trial expiration + downgrade

### Modified Files
- `saas/lib/tasks/saas_plans.rake` — added `sync_plans_to_stripe` task
- `saas/app/jobs/saas/stripe_webhook_job.rb` — added `trial_will_end`, `payment_succeeded`, `payment_failed` (enhanced with attempt tracking)
- `saas/app/models/saas/account/plan_usage_and_limits.rb` — suspended state enforcement, `ai_usage_percentage` method
- `saas/app/models/saas/concerns/account.rb` — welcome email on account creation
- `saas/app/services/saas/stripe_service.rb` — plan change + cancellation email notifications
- `saas/app/controllers/saas/api/v1/accounts_controller.rb` — enhanced limits response with UpgradePage-compatible shape
- `config/schedule.yml` — added 3 SaaS cron jobs
- `config/locales/en.yml` — added `saas.mailer.*` i18n keys
- `docs/README.md` — updated status table (Phases 5–10 ✅)