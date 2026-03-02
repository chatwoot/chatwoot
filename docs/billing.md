# Stripe Billing

## Overview

AirysChat uses a hybrid billing model:
- **Base plan** — Monthly subscription with fixed limits (agents, inboxes, AI tokens)
- **AI metered overage** — Usage beyond the plan's included AI tokens is tracked and billed

## Setup

### 1. Environment variables

Add to your `.env` file:

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### 2. Database migrations

```bash
bundle exec rails db:migrate
```

This creates three tables:
- `saas_plans` — plan definitions
- `saas_subscriptions` — per-account subscription state
- `saas_ai_usage_records` — daily AI usage tracking

### 3. Seed default plans

```bash
bundle exec rake saas:seed_plans
```

Creates 4 plans:

| Plan | Price | Agents | Inboxes | AI Tokens/mo |
|------|-------|--------|---------|-------------|
| Free | $0 | 1 | 1 | 10,000 |
| Starter | $29/mo | 5 | 5 | 100,000 |
| Pro | $99/mo | 20 | 20 | 500,000 |
| Enterprise | $299/mo | ∞ | ∞ | 2,000,000 |

### 4. Create Stripe products

For each plan, create a corresponding Product and Price in Stripe Dashboard (or via API), then update the `stripe_product_id` and `stripe_price_id` columns.

### 5. Configure webhook endpoint

In Stripe Dashboard → Webhooks, add:
- **URL:** `https://your-domain.com/saas/webhooks/stripe`
- **Events:**
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_failed`

## Data Model

### Saas::Plan

```ruby
# saas/app/models/saas/plan.rb
# Columns: name, stripe_product_id, stripe_price_id, price_cents, interval,
#          agent_limit, inbox_limit, ai_tokens_monthly, features (JSONB), active
```

### Saas::Subscription

```ruby
# saas/app/models/saas/subscription.rb
# Columns: account_id, saas_plan_id, stripe_subscription_id, stripe_customer_id,
#          status (enum), current_period_start, current_period_end, trial_end
#
# Status values: active, trialing, past_due, canceled, unpaid, incomplete
```

### Saas::AiUsageRecord

```ruby
# saas/app/models/saas/ai_usage_record.rb
# Columns: account_id, provider, model, tokens_input, tokens_output,
#          cost_microcents, feature, recorded_on
#
# One record per account/provider/model/feature/day
```

## API Endpoints

All endpoints require authentication.

### Get available plans

```
GET /saas/api/v1/accounts/:account_id/plans
```

Returns all active plans with their limits and pricing.

### Create checkout session

```
POST /saas/api/v1/accounts/:account_id/checkout
Body: { "plan_id": 2 }
```

Creates a Stripe Checkout Session and returns the URL. Redirects the user to Stripe for payment.

### Get current subscription

```
GET /saas/api/v1/accounts/:account_id/subscription
```

Returns the account's current subscription details including plan, status, and period dates.

### Get usage limits

```
GET /saas/api/v1/accounts/:account_id/limits
```

Returns current usage vs. plan limits:
- Agent count / limit
- Inbox count / limit
- AI tokens used / included
- AI tokens remaining

## Webhook Flow

```
Stripe → POST /saas/webhooks/stripe → StripeController
  │
  ├── 1. Verify signature (STRIPE_WEBHOOK_SECRET)
  │      └── Production: rejects unsigned webhooks (returns 400)
  │
  ├── 2. Return 200 immediately (Stripe best practice)
  │
  └── 3. Enqueue Saas::StripeWebhookJob (async processing)
         │
         ├── Idempotency check (Rails.cache, 24h TTL)
         │
         ├── checkout.session.completed   → Create Subscription record
         ├── customer.subscription.updated → Update status/period/plan
         ├── customer.subscription.deleted → Mark as canceled
         └── invoice.payment_failed       → Mark as past_due
```

### Async Webhook Processing

Per Stripe best practices, the webhook controller returns `200 OK` immediately and delegates processing to `Saas::StripeWebhookJob`:

```ruby
# saas/app/controllers/saas/webhooks/stripe_controller.rb
def create
  payload = request.body.read
  event = verify_signature(payload)
  Saas::StripeWebhookJob.perform_later(event.type, event.data.object.to_json)
  head :ok
end
```

### Idempotency

`Saas::StripeWebhookJob` uses cache-based idempotency to prevent duplicate processing:

```ruby
# saas/app/jobs/saas/stripe_webhook_job.rb
cache_key = "stripe_webhook:#{event_id}"
return if Rails.cache.read(cache_key)
Rails.cache.write(cache_key, true, expires_in: 24.hours)
# ... process event
```

### Production Signature Enforcement

In production, unsigned webhooks are rejected with a 400 response. In development/test, signature verification is skipped if `STRIPE_WEBHOOK_SECRET` is not set.

## StripeService

Located at `saas/app/services/saas/stripe_service.rb`:

```ruby
Saas::StripeService.create_customer(account)
Saas::StripeService.create_checkout_session(account, plan)
Saas::StripeService.create_billing_portal_session(account)
```

### Dynamic Payment Methods

Checkout sessions omit `payment_method_types` to let Stripe automatically present the best payment methods based on the customer's location and currency (cards, bank transfers, wallets, etc.).

## Account Extensions

### Auto-assign default plan

When a new account is created, `Saas::Concerns::Account` automatically assigns the Free plan by creating a Subscription record.

### Usage limits override

`Saas::Account::PlanUsageAndLimits` overrides the core `usage_limits` method to return limits from the account's current plan instead of hardcoded defaults.

Additional methods:
- `ai_tokens_remaining` — tokens included minus tokens used this month
- `ai_usage_exceeded?` — whether the account has exceeded its AI token allowance

## Super Admin

Plans can be managed via Super Admin at `/super_admin/saas_plans`:
- Create/edit/delete plans
- View all fields including Stripe IDs
- Toggle plan active status

## Frontend

The billing page at Settings → Billing shows:
- Plan comparison cards with current plan highlighted
- AI usage progress bar (tokens used / included)
- Upgrade/downgrade buttons (redirect to Stripe Checkout)
- Manage subscription button (redirect to Stripe Billing Portal)

Located at `app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue`.

## Testing with Stripe CLI

```bash
# Listen for webhooks locally
stripe listen --forward-to localhost:3000/saas/webhooks/stripe

# Trigger test events
stripe trigger checkout.session.completed
stripe trigger invoice.payment_failed
```
