# Subscription & Billing Implementation Plan

## Overview

Implement self-service signup and subscription for AlooChat with two plans (**Basic** and **Pro**) using **Stripe** via the **[pay-rails/pay](https://github.com/pay-rails/pay)** gem.

This plan follows the **Deep Modules Philosophy** from `CLAUDE.md`: all billing complexity is hidden behind simple interfaces on the `Account` model via a `Billable` concern. Every operation is testable from `rails console`.

---

## Table of Contents

1. [Plan Definitions](#1-plan-definitions)
2. [Architecture & Design Rationale](#2-architecture--design-rationale)
3. [Phase 1 — Backend Foundation](#3-phase-1--backend-foundation)
4. [Phase 2 — Stripe Configuration](#4-phase-2--stripe-configuration)
5. [Phase 3 — API Layer (Thin Controllers)](#5-phase-3--api-layer-thin-controllers)
6. [Phase 4 — Frontend](#6-phase-4--frontend)
7. [Phase 5 — Webhooks, Plan Sync & Auto-Suspend](#7-phase-5--webhooks-plan-sync--auto-suspend)
8. [Phase 6 — Super Admin Billing Toolkit](#8-phase-6--super-admin-billing-toolkit)
9. [Phase 7 — Billing Notifications & Mailer](#9-phase-7--billing-notifications--mailer)
10. [Phase 8 — Admin Observability (Filters & Dashboard)](#10-phase-8--admin-observability-filters--dashboard)
11. [Rails Console Playbook](#11-rails-console-playbook)
12. [File Map](#12-file-map)
13. [Environment Variables](#13-environment-variables)
14. [Open Questions](#14-open-questions)
15. [Post-Launch Iterations](#15-post-launch-iterations)

---

## 1. Plan Definitions

### Basic — 60 KD/month or 600 KD/year

| Feature | Value |
|---|---|
| AI Responses | ~10,000 msgs/month |
| Voice Notes | Included (1 voice note = 6 AI responses) |
| Agents / Users | Unlimited |
| Integrations | WhatsApp, Instagram, Facebook Messenger, Telegram, Live Chat Widget, Email |
| AI Auto Labeling | Included |
| Analytics | Advanced |
| Agent Customization | Full |
| Knowledge Base | Up to 100 documents |
| CRM Integration | **Not Included** |
| Custom Workflows | Included |
| API Access | **Not Included** |

### Pro — 75 KD/month or 900 KD/year

Everything in Basic, plus:

| Feature | Value |
|---|---|
| AI Responses | 25,000 msgs/month |
| Knowledge Base | Up to 200 documents |
| CRM Integration | Notion, Hubspot, Odoo, MoEngage |
| API Access | **Included** |

---

## 2. Architecture & Design Rationale

### Deep Module: `Billable` Concern on `Account`

All billing complexity lives in a single concern — `Billable` — included on `Account`. This is the **deep module**: it hides Stripe interactions, plan resolution, usage tracking, feature syncing, and checkout session creation behind a simple interface.

```
Module Depth = (Complexity Hidden) / (Interface Exposed)

Billable concern:
  Hidden: Stripe API, pay gem orchestration, plan config loading,
          usage counter management, feature flag syncing, checkout
          session creation, billing portal sessions, subscription
          state transitions, webhook-driven plan sync
  Exposed: ~12 methods on Account
```

### Why NOT separate services

The old plan proposed `PlanLimitService`, `PlanSyncService`, `SubscriptionCreatedHandler`, `SubscriptionUpdatedHandler`, `SubscriptionDeletedHandler`, `PaymentFailedHandler` — **6 shallow classes** that each wrap a single operation. Per CLAUDE.md, these are anti-patterns:

```ruby
# ❌ SHALLOW — wrapper that just delegates
class PlanLimitService
  def initialize(account) = @account = account
  def can_use_ai_response?
    usage.ai_responses_count < @account.plan_config.ai_response_limit
  end
end

# ✅ DEEP — methods live on Account via Billable concern
account.within_ai_limit?        # hides: usage lookup, plan resolution, nil-safety
account.track_ai_response!      # hides: find_or_create usage record, atomic increment
account.sync_plan_features!     # hides: plan lookup, feature flag mapping, limits update
```

### One deep service: `Billing::CheckoutService`

The one place a service is justified is checkout — it orchestrates plan validation, Stripe customer setup, checkout session creation, and URL construction. This has real cross-model complexity worth hiding.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────┐
│                   Account Model                       │
│                                                      │
│  include Billable   ← DEEP: hides all billing logic  │
│  include Featurable ← existing: feature flags         │
│                                                      │
│  # Customer self-service:                            │
│  account.checkout_url(plan_key)                      │
│  account.billing_portal_url                          │
│  account.swap_plan!(plan_key)                        │
│  account.cancel_subscription!                        │
│  account.resume_subscription!                        │
│  account.subscribed? / active_plan / plan_tier       │
│                                                      │
│  # Usage tracking & limits:                          │
│  account.within_ai_limit?                            │
│  account.within_limit?(:knowledge_base_documents)    │
│  account.track_ai_response! / track_voice_note!      │
│  account.usage_summary / billing_status              │
│                                                      │
│  # Admin toolkit:                                    │
│  account.grant_trial!(days: 30)                      │
│  account.extend_trial!(days: 14)                     │
│  account.grant_complimentary!(plan_key: "pro_annual")│
│  account.apply_coupon!("RAMADAN50")                  │
│  account.override_plan!("pro_monthly")               │
│  account.add_bonus_credits!(5000)                    │
│  account.reset_usage! / sync_plan_features!          │
│  account.suspend_for_nonpayment!                     │
│  account.reactivate_after_payment!                   │
│                                                      │
│  has_many :usage_records (per-month, auto-created)   │
│  has_many :pay_customers (via pay gem)               │
└──────────────────────────────────┬───────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
  ┌──────────────┐   ┌──────────────────────┐   ┌──────────────┐
  │  PlanConfig   │   │ Pay Gem Models       │   │ AccountUsage │
  │  (PORO from   │   │ + Stripe API         │   │ Record       │
  │  plans.yml)   │   │ + BillingMailer      │   │ (per-month)  │
  └──────────────┘   └──────────────────────┘   └──────────────┘

Controllers are thin delegates:
  SubscriptionsController#show    → render account.billing_status
  SubscriptionsController#checkout → render account.checkout_url(plan_key)
  SuperAdmin::AccountsController  → account.grant_trial!, etc.
```

---

## 3. Phase 1 — Backend Foundation

### 3.1 Install the Pay Gem

```ruby
# Gemfile — add after existing stripe gem
gem "pay", "~> 7"
# gem "receipts", "~> 2.0"  # optional: PDF receipts, add later if needed
```

```bash
bundle install
bin/rails pay:install:migrations
bin/rails db:migrate
```

Tables created by pay: `pay_customers`, `pay_subscriptions`, `pay_charges`, `pay_payment_methods`, `pay_webhooks`, `pay_merchants`.

### 3.2 Pay Gem Initializer

**New file: `config/initializers/pay.rb`**

```ruby
Pay.setup do |config|
  config.business_name = "AlooChat"
  config.business_address = "Kuwait"
  config.application_name = "AlooChat"
  config.support_email = ENV.fetch("MAILER_SENDER_EMAIL", "support@aloochat.com")

  config.default_product_name = "AlooChat"
  config.default_plan_name = "basic"

  config.automount_routes = true
  config.routes_path = "/pay"

  config.enabled_processors = [:stripe]

  config.send_emails = true
  config.emails.payment_action_required = true
  config.emails.receipt = true
  config.emails.refund = true
  config.emails.subscription_renewing = true
end
```

### 3.3 Plan Configuration (PORO)

**New file: `config/plans.yml`**

Single source of truth for plan definitions. Versioned in code, not in the database.

```yaml
plans:
  basic_monthly:
    name: Basic
    tier: basic
    interval: month
    amount_kd: 60
    stripe_price_id: <%= ENV.fetch("STRIPE_BASIC_MONTHLY_PRICE_ID", "price_basic_monthly_test") %>
    limits:
      ai_responses_per_month: 10000
      knowledge_base_documents: 100
    features:
      crm_integration: false
      api_access: false

  basic_annual:
    name: Basic
    tier: basic
    interval: year
    amount_kd: 600
    stripe_price_id: <%= ENV.fetch("STRIPE_BASIC_ANNUAL_PRICE_ID", "price_basic_annual_test") %>
    limits:
      ai_responses_per_month: 10000
      knowledge_base_documents: 100
    features:
      crm_integration: false
      api_access: false

  pro_monthly:
    name: Pro
    tier: pro
    interval: month
    amount_kd: 75
    stripe_price_id: <%= ENV.fetch("STRIPE_PRO_MONTHLY_PRICE_ID", "price_pro_monthly_test") %>
    limits:
      ai_responses_per_month: 25000
      knowledge_base_documents: 200
    features:
      crm_integration: true
      api_access: true

  pro_annual:
    name: Pro
    tier: pro
    interval: year
    amount_kd: 900
    stripe_price_id: <%= ENV.fetch("STRIPE_PRO_ANNUAL_PRICE_ID", "price_pro_annual_test") %>
    limits:
      ai_responses_per_month: 25000
      knowledge_base_documents: 200
    features:
      crm_integration: true
      api_access: true
```

**New file: `app/models/plan_config.rb`**

```ruby
# PORO that loads plan definitions from config/plans.yml.
# Not an ActiveRecord model — plans are code, not data.
#
# Console usage:
#   PlanConfig.all                          # => [PlanConfig, ...]
#   PlanConfig.find("pro_monthly")          # => PlanConfig
#   PlanConfig.for_price("price_xxx")       # => PlanConfig (lookup by Stripe price ID)
#   plan.ai_response_limit                  # => 25000
#   plan.feature_enabled?(:api_access)      # => true
#   plan.pro?                               # => true
#
class PlanConfig
  PLANS = YAML.safe_load(
    ERB.new(Rails.root.join("config/plans.yml").read).result,
    permitted_classes: [], aliases: true
  ).fetch("plans").freeze

  attr_reader :key, :name, :tier, :interval, :amount_kd,
              :stripe_price_id, :limits, :features

  def initialize(key, data)
    @key = key
    @name = data["name"]
    @tier = data["tier"]
    @interval = data["interval"]
    @amount_kd = data["amount_kd"]
    @stripe_price_id = data["stripe_price_id"]
    @limits = (data["limits"] || {}).symbolize_keys
    @features = (data["features"] || {}).symbolize_keys
  end

  class << self
    def find(plan_key)
      data = PLANS[plan_key]
      raise ArgumentError, "Unknown plan: #{plan_key}" unless data

      new(plan_key, data)
    end

    def for_price(stripe_price_id)
      key, data = PLANS.find { |_k, v| v["stripe_price_id"] == stripe_price_id }
      return nil unless key

      new(key, data)
    end

    def all
      PLANS.map { |key, data| new(key, data) }
    end
  end

  def ai_response_limit  = limits[:ai_responses_per_month]
  def kb_document_limit   = limits[:knowledge_base_documents]

  def feature_enabled?(feature)
    features.fetch(feature, false)
  end

  def basic? = tier == "basic"
  def pro?   = tier == "pro"

  def to_h
    { key: key, name: name, tier: tier, interval: interval,
      amount_kd: amount_kd, limits: limits, features: features }
  end
end
```

### 3.4 Usage Tracking Model

**New migration: `db/migrate/XXXXXX_create_account_usage_records.rb`**

```ruby
class CreateAccountUsageRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :account_usage_records do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.integer :ai_responses_count, default: 0, null: false
      t.integer :voice_notes_count, default: 0, null: false
      t.integer :bonus_credits, default: 0, null: false
      t.date :period_date, null: false

      t.timestamps
    end

    add_index :account_usage_records, [:account_id, :period_date],
              unique: true, name: "idx_usage_account_period"
  end
end
```

**New file: `app/models/account_usage_record.rb`**

```ruby
# Tracks monthly AI usage per account. One row per account per month.
#
# Console usage:
#   record = AccountUsageRecord.current_for(account)
#   record.increment_ai_responses!
#   record.increment_voice_notes!     # adds 1 voice note + 6 AI responses
#   record.ai_responses_count         # => 142
#
class AccountUsageRecord < ApplicationRecord
  belongs_to :account

  validates :period_date, presence: true, uniqueness: { scope: :account_id }

  def self.current_for(account)
    find_or_create_by!(account: account, period_date: Time.current.beginning_of_month.to_date)
  end

  def increment_ai_responses!(count = 1)
    increment!(:ai_responses_count, count)
  end

  def increment_voice_notes!(count = 1)
    # 1 voice note = 6 AI responses
    increment!(:voice_notes_count, count)
    increment!(:ai_responses_count, count * 6)
  end
end
```

### 3.5 The Deep Module: `Billable` Concern

**New file: `app/models/concerns/billable.rb`**

This is the core of the system. It hides all billing complexity behind simple methods on `Account`.

```ruby
# Deep concern that hides all subscription/billing complexity.
#
# Hides: pay gem orchestration, Stripe API interactions, plan config resolution,
#        usage tracking, feature flag syncing, checkout/portal session creation,
#        subscription lifecycle (swap, cancel, resume), webhook-driven sync.
#
# Console usage:
#   account = Account.find(1)
#
#   # Plan inspection
#   account.active_plan              # => PlanConfig or nil
#   account.subscribed?              # => true
#   account.plan_tier                # => "pro"
#
#   # Usage tracking
#   account.within_ai_limit?         # => true
#   account.track_ai_response!       # increments counter
#   account.track_voice_note!        # increments counter (1 note = 6 AI responses)
#   account.usage_summary            # => { ai_responses: 142, limit: 25000, ... }
#
#   # Subscription management
#   account.checkout_url("pro_monthly")    # => "https://checkout.stripe.com/..."
#   account.billing_portal_url             # => "https://billing.stripe.com/..."
#   account.swap_plan!("basic_annual")     # swaps subscription in Stripe
#   account.cancel_subscription!           # cancels at period end
#   account.resume_subscription!           # resumes cancelled subscription
#   account.sync_plan_features!            # syncs feature flags + limits from plan
#
module Billable
  extend ActiveSupport::Concern

  included do
    pay_customer stripe_attributes: :stripe_attributes

    has_many :usage_records, class_name: "AccountUsageRecord", dependent: :destroy
  end

  # ── Plan Resolution ────────────────────────────────────────────

  def active_subscription
    payment_processor&.subscription
  end

  def active_plan
    sub = active_subscription
    return nil unless sub&.active? || sub&.on_trial?

    PlanConfig.for_price(sub.processor_plan)
  end

  def plan_tier
    active_plan&.tier
  end

  def subscribed?
    active_subscription&.active? || active_subscription&.on_trial? || false
  end

  # ── Usage Tracking ─────────────────────────────────────────────

  def current_usage
    AccountUsageRecord.current_for(self)
  end

  def within_ai_limit?
    plan = active_plan
    return true unless plan # no plan = no enforcement (legacy/admin accounts)

    usage = current_usage
    effective_limit = plan.ai_response_limit + (usage.bonus_credits || 0)
    usage.ai_responses_count < effective_limit
  end

  # General limit check — works for any resource defined in plans.yml limits.
  # Returns true if the current count is below the plan limit, or if no plan is set.
  #
  #   account.within_limit?(:knowledge_base_documents, account.aloo_documents.count)
  #   account.within_limit?(:ai_responses_per_month)  # uses usage record automatically
  #
  def within_limit?(resource, current_count = nil)
    plan = active_plan
    return true unless plan

    limit = plan.limits[resource]
    return true unless limit # no limit defined for this resource = unlimited

    current_count ||= current_usage.send(:"#{resource}_count") if current_usage.respond_to?(:"#{resource}_count")
    return true unless current_count

    current_count < limit
  end

  def track_ai_response!(count = 1)
    current_usage.increment_ai_responses!(count)
  end

  def track_voice_note!(count = 1)
    current_usage.increment_voice_notes!(count)
  end

  def usage_summary
    plan = active_plan
    usage = current_usage

    {
      ai_responses_count: usage.ai_responses_count,
      ai_responses_limit: plan&.ai_response_limit,
      voice_notes_count: usage.voice_notes_count,
      period_date: usage.period_date,
      usage_percentage: plan ? (usage.ai_responses_count.to_f / plan.ai_response_limit * 100).round(1) : nil
    }
  end

  # ── Subscription Lifecycle ─────────────────────────────────────

  def checkout_url(plan_key, success_url:, cancel_url:)
    plan = PlanConfig.find(plan_key)
    ensure_payment_processor!

    session = payment_processor.checkout(
      mode: "subscription",
      line_items: [{ price: plan.stripe_price_id, quantity: 1 }],
      allow_promotion_codes: true,  # customers can enter promo codes at checkout
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: { account_id: id, plan_key: plan_key }
    )
    session.url
  end

  def billing_portal_url(return_url:)
    ensure_payment_processor!
    session = payment_processor.billing_portal(return_url: return_url)
    session.url
  end

  def swap_plan!(plan_key)
    plan = PlanConfig.find(plan_key)
    sub = active_subscription
    raise "No active subscription to swap" unless sub

    sub.swap(plan.stripe_price_id)
    sync_plan_features!
  end

  def cancel_subscription!
    sub = active_subscription
    raise "No active subscription to cancel" unless sub

    sub.cancel
  end

  def resume_subscription!
    sub = active_subscription
    raise "No active subscription to resume" unless sub

    sub.resume
  end

  # ── Plan ↔ Feature Sync (called from webhooks) ────────────────

  def sync_plan_features!
    plan = active_plan

    if plan
      # Sync feature flags from plan config → Account#feature_flags
      plan.features.each do |feature_key, enabled|
        flag_name = plan_feature_to_flag(feature_key)
        next unless flag_name

        enabled ? enable_features(flag_name) : disable_features(flag_name)
      end

      # Sync limits into Account#limits jsonb
      self.limits = (limits || {}).merge(
        "ai_responses_per_month" => plan.ai_response_limit,
        "knowledge_base_documents" => plan.kb_document_limit
      )
    else
      # No plan — clear premium features
      disable_features(:crm)
      self.limits = (limits || {}).except("ai_responses_per_month", "knowledge_base_documents")
    end

    save!
  end

  # ── Feature Gating (plan-aware) ────────────────────────────────

  def plan_feature_available?(feature_key)
    plan = active_plan
    return true unless plan # legacy accounts — no restrictions

    plan.feature_enabled?(feature_key)
  end

  # ── Admin Toolkit ──────────────────────────────────────────────
  # These methods are for super admin use (console + admin UI).
  # They hide: fake_processor setup, trial timestamp math, Stripe
  # coupon API, subscription schedule creation, plan sync.
  #
  # Every method is a one-liner from rails console — the admin UI
  # just calls these same methods via controller actions.

  # Grant a free trial for N days without requiring a credit card.
  # Uses pay's fake_processor so no Stripe customer is created.
  #
  #   account.grant_trial!(days: 14)
  #   account.grant_trial!(days: 30, plan_key: "pro_monthly")
  #
  def grant_trial!(days:, plan_key: "pro_monthly")
    plan = PlanConfig.find(plan_key)
    trial_end = days.days.from_now

    set_payment_processor :fake_processor, allow_fake: true
    payment_processor.subscribe(
      plan: plan.stripe_price_id,
      trial_ends_at: trial_end,
      ends_at: trial_end
    )
    sync_plan_features!
  end

  # Extend an existing trial (or subscription period) by N days.
  # Works with both fake_processor and Stripe subscriptions.
  #
  #   account.extend_trial!(days: 30)
  #
  def extend_trial!(days:)
    sub = active_subscription
    raise "No active subscription to extend" unless sub

    new_end = (sub.ends_at || sub.trial_ends_at || Time.current) + days.days

    if sub.customer.processor == "fake_processor"
      sub.update!(trial_ends_at: new_end, ends_at: new_end)
    else
      # Stripe: update trial_end on the Stripe subscription, then sync
      ::Stripe::Subscription.update(sub.processor_id, { trial_end: new_end.to_i })
      sub.sync!
    end
  end

  # Grant a complimentary (free forever) subscription.
  # Uses fake_processor — no billing, no expiration.
  #
  #   account.grant_complimentary!(plan_key: "pro_annual")
  #
  def grant_complimentary!(plan_key: "pro_monthly")
    plan = PlanConfig.find(plan_key)

    # Cancel any existing subscription first
    active_subscription&.cancel_now! if active_subscription&.active?

    set_payment_processor :fake_processor, allow_fake: true
    payment_processor.subscribe(plan: plan.stripe_price_id)
    sync_plan_features!
  end

  # Apply a Stripe coupon to an existing Stripe subscription.
  # The coupon must already exist in Stripe Dashboard.
  #
  #   account.apply_coupon!("SUMMER50")         # 50% off coupon
  #   account.apply_coupon!("FREE3MONTHS")      # 100% off for 3 months
  #
  def apply_coupon!(coupon_id)
    sub = active_subscription
    raise "No active subscription" unless sub
    raise "Coupons only work with Stripe subscriptions" unless sub.customer.processor == "stripe"

    ::Stripe::Subscription.update(sub.processor_id, { discounts: [{ coupon: coupon_id }] })
    sub.sync!
  end

  # Override the plan for this account (admin force-assign).
  # Cancels any existing subscription and creates a new one.
  #
  #   account.override_plan!("pro_annual")                 # complimentary
  #   account.override_plan!("pro_monthly", stripe: true)  # real Stripe sub (if card on file)
  #
  def override_plan!(plan_key, stripe: false)
    plan = PlanConfig.find(plan_key)

    active_subscription&.cancel_now! if active_subscription&.active?

    if stripe
      ensure_payment_processor!
      payment_processor.subscribe(plan: plan.stripe_price_id)
    else
      set_payment_processor :fake_processor, allow_fake: true
      payment_processor.subscribe(plan: plan.stripe_price_id)
    end

    sync_plan_features!
  end

  # Add bonus AI credits without changing the plan. Stored as a negative
  # offset on the usage record so within_ai_limit? automatically accounts for it.
  #
  #   account.add_bonus_credits!(5000)  # 5000 extra AI responses this month
  #
  def add_bonus_credits!(amount)
    usage = current_usage
    usage.update!(bonus_credits: (usage.bonus_credits || 0) + amount)
  end

  # Reset AI usage counters for the current billing period.
  #
  #   account.reset_usage!
  #
  def reset_usage!
    current_usage.update!(ai_responses_count: 0, voice_notes_count: 0)
  end

  # Suspend account due to prolonged payment failure.
  # Called by webhook handler when subscription goes unpaid past grace period.
  #
  #   account.suspend_for_nonpayment!
  #
  def suspend_for_nonpayment!
    update!(status: :suspended)
    # Store reason in custom_attributes for admin visibility
    self.custom_attributes = (custom_attributes || {}).merge(
      "suspension_reason" => "nonpayment",
      "suspended_at" => Time.current.iso8601
    )
    save!
  end

  # Reactivate a suspended account after payment succeeds.
  # Called by webhook handler on charge.succeeded for past_due accounts.
  #
  #   account.reactivate_after_payment!
  #
  def reactivate_after_payment!
    return unless suspended? && custom_attributes&.dig("suspension_reason") == "nonpayment"

    update!(status: :active)
    self.custom_attributes = (custom_attributes || {}).except("suspension_reason", "suspended_at")
    save!
    sync_plan_features!
  end

  # Full billing status snapshot for admin dashboards.
  #
  #   account.billing_status
  #   # => { plan_name: "Pro", plan_tier: "pro", subscription_status: "active",
  #   #      processor: "stripe", current_period_end: ..., trial_ends_at: ...,
  #   #      is_complimentary: false, usage: { ... } }
  #
  def billing_status
    sub = active_subscription
    plan = active_plan

    {
      plan_name: plan&.name,
      plan_key: plan&.key,
      plan_tier: plan&.tier,
      subscription_status: sub&.status,
      processor: sub&.customer&.processor,
      is_complimentary: sub&.customer&.processor == "fake_processor",
      current_period_end: sub&.current_period_end,
      trial_ends_at: sub&.trial_ends_at,
      ends_at: sub&.ends_at,
      on_grace_period: sub&.on_grace_period? || false,
      usage: usage_summary
    }
  end

  private

  def ensure_payment_processor!
    set_payment_processor(:stripe) unless payment_processor
  end

  def stripe_attributes(_pay_customer)
    {
      name: name,
      email: billing_email,
      metadata: { account_id: id }
    }
  end

  def billing_email
    support_email.presence || administrators.first&.email
  end

  def administrators
    users.joins(:account_users).where(account_users: { role: :administrator })
  end

  # Maps plan feature keys (from plans.yml) to Account feature flag names (from features.yml)
  def plan_feature_to_flag(feature_key)
    # Only map features that exist in Account#feature_flags (FlagShihTzu)
    mapping = {
      crm_integration: :crm
      # Add mappings as new plan-gated features are introduced
    }
    mapping[feature_key]
  end
end
```

### 3.6 Include Billable on Account

**Modify: `app/models/account.rb`** — add one line:

```ruby
class Account < ApplicationRecord
  include Billable
  # ... existing includes and code ...
end
```

> **No other changes to `account.rb`.** The concern encapsulates everything.

---

## 4. Phase 2 — Stripe Configuration

### 4.1 Stripe Dashboard

Create in Stripe Dashboard (or via API):

1. **Product: "AlooChat Basic"**
   - Price: 60 KWD/month (recurring) → save as `STRIPE_BASIC_MONTHLY_PRICE_ID`
   - Price: 600 KWD/year (recurring) → save as `STRIPE_BASIC_ANNUAL_PRICE_ID`

2. **Product: "AlooChat Pro"**
   - Price: 75 KWD/month (recurring) → save as `STRIPE_PRO_MONTHLY_PRICE_ID`
   - Price: 900 KWD/year (recurring) → save as `STRIPE_PRO_ANNUAL_PRICE_ID`

> **Currency note:** KWD has 3 decimal places in Stripe. 60 KWD = 60000 fils.

### 4.2 Stripe Webhooks

Endpoint URL: `https://app.aloochat.com/pay/webhooks/stripe`

Events: `checkout.session.completed`, `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `customer.subscription.trial_will_end`, `invoice.payment_action_required`, `invoice.payment_failed`, `charge.succeeded`, `charge.refunded`, `customer.updated`, `customer.deleted`, `payment_method.attached`, `payment_method.updated`, `payment_method.detached`.

### 4.3 Remove Existing Dead Webhook Route

The existing `POST /webhooks/stripe` route (config/routes.rb ~line 586) points to a non-existent controller. Remove it — pay gem auto-mounts at `/pay/webhooks/stripe`.

---

## 5. Phase 3 — API Layer (Thin Controllers)

Controllers are thin delegates per CLAUDE.md. They call methods on `Current.account` (which include `Billable`) and render the result.

### 5.1 Routes

**Modify: `config/routes.rb`** — inside the existing `scope module: :accounts` block:

```ruby
# Billing
resource :subscription, only: [:show] do
  post :checkout, on: :collection
  post :portal, on: :member
  post :swap, on: :member
  post :cancel, on: :member
  post :resume, on: :member
end
```

This produces:
- `GET    /api/v1/accounts/:account_id/subscription`
- `POST   /api/v1/accounts/:account_id/subscription/checkout`
- `POST   /api/v1/accounts/:account_id/subscription/portal`
- `POST   /api/v1/accounts/:account_id/subscription/swap`
- `POST   /api/v1/accounts/:account_id/subscription/cancel`
- `POST   /api/v1/accounts/:account_id/subscription/resume`

### 5.2 Subscriptions Controller

**New file: `app/controllers/api/v1/accounts/subscriptions_controller.rb`**

Thin controller — all depth lives in the `Billable` concern.

```ruby
class Api::V1::Accounts::SubscriptionsController < Api::V1::Accounts::BaseController
  before_action :authorize_billing

  def show
    render json: {
      subscription: subscription_payload,
      plan: Current.account.active_plan&.to_h,
      usage: Current.account.usage_summary,
      plans: PlanConfig.all.map(&:to_h)
    }
  end

  def checkout
    url = Current.account.checkout_url(
      params[:plan_key],
      success_url: billing_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: billing_url(cancelled: true)
    )
    render json: { checkout_url: url }
  end

  def portal
    url = Current.account.billing_portal_url(return_url: billing_url)
    render json: { portal_url: url }
  end

  def swap
    Current.account.swap_plan!(params[:plan_key])
    render json: { message: "Plan updated" }
  end

  def cancel
    Current.account.cancel_subscription!
    render json: { message: "Subscription will cancel at period end" }
  end

  def resume
    Current.account.resume_subscription!
    render json: { message: "Subscription resumed" }
  end

  private

  def authorize_billing
    authorize Current.account, :manage_billing?
  end

  def billing_url(**query)
    base = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{Current.account.id}/settings/billing"
    query.any? ? "#{base}?#{query.to_query}" : base
  end

  def subscription_payload
    sub = Current.account.active_subscription
    return nil unless sub

    {
      status: sub.status,
      current_period_end: sub.current_period_end,
      trial_ends_at: sub.trial_ends_at,
      ends_at: sub.ends_at,
      on_grace_period: sub.on_grace_period?,
      processor_plan: sub.processor_plan
    }
  end
end
```

### 5.3 Account Policy

**Modify: `app/policies/account_policy.rb`** — add one method:

```ruby
def manage_billing?
  @account_user.administrator?
end
```

### 5.4 Jbuilder View (optional)

If you prefer Jbuilder (matching existing patterns), create `app/views/api/v1/accounts/subscriptions/show.json.jbuilder`. But for billing, inline `render json:` is simpler since the shape is unique and not reused.

---

## 6. Phase 4 — Frontend

### 6.1 API Client

**New file: `app/javascript/dashboard/api/billing.js`**

Follows existing `ApiClient` pattern (see `api/agents.js`).

```javascript
import ApiClient from './ApiClient';

class BillingAPI extends ApiClient {
  constructor() {
    super('subscription', { accountScoped: true });
  }

  getSubscription() {
    return axios.get(this.url);
  }

  createCheckout(planKey) {
    return axios.post(`${this.url}/checkout`, { plan_key: planKey });
  }

  getPortalUrl() {
    return axios.post(`${this.url}/portal`);
  }

  swapPlan(planKey) {
    return axios.post(`${this.url}/swap`, { plan_key: planKey });
  }

  cancel() {
    return axios.post(`${this.url}/cancel`);
  }

  resume() {
    return axios.post(`${this.url}/resume`);
  }
}

export default new BillingAPI();
```

### 6.2 Pinia Store

**New file: `app/javascript/dashboard/stores/billing.js`**

```javascript
import { defineStore } from 'pinia';
import BillingAPI from 'dashboard/api/billing';

export const useBillingStore = defineStore('billing', {
  state: () => ({
    subscription: null,
    plan: null,
    usage: null,
    plans: [],
    uiFlags: {
      isFetching: false,
      isCheckingOut: false,
    },
  }),

  getters: {
    isSubscribed: state => state.subscription?.status === 'active',
    planTier: state => state.plan?.tier || null,
    usagePercentage: state => state.usage?.usage_percentage || 0,
  },

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const { data } = await BillingAPI.getSubscription();
        this.subscription = data.subscription;
        this.plan = data.plan;
        this.usage = data.usage;
        this.plans = data.plans;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async checkout(planKey) {
      this.uiFlags.isCheckingOut = true;
      try {
        const { data } = await BillingAPI.createCheckout(planKey);
        window.location.href = data.checkout_url;
      } finally {
        this.uiFlags.isCheckingOut = false;
      }
    },

    async openPortal() {
      const { data } = await BillingAPI.getPortalUrl();
      window.location.href = data.portal_url;
    },

    async swapPlan(planKey) {
      await BillingAPI.swapPlan(planKey);
      await this.fetch();
    },

    async cancel() {
      await BillingAPI.cancel();
      await this.fetch();
    },

    async resume() {
      await BillingAPI.resume();
      await this.fetch();
    },
  },
});
```

### 6.3 Frontend Pages

All new components go in `components-next/` with `<script setup>`, Tailwind-only, no `<style>` blocks.

```
app/javascript/dashboard/routes/dashboard/settings/billing/
├── billing.routes.js
├── Index.vue                    # Main billing page
├── components/
│   ├── PlanSelector.vue         # Plan cards + monthly/annual toggle
│   ├── CurrentPlanCard.vue      # Current plan + status + renewal date
│   └── UsageBar.vue             # AI response usage progress bar
```

**Route definition — `billing.routes.js`:**

```javascript
import { frontendURL } from 'dashboard/helper/URLHelper';

const billing = accountId => ({
  routes: [
    {
      path: frontendURL(`accounts/${accountId}/settings/billing`),
      name: 'billing_settings',
      meta: {
        permissions: ['administrator'],
      },
      component: () => import('./Index.vue'),
    },
  ],
});

export default billing;
```

**Index.vue — skeleton:**

```vue
<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useBillingStore } from 'dashboard/stores/billing';
import CurrentPlanCard from './components/CurrentPlanCard.vue';
import PlanSelector from './components/PlanSelector.vue';

const { t } = useI18n();
const billingStore = useBillingStore();

onMounted(() => billingStore.fetch());
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <h1 class="text-xl font-semibold text-slate-900 dark:text-white">
      {{ t('BILLING.TITLE') }}
    </h1>
    <CurrentPlanCard
      :subscription="billingStore.subscription"
      :plan="billingStore.plan"
      :usage="billingStore.usage"
      @manage-billing="billingStore.openPortal()"
      @cancel="billingStore.cancel()"
      @resume="billingStore.resume()"
    />
    <PlanSelector
      :plans="billingStore.plans"
      :current-plan="billingStore.plan"
      :is-checking-out="billingStore.uiFlags.isCheckingOut"
      @select="billingStore.checkout($event)"
    />
  </div>
</template>
```

### 6.4 Sidebar Navigation

**Modify: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`**

Add a "Billing" entry under Settings, visible only to administrators.

### 6.5 i18n

**Add billing keys to `app/javascript/dashboard/i18n/locale/en/settings.json`:**

```json
{
  "BILLING": {
    "TITLE": "Billing & Subscription",
    "CURRENT_PLAN": "Current Plan",
    "NO_PLAN": "No active plan",
    "SELECT_PLAN": "Select a Plan",
    "MONTHLY": "Monthly",
    "ANNUAL": "Annual",
    "PER_MONTH": "/month",
    "PER_YEAR": "/year",
    "AI_RESPONSES": "AI Responses",
    "KNOWLEDGE_BASE": "Knowledge Base Documents",
    "USAGE": "Usage This Month",
    "MANAGE_BILLING": "Manage Billing",
    "CANCEL": "Cancel Subscription",
    "RESUME": "Resume Subscription",
    "UPGRADE": "Upgrade to Pro",
    "CURRENT": "Current Plan",
    "SUBSCRIBE": "Subscribe",
    "CONFIRM_CANCEL": "Are you sure you want to cancel? You keep access until the billing period ends."
  }
}
```

---

## 7. Phase 5 — Webhooks, Plan Sync & Auto-Suspend

### 7.1 What Pay Gem Handles Automatically

The pay gem processes these webhook events and updates `pay_subscriptions`, `pay_charges`, `pay_payment_methods` automatically. No code needed.

### 7.2 Custom Webhook Handlers

All handlers are lambdas in a single initializer. Each calls one deep method on `Billable`. No separate handler classes.

**New file: `config/initializers/pay_webhooks.rb`**

```ruby
ActiveSupport.on_load(:pay) do
  # ── Plan sync: subscription created/updated/deleted ────────────
  # All three events need the same action: re-sync features from the current plan.
  plan_sync = ->(event) {
    account = event.data.customer&.owner
    next unless account.is_a?(Account)

    account.sync_plan_features!
  }

  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.created", plan_sync
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.updated", plan_sync
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.deleted", plan_sync

  # ── Auto-suspend: payment failed after grace period ────────────
  # Stripe fires invoice.payment_failed on each retry (3 retries over ~3 weeks).
  # We suspend on the final failure (when subscription status becomes "unpaid").
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.updated", ->(event) {
    pay_sub = event.data
    account = pay_sub.customer&.owner
    next unless account.is_a?(Account)

    if pay_sub.status == "unpaid"
      account.suspend_for_nonpayment!
      BillingMailer.account_suspended(account).deliver_later
    end
  }

  # ── Auto-reactivate: payment succeeds on past_due account ─────
  Pay::Webhooks.delegator.subscribe "stripe.charge.succeeded", ->(event) {
    pay_charge = event.data
    account = pay_charge.customer&.owner
    next unless account.is_a?(Account) && account.suspended?

    account.reactivate_after_payment!
    BillingMailer.account_reactivated(account).deliver_later
  }

  # ── Welcome email: first successful checkout ───────────────────
  Pay::Webhooks.delegator.subscribe "stripe.checkout.session.completed", ->(event) {
    pay_charge = event.data
    account = pay_charge.customer&.owner
    next unless account.is_a?(Account)

    account.sync_plan_features!
    BillingMailer.welcome_to_plan(account).deliver_later
  }
end
```

> **Why lambdas, not 6 handler classes?** Each lambda calls 1-2 methods on `Billable` or `BillingMailer`. Creating `SubscriptionCreatedHandler`, `PaymentFailedHandler`, `ChargeSucceededHandler` etc. that each wrap a single method call would be textbook shallow modules per CLAUDE.md.

---

## 8. Phase 6 — Super Admin Billing Toolkit

The super admin needs full control over customer billing: grant trials, give free months, apply discounts, override plans, and view billing status across all accounts. All of these are methods on the `Billable` concern (Section 3.5), so the admin UI is just a thin form that calls the same methods available in `rails console`.

### 8.1 What the Super Admin Can Do

| Action | Method | Use Case |
|--------|--------|----------|
| **Grant free trial** | `account.grant_trial!(days: 30)` | New customer wants to try before buying |
| **Extend trial** | `account.extend_trial!(days: 14)` | Customer needs more time to evaluate |
| **Give free subscription** | `account.grant_complimentary!(plan_key: "pro_annual")` | Partner, investor, internal team |
| **Apply discount coupon** | `account.apply_coupon!("RAMADAN50")` | Seasonal offer, loyalty discount |
| **Force assign plan** | `account.override_plan!("pro_monthly")` | Fix billing issues, special deals |
| **Add bonus AI credits** | `account.add_bonus_credits!(5000)` | Goodwill, promotion, outage compensation |
| **Reset usage counters** | `account.reset_usage!` | Goodwill gesture after outage |
| **Suspend for nonpayment** | `account.suspend_for_nonpayment!` | Auto-triggered by webhook, or manual |
| **Reactivate after payment** | `account.reactivate_after_payment!` | Auto-triggered by webhook, or manual |
| **View billing status** | `account.billing_status` | Debug / support ticket |
| **Cancel subscription** | `account.cancel_subscription!` | Customer request via support |
| **Swap plan** | `account.swap_plan!("basic_annual")` | Customer request via support |

### 8.2 Admin Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│  Super Admin > Accounts > Account #42                                │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  BILLING STATUS                                                │  │
│  │  Plan: Pro (Monthly)  •  Status: active  •  Via: Stripe        │  │
│  │  Renews: April 3, 2026  •  Usage: 12,450 / 25,000 (49.8%)     │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  ADMIN ACTIONS                                                 │  │
│  │                                                                │  │
│  │  [Grant Trial]  Duration: [14] days  Plan: [Pro ▼]  [Apply]   │  │
│  │                                                                │  │
│  │  [Extend Trial] Additional days: [30]               [Apply]   │  │
│  │                                                                │  │
│  │  [Give Free Plan]  Plan: [Pro Annual ▼]             [Apply]   │  │
│  │                                                                │  │
│  │  [Apply Coupon]  Coupon ID: [________]              [Apply]   │  │
│  │                                                                │  │
│  │  [Override Plan]  Plan: [Basic Monthly ▼]           [Apply]   │  │
│  │                                                                │  │
│  │  [Reset Usage]  [Cancel Subscription]  [Swap Plan]            │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 8.3 Stripe Coupons (Created in Stripe Dashboard)

Coupons are created once in the Stripe Dashboard and then applied to accounts by the super admin. Common coupon patterns:

| Coupon ID | Type | Duration | Use Case |
|-----------|------|----------|----------|
| `RAMADAN50` | 50% off | 1 month | Seasonal offer |
| `PARTNER100` | 100% off | Forever | Partners/investors |
| `FREE3MONTHS` | 100% off | 3 months | Onboarding incentive |
| `LOYALTY20` | 20% off | Forever | Long-term customer retention |
| `LAUNCH25` | 25 KD off | 6 months | Launch promotion |

```ruby
# Create coupons via Stripe API (one-time setup, or via Stripe Dashboard):
Stripe::Coupon.create(id: "RAMADAN50", percent_off: 50, duration: "once")
Stripe::Coupon.create(id: "PARTNER100", percent_off: 100, duration: "forever")
Stripe::Coupon.create(id: "FREE3MONTHS", percent_off: 100, duration: "repeating", duration_in_months: 3)
Stripe::Coupon.create(id: "LOYALTY20", percent_off: 20, duration: "forever")
Stripe::Coupon.create(id: "LAUNCH25", amount_off: 25000, currency: "kwd", duration: "repeating", duration_in_months: 6)
```

### 8.4 Administrate Dashboard Changes

**Modify: `app/dashboards/account_dashboard.rb`**

Add billing fields to the existing Administrate dashboard.

```ruby
# Add to ATTRIBUTE_TYPES:
billing_plan: Field::String.with_options(getter: ->(field) { field.resource.active_plan&.name || "None" }),
billing_status: Field::String.with_options(getter: ->(field) { field.resource.active_subscription&.status || "No subscription" }),
billing_processor: Field::String.with_options(getter: ->(field) { field.resource.active_subscription&.customer&.processor || "—" }),
ai_usage: Field::String.with_options(getter: ->(field) {
  s = field.resource.usage_summary
  s[:ai_responses_limit] ? "#{s[:ai_responses_count]} / #{s[:ai_responses_limit]}" : "—"
}),

# Add to COLLECTION_ATTRIBUTES (accounts list):
COLLECTION_ATTRIBUTES = %i[id name locale users conversations status billing_plan billing_status].freeze

# Add to SHOW_PAGE_ATTRIBUTES:
SHOW_PAGE_ATTRIBUTES = %i[
  id name created_at updated_at locale status conversations account_users
  billing_plan billing_status billing_processor ai_usage
].freeze
```

### 8.5 Super Admin Controller Actions

**Modify: `app/controllers/super_admin/accounts_controller.rb`**

Add custom actions for billing management. Each action is a thin delegate to a `Billable` method.

```ruby
class SuperAdmin::AccountsController < SuperAdmin::ApplicationController
  # ... existing code ...

  def grant_trial
    account = Account.find(params[:id])
    account.grant_trial!(days: params[:days].to_i, plan_key: params[:plan_key])
    redirect_back(fallback_location: [namespace, account], notice: "Trial granted: #{params[:days]} days on #{params[:plan_key]}")
  end

  def extend_trial
    account = Account.find(params[:id])
    account.extend_trial!(days: params[:days].to_i)
    redirect_back(fallback_location: [namespace, account], notice: "Trial extended by #{params[:days]} days")
  end

  def grant_complimentary
    account = Account.find(params[:id])
    account.grant_complimentary!(plan_key: params[:plan_key])
    redirect_back(fallback_location: [namespace, account], notice: "Complimentary #{params[:plan_key]} plan granted")
  end

  def apply_coupon
    account = Account.find(params[:id])
    account.apply_coupon!(params[:coupon_id])
    redirect_back(fallback_location: [namespace, account], notice: "Coupon #{params[:coupon_id]} applied")
  end

  def override_plan
    account = Account.find(params[:id])
    account.override_plan!(params[:plan_key])
    redirect_back(fallback_location: [namespace, account], notice: "Plan overridden to #{params[:plan_key]}")
  end

  def add_bonus_credits
    account = Account.find(params[:id])
    account.add_bonus_credits!(params[:amount].to_i)
    redirect_back(fallback_location: [namespace, account], notice: "#{params[:amount]} bonus AI credits added")
  end

  def reset_usage
    account = Account.find(params[:id])
    account.reset_usage!
    redirect_back(fallback_location: [namespace, account], notice: "Usage counters reset")
  end

  def cancel_subscription
    account = Account.find(params[:id])
    account.cancel_subscription!
    redirect_back(fallback_location: [namespace, account], notice: "Subscription cancelled")
  end

  def reactivate
    account = Account.find(params[:id])
    account.reactivate_after_payment!
    redirect_back(fallback_location: [namespace, account], notice: "Account reactivated")
  end
end
```

### 8.6 Super Admin Routes

**Modify: `config/routes.rb`** — add member actions to the existing super_admin accounts resource:

```ruby
resources :accounts, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
  post :seed, on: :member
  post :reset_cache, on: :member
  # Billing admin actions
  post :grant_trial, on: :member
  post :extend_trial, on: :member
  post :grant_complimentary, on: :member
  post :apply_coupon, on: :member
  post :override_plan, on: :member
  post :add_bonus_credits, on: :member
  post :reset_usage, on: :member
  post :cancel_subscription, on: :member
  post :reactivate, on: :member
end
```

### 8.7 Admin View Partial

**New file: `app/views/super_admin/accounts/_billing_actions.html.erb`**

Rendered on the account show page. Each form is a single button/input that POSTs to a member action.

```erb
<section class="billing-admin">
  <h3>Billing Management</h3>

  <div class="billing-status">
    <% status = page.resource.billing_status %>
    <p><strong>Plan:</strong> <%= status[:plan_name] || "None" %> (<%= status[:plan_tier] || "—" %>)</p>
    <p><strong>Status:</strong> <%= status[:subscription_status] || "No subscription" %></p>
    <p><strong>Processor:</strong> <%= status[:processor] || "—" %></p>
    <p><strong>Complimentary:</strong> <%= status[:is_complimentary] ? "Yes" : "No" %></p>
    <% if status[:trial_ends_at] %>
      <p><strong>Trial ends:</strong> <%= status[:trial_ends_at]&.strftime("%B %d, %Y") %></p>
    <% end %>
    <% if status[:usage] %>
      <p><strong>AI Usage:</strong> <%= status[:usage][:ai_responses_count] %> / <%= status[:usage][:ai_responses_limit] || "∞" %></p>
    <% end %>
  </div>

  <hr>

  <!-- Grant Trial -->
  <%= form_tag grant_trial_super_admin_account_path(page.resource), method: :post do %>
    <label>Grant Free Trial:</label>
    <%= number_field_tag :days, 14, min: 1, max: 365 %> days
    <%= select_tag :plan_key, options_for_select(PlanConfig.all.map { |p| [p.name + " (#{p.interval})", p.key] }) %>
    <%= submit_tag "Grant Trial" %>
  <% end %>

  <!-- Extend Trial -->
  <%= form_tag extend_trial_super_admin_account_path(page.resource), method: :post do %>
    <label>Extend Trial:</label>
    <%= number_field_tag :days, 30, min: 1, max: 365 %> additional days
    <%= submit_tag "Extend" %>
  <% end %>

  <!-- Complimentary Plan -->
  <%= form_tag grant_complimentary_super_admin_account_path(page.resource), method: :post do %>
    <label>Grant Free Plan:</label>
    <%= select_tag :plan_key, options_for_select(PlanConfig.all.map { |p| [p.name + " (#{p.interval})", p.key] }) %>
    <%= submit_tag "Grant Complimentary" %>
  <% end %>

  <!-- Apply Coupon -->
  <% if page.resource.active_subscription&.customer&.processor == "stripe" %>
    <%= form_tag apply_coupon_super_admin_account_path(page.resource), method: :post do %>
      <label>Apply Stripe Coupon:</label>
      <%= text_field_tag :coupon_id, nil, placeholder: "e.g. RAMADAN50" %>
      <%= submit_tag "Apply Coupon" %>
    <% end %>
  <% end %>

  <!-- Override Plan -->
  <%= form_tag override_plan_super_admin_account_path(page.resource), method: :post do %>
    <label>Override Plan:</label>
    <%= select_tag :plan_key, options_for_select(PlanConfig.all.map { |p| [p.name + " (#{p.interval})", p.key] }) %>
    <%= submit_tag "Override" %>
  <% end %>

  <!-- Bonus Credits -->
  <%= form_tag add_bonus_credits_super_admin_account_path(page.resource), method: :post do %>
    <label>Add Bonus AI Credits:</label>
    <%= number_field_tag :amount, 1000, min: 1, max: 100000 %> responses
    <%= submit_tag "Add Credits" %>
  <% end %>

  <!-- Quick Actions -->
  <div class="quick-actions">
    <%= button_to "Reset Usage", reset_usage_super_admin_account_path(page.resource), method: :post,
        data: { confirm: "Reset AI usage counters to zero?" } %>

    <% if page.resource.active_subscription&.active? %>
      <%= button_to "Cancel Subscription", cancel_subscription_super_admin_account_path(page.resource), method: :post,
          data: { confirm: "Cancel this account's subscription?" } %>
    <% end %>

    <% if page.resource.suspended? && page.resource.custom_attributes&.dig("suspension_reason") == "nonpayment" %>
      <%= button_to "Reactivate Account", reactivate_super_admin_account_path(page.resource), method: :post,
          data: { confirm: "Reactivate this account?" } %>
    <% end %>
  </div>
</section>
```

### 8.8 Design Rationale: Why Admin Methods Live on the Concern

```
# ❌ SHALLOW — separate AdminBillingService that just delegates
class AdminBillingService
  def initialize(account) = @account = account
  def grant_trial(days:)
    @account.set_payment_processor :fake_processor, allow_fake: true
    @account.payment_processor.subscribe(trial_ends_at: days.days.from_now, ...)
    @account.sync_plan_features!
  end
end
# This class adds nothing — the controller could call the 3 lines directly.

# ✅ DEEP — method on Billable hides fake_processor setup, timestamp math,
#           plan resolution, and feature sync behind one call
account.grant_trial!(days: 30)
# The controller calls this one method. The concern hides all orchestration.
```

The admin actions are **part of the billing domain**, not a separate module. They belong on `Billable` because they modify the same state (subscriptions, features, usage) through the same abstractions (pay gem, PlanConfig, feature flags). Extracting them into a separate `AdminBillingService` would be the "shallow wrapper" anti-pattern from CLAUDE.md.

---

## 9. Phase 7 — Billing Notifications & Mailer

### 9.1 BillingMailer

**New file: `app/mailers/billing_mailer.rb`**

Uses the existing Liquid template infrastructure. Each method sends one type of billing notification.

```ruby
class BillingMailer < ApplicationMailer
  def trial_expiring(account, days_remaining:)
    @account = account
    @days_remaining = days_remaining
    @plan = account.active_plan

    send_billing_email(
      to: account.billing_email,
      subject: "Your AlooChat trial ends in #{days_remaining} days"
    )
  end

  def trial_expired(account)
    @account = account
    send_billing_email(
      to: account.billing_email,
      subject: "Your AlooChat trial has ended — choose a plan"
    )
  end

  def payment_failed(account)
    @account = account
    send_billing_email(
      to: account.billing_email,
      subject: "Action required: payment failed for your AlooChat subscription"
    )
  end

  def usage_warning(account, percentage:)
    @account = account
    @percentage = percentage
    @usage = account.usage_summary

    send_billing_email(
      to: account.billing_email,
      subject: "You've used #{percentage.to_i}% of your monthly AI responses"
    )
  end

  def usage_limit_reached(account)
    @account = account
    @usage = account.usage_summary

    send_billing_email(
      to: account.billing_email,
      subject: "Monthly AI response limit reached"
    )
  end

  def welcome_to_plan(account)
    @account = account
    @plan = account.active_plan

    send_billing_email(
      to: account.billing_email,
      subject: "Welcome to AlooChat #{@plan&.name || 'Plan'}!"
    )
  end

  def plan_changed(account, old_plan_name:)
    @account = account
    @old_plan_name = old_plan_name
    @new_plan = account.active_plan

    send_billing_email(
      to: account.billing_email,
      subject: "Your AlooChat plan has been changed to #{@new_plan&.name}"
    )
  end

  def account_suspended(account)
    @account = account
    send_billing_email(
      to: account.billing_email,
      subject: "Your AlooChat account has been suspended — update payment method"
    )
  end

  def account_reactivated(account)
    @account = account
    send_billing_email(
      to: account.billing_email,
      subject: "Your AlooChat account has been reactivated"
    )
  end

  def coupon_applied(account, coupon_id:)
    @account = account
    @coupon_id = coupon_id

    send_billing_email(
      to: account.billing_email,
      subject: "A discount has been applied to your AlooChat account"
    )
  end

  private

  def send_billing_email(to:, subject:)
    return if to.blank?

    mail(to: to, subject: subject)
  end
end
```

### 9.2 BillingNotificationJob (Daily Cron)

**New file: `app/jobs/billing_notification_job.rb`**

Runs daily via sidekiq-cron or whenever. Checks for accounts that need billing notifications.

```ruby
# Job is thin glue (correct per CLAUDE.md) — delegates to Billable methods
# and BillingMailer for the actual work.
#
# Console usage:
#   BillingNotificationJob.perform_now  # run manually
#
class BillingNotificationJob < ApplicationJob
  queue_as :low

  def perform
    notify_expiring_trials
    notify_high_usage
    notify_expired_trials
  end

  private

  # Trials expiring in 3 days — send a heads-up email
  def notify_expiring_trials
    Pay::Subscription.where(
      "trial_ends_at BETWEEN ? AND ?",
      Time.current, 3.days.from_now
    ).find_each do |sub|
      account = sub.customer.owner
      next unless account.is_a?(Account) && account.active?

      days = ((sub.trial_ends_at - Time.current) / 1.day).ceil
      BillingMailer.trial_expiring(account, days_remaining: days).deliver_later
    end
  end

  # Trials that expired yesterday — nudge to subscribe
  def notify_expired_trials
    Pay::Subscription.where(
      "trial_ends_at BETWEEN ? AND ?",
      1.day.ago.beginning_of_day, 1.day.ago.end_of_day
    ).find_each do |sub|
      account = sub.customer.owner
      next unless account.is_a?(Account) && account.active?
      next if account.subscribed? # they already subscribed

      BillingMailer.trial_expired(account).deliver_later
    end
  end

  # Accounts at >80% AI usage — warn them
  def notify_high_usage
    Account.active.find_each do |account|
      next unless account.subscribed?

      summary = account.usage_summary
      next unless summary[:usage_percentage]

      if summary[:usage_percentage] >= 80 && summary[:usage_percentage] < 100
        BillingMailer.usage_warning(account, percentage: summary[:usage_percentage]).deliver_later
      elsif summary[:usage_percentage] >= 100
        BillingMailer.usage_limit_reached(account).deliver_later
      end
    end
  end
end
```

### 9.3 Cron Schedule

Add to your cron configuration (sidekiq-cron, whenever, or Procfile):

```yaml
# config/schedule.yml (sidekiq-cron) or equivalent
billing_notifications:
  cron: "0 9 * * *"  # daily at 9 AM
  class: BillingNotificationJob
  queue: low
```

### 9.4 i18n for Billing Emails

**Add to `config/locales/en.yml`:**

```yaml
en:
  billing_mailer:
    trial_expiring:
      subject: "Your AlooChat trial ends in %{days} days"
    trial_expired:
      subject: "Your AlooChat trial has ended"
    payment_failed:
      subject: "Action required: payment failed"
    usage_warning:
      subject: "You've used %{percentage}% of your AI responses"
    usage_limit_reached:
      subject: "Monthly AI response limit reached"
    welcome_to_plan:
      subject: "Welcome to AlooChat %{plan_name}!"
    account_suspended:
      subject: "Account suspended — update payment method"
    account_reactivated:
      subject: "Account reactivated"
```

---

## 10. Phase 8 — Admin Observability (Filters & Dashboard)

### 10.1 Administrate Collection Filters

**Modify: `app/dashboards/account_dashboard.rb`**

Add billing-specific filters so the admin can quickly find accounts by billing state.

```ruby
COLLECTION_FILTERS = {
  # Existing filters
  active: ->(resources) { resources.where(status: :active) },
  suspended: ->(resources) { resources.where(status: :suspended) },
  recent: ->(resources) { resources.where("created_at > ?", 30.days.ago) },

  # New billing filters
  subscribed: ->(resources) {
    resources.joins("INNER JOIN pay_customers ON pay_customers.owner_id = accounts.id AND pay_customers.owner_type = 'Account'")
             .joins("INNER JOIN pay_subscriptions ON pay_subscriptions.customer_id = pay_customers.id")
             .where(pay_subscriptions: { status: "active" })
             .distinct
  },
  on_trial: ->(resources) {
    resources.joins("INNER JOIN pay_customers ON pay_customers.owner_id = accounts.id AND pay_customers.owner_type = 'Account'")
             .joins("INNER JOIN pay_subscriptions ON pay_subscriptions.customer_id = pay_customers.id")
             .where("pay_subscriptions.trial_ends_at > ?", Time.current)
             .distinct
  },
  trial_expiring_soon: ->(resources) {
    resources.joins("INNER JOIN pay_customers ON pay_customers.owner_id = accounts.id AND pay_customers.owner_type = 'Account'")
             .joins("INNER JOIN pay_subscriptions ON pay_subscriptions.customer_id = pay_customers.id")
             .where("pay_subscriptions.trial_ends_at BETWEEN ? AND ?", Time.current, 7.days.from_now)
             .distinct
  },
  no_subscription: ->(resources) {
    resources.left_joins(:pay_customers).where(pay_customers: { id: nil })
  },
  past_due: ->(resources) {
    resources.joins("INNER JOIN pay_customers ON pay_customers.owner_id = accounts.id AND pay_customers.owner_type = 'Account'")
             .joins("INNER JOIN pay_subscriptions ON pay_subscriptions.customer_id = pay_customers.id")
             .where(pay_subscriptions: { status: "past_due" })
             .distinct
  },
  complimentary: ->(resources) {
    resources.joins("INNER JOIN pay_customers ON pay_customers.owner_id = accounts.id AND pay_customers.owner_type = 'Account'")
             .where(pay_customers: { processor: "fake_processor" })
             .distinct
  },
  high_usage: ->(resources) {
    # Accounts above 80% AI usage this month
    period = Time.current.beginning_of_month.to_date
    resources.joins("INNER JOIN account_usage_records ON account_usage_records.account_id = accounts.id")
             .where(account_usage_records: { period_date: period })
             .where("account_usage_records.ai_responses_count > 0")
             .distinct
  }
}.freeze
```

This gives the admin these one-click filters in the accounts list:

| Filter | What it shows |
|--------|--------------|
| **subscribed** | Paying customers |
| **on_trial** | Accounts currently in trial |
| **trial_expiring_soon** | Trials ending within 7 days (action needed) |
| **no_subscription** | Accounts with no plan (need nudging) |
| **past_due** | Failed payment — might need intervention |
| **complimentary** | Free accounts (partners, internal) |
| **high_usage** | Accounts with significant AI usage this month |

### 10.2 Billing Summary Metrics (Super Admin Dashboard)

**New file: `app/controllers/super_admin/billing_dashboard_controller.rb`**

A simple controller that computes billing metrics. Thin controller — queries are straightforward SQL aggregations.

```ruby
class SuperAdmin::BillingDashboardController < SuperAdmin::ApplicationController
  def show
    @metrics = {
      total_active_subscriptions: Pay::Subscription.where(status: "active").count,
      total_trials: Pay::Subscription.where("trial_ends_at > ?", Time.current).count,
      total_complimentary: Pay::Customer.where(processor: "fake_processor").count,
      trials_expiring_7_days: Pay::Subscription.where("trial_ends_at BETWEEN ? AND ?", Time.current, 7.days.from_now).count,
      past_due_subscriptions: Pay::Subscription.where(status: "past_due").count,
      suspended_for_nonpayment: Account.suspended.where("custom_attributes->>'suspension_reason' = ?", "nonpayment").count,
      mrr_charges_this_month: Pay::Charge.where("created_at >= ?", Time.current.beginning_of_month).sum(:amount),
      accounts_no_plan: Account.active.left_joins(:pay_customers).where(pay_customers: { id: nil }).count
    }
  end
end
```

**Route:**

```ruby
# Inside namespace :super_admin
resource :billing_dashboard, only: [:show], controller: 'billing_dashboard'
```

**View: `app/views/super_admin/billing_dashboard/show.html.erb`**

```erb
<h1>Billing Dashboard</h1>

<div class="metrics-grid">
  <div class="metric">
    <h3><%= @metrics[:total_active_subscriptions] %></h3>
    <p>Active Subscriptions</p>
  </div>
  <div class="metric">
    <h3><%= @metrics[:total_trials] %></h3>
    <p>Active Trials</p>
  </div>
  <div class="metric">
    <h3><%= @metrics[:total_complimentary] %></h3>
    <p>Complimentary</p>
  </div>
  <div class="metric alert">
    <h3><%= @metrics[:trials_expiring_7_days] %></h3>
    <p>Trials Expiring (7 days)</p>
  </div>
  <div class="metric alert">
    <h3><%= @metrics[:past_due_subscriptions] %></h3>
    <p>Past Due</p>
  </div>
  <div class="metric alert">
    <h3><%= @metrics[:suspended_for_nonpayment] %></h3>
    <p>Suspended (Nonpayment)</p>
  </div>
  <div class="metric">
    <h3><%= @metrics[:accounts_no_plan] %></h3>
    <p>Accounts Without Plan</p>
  </div>
  <div class="metric">
    <h3><%= number_to_currency(@metrics[:mrr_charges_this_month].to_f / 1000, unit: "KD ") %></h3>
    <p>Revenue This Month</p>
  </div>
</div>
```

---

## 11. Rails Console Playbook

Every billing operation is directly testable from `rails console`. This section serves as both documentation, testing checklist, and admin operations manual.

### 11.1 Basic Operations

```ruby
# ── Setup ────────────────────────────────────────────
account = Account.find(1)

# ── Plan inspection ──────────────────────────────────
PlanConfig.all.map(&:key)            # => ["basic_monthly", "basic_annual", "pro_monthly", "pro_annual"]
PlanConfig.find("pro_monthly")       # => #<PlanConfig key="pro_monthly" ...>
PlanConfig.find("pro_monthly").to_h  # => { key: "pro_monthly", name: "Pro", ... }

# ── Check current state ─────────────────────────────
account.subscribed?                  # => false
account.active_plan                  # => nil
account.plan_tier                    # => nil
account.usage_summary                # => { ai_responses_count: 0, ... }
account.billing_status               # => { plan_name: nil, subscription_status: nil, ... }
```

### 11.2 Subscription Management (Customer Self-Service)

```ruby
# ── Checkout URL (redirect customer to Stripe) ──────
account.checkout_url("pro_monthly",
  success_url: "http://localhost:3000/billing?ok=1",
  cancel_url: "http://localhost:3000/billing?cancel=1"
)
# => "https://checkout.stripe.com/c/pay/cs_test_..."

# ── Billing portal URL (Stripe-hosted management) ───
account.billing_portal_url(return_url: "http://localhost:3000/billing")
# => "https://billing.stripe.com/p/session/..."

# ── Swap plan ────────────────────────────────────────
account.swap_plan!("basic_annual")
account.active_plan.basic?           # => true

# ── Cancel / Resume ──────────────────────────────────
account.cancel_subscription!         # cancels at period end
account.active_subscription.on_grace_period?  # => true
account.resume_subscription!         # un-cancels
```

### 11.3 Admin Toolkit (Super Admin Operations)

```ruby
account = Account.find(42)

# ── SCENARIO: New customer wants to try before buying ──
account.grant_trial!(days: 14)
account.subscribed?                  # => true
account.active_subscription.on_trial?  # => true (via fake_processor)
account.active_plan.name             # => "Pro"
# After 14 days, subscription auto-expires. Customer must subscribe.

# ── SCENARIO: Customer needs more time to evaluate ────
account.extend_trial!(days: 30)
# Trial now ends 30 days later than before

# ── SCENARIO: Give trial on a specific plan ───────────
account.grant_trial!(days: 30, plan_key: "basic_monthly")
account.active_plan.basic?           # => true

# ── SCENARIO: Partner gets free Pro forever ───────────
account.grant_complimentary!(plan_key: "pro_annual")
account.billing_status[:is_complimentary]  # => true
account.billing_status[:processor]         # => "fake_processor"
account.active_plan.pro?                   # => true
# No expiration. No Stripe customer. Free forever.

# ── SCENARIO: Seasonal discount for paying customer ──
# (Customer must already have a Stripe subscription)
account.apply_coupon!("RAMADAN50")   # 50% off, applied in Stripe
# Stripe handles prorating. Webhook syncs the change.

# ── SCENARIO: 3 months free for onboarding incentive ─
Stripe::Coupon.create(id: "FREE3MONTHS", percent_off: 100, duration: "repeating", duration_in_months: 3)
account.apply_coupon!("FREE3MONTHS")

# ── SCENARIO: Force assign a plan (fix billing issue) ──
account.override_plan!("pro_monthly")          # complimentary (fake_processor)
account.override_plan!("pro_monthly", stripe: true)  # real Stripe sub (card on file)

# ── SCENARIO: Goodwill — reset usage after outage ─────
account.reset_usage!
account.usage_summary[:ai_responses_count]  # => 0

# ── SCENARIO: Give bonus credits (doesn't reset usage) ─
account.add_bonus_credits!(5000)
# If plan limit is 10,000 and they've used 9,500, they now have
# an effective limit of 15,000 — so 5,500 remaining this month.
account.within_ai_limit?  # => true (9500 < 10000 + 5000)

# ── SCENARIO: Suspend for nonpayment (usually auto) ────
account.suspend_for_nonpayment!
account.suspended?         # => true
account.custom_attributes  # => { "suspension_reason" => "nonpayment", "suspended_at" => "..." }

# ── SCENARIO: Reactivate after they fix payment ────────
account.reactivate_after_payment!
account.active?            # => true

# ── SCENARIO: Debug a support ticket ──────────────────
account.billing_status
# => {
#      plan_name: "Pro", plan_key: "pro_monthly", plan_tier: "pro",
#      subscription_status: "active", processor: "stripe",
#      is_complimentary: false, current_period_end: 2026-04-03,
#      trial_ends_at: nil, ends_at: nil, on_grace_period: false,
#      usage: { ai_responses_count: 12450, ai_responses_limit: 25000,
#               voice_notes_count: 23, usage_percentage: 49.8 }
#    }
```

### 11.4 Usage Tracking & Feature Gating

```ruby
# ── Track AI usage (called by AI response handler) ──
account.within_ai_limit?             # => true
account.track_ai_response!           # increments by 1
account.track_ai_response!(100)      # increments by 100
account.track_voice_note!            # increments voice_notes by 1, ai_responses by 6
account.usage_summary                # => { ai_responses_count: 107, ... }

# ── General resource limit check ─────────────────────
account.within_limit?(:knowledge_base_documents, account.aloo_documents.count)
# => true if count < plan limit (100 for Basic, 200 for Pro)

# ── Feature gating (for controller before_actions) ──
account.plan_feature_available?(:api_access)       # => true (Pro)
account.plan_feature_available?(:crm_integration)  # => false (Basic)

# ── Inline guard pattern for AI handler ──────────────
if account.within_ai_limit?
  # process AI response
  account.track_ai_response!
else
  # return limit-reached message to customer
end

# ── Run billing notifications manually ───────────────
BillingNotificationJob.perform_now  # checks trials, usage, sends emails

# ── Send a specific email ────────────────────────────
BillingMailer.trial_expiring(account, days_remaining: 3).deliver_now
BillingMailer.usage_warning(account, percentage: 85.0).deliver_now
```

### 11.5 Bulk Operations

```ruby
# Sync all accounts (e.g., after changing plans.yml)
Account.find_each { |a| a.sync_plan_features! if a.subscribed? }

# Usage report
Account.find_each do |a|
  next unless a.subscribed?
  s = a.billing_status
  puts "#{a.id} | #{a.name} | #{s[:plan_name]} (#{s[:processor]}) | #{s[:usage][:ai_responses_count]}/#{s[:usage][:ai_responses_limit]}"
end

# Find accounts on trial expiring in 3 days
Pay::Subscription.where("trial_ends_at BETWEEN ? AND ?", Time.current, 3.days.from_now).find_each do |sub|
  account = sub.customer.owner
  puts "#{account.name} trial ends #{sub.trial_ends_at.strftime('%B %d')}"
end

# Find accounts with no subscription (need nudging)
Account.active.left_joins(:pay_customers).where(pay_customers: { id: nil }).pluck(:id, :name)

# Find accounts near their AI limit (>80% used)
Account.find_each do |a|
  next unless a.subscribed?
  pct = a.usage_summary[:usage_percentage]
  puts "#{a.name}: #{pct}%" if pct && pct > 80
end
```

---

## 12. File Map

### New Files

| File | Purpose | Depth |
|------|---------|-------|
| `config/initializers/pay.rb` | Pay gem config | Config (infrastructure) |
| `config/initializers/pay_webhooks.rb` | Webhook subscriptions → lambdas → `sync_plan_features!`, auto-suspend/reactivate | Thin glue (correct) |
| `config/plans.yml` | Plan definitions (single source of truth) | Config |
| `app/models/plan_config.rb` | PORO: loads plans.yml, provides lookup/query methods | Deep PORO |
| `app/models/concerns/billable.rb` | **Core deep module**: all billing + admin + suspend/reactivate logic on Account | **Deep concern** |
| `app/models/account_usage_record.rb` | AR model for monthly usage tracking (includes bonus_credits) | Model |
| `db/migrate/xxx_create_account_usage_records.rb` | Usage table with bonus_credits column | Migration |
| `app/controllers/api/v1/accounts/subscriptions_controller.rb` | Thin delegate to `Billable` methods | Thin controller (correct) |
| `app/views/super_admin/accounts/_billing_actions.html.erb` | Admin billing forms (trial, coupon, override, bonus credits) | Thin view (correct) |
| `app/mailers/billing_mailer.rb` | 10 billing email types (trial, payment, usage, lifecycle) | Thin mailer (correct) |
| `app/views/billing_mailer/` | Liquid templates for each billing email | Templates |
| `app/jobs/billing_notification_job.rb` | Daily cron: expiring trials, expired trials, high usage alerts | Thin job (correct) |
| `config/schedule.yml` or cron config | Daily trigger for BillingNotificationJob | Config |
| `app/controllers/super_admin/billing_dashboard_controller.rb` | Billing metrics dashboard (MRR, active subs, trials, etc.) | Thin controller (correct) |
| `app/views/super_admin/billing_dashboard/index.html.erb` | Billing dashboard view with charts/tables | View |
| `app/javascript/dashboard/api/billing.js` | API client (extends ApiClient) | Thin API layer |
| `app/javascript/dashboard/stores/billing.js` | Pinia store for billing state | Store |
| `app/javascript/dashboard/routes/dashboard/settings/billing/` | Billing settings page + components | Frontend |

### Modified Files

| File | Change |
|------|--------|
| `Gemfile` | Add `gem "pay", "~> 7"` |
| `app/models/account.rb` | Add `include Billable` (one line) |
| `app/policies/account_policy.rb` | Add `manage_billing?` method |
| `config/routes.rb` | Add `resource :subscription` API routes, add super admin billing member actions, add `billing_dashboard` resource, remove dead `/webhooks/stripe` route |
| `app/controllers/super_admin/accounts_controller.rb` | Add 9 billing admin actions (`grant_trial`, `extend_trial`, `grant_complimentary`, `apply_coupon`, `override_plan`, `reset_usage`, `cancel_subscription`, `add_bonus_credits`, `suspend_account`) |
| `app/dashboards/account_dashboard.rb` | Add `billing_plan`, `billing_status`, `billing_processor`, `ai_usage` display fields + collection filters |
| `app/views/super_admin/accounts/show.html.erb` | Render `_billing_actions` partial |
| Sidebar.vue | Add Billing nav item |
| Settings route index | Register billing routes |
| `app/javascript/dashboard/i18n/locale/en/settings.json` | Add `BILLING` i18n keys |

### Module Depth Audit

| Module | Interface | Complexity Hidden | Verdict |
|--------|-----------|-------------------|---------|
| `Billable` concern | ~25 public methods | Stripe API, pay gem, plan config, usage tracking, feature syncing, checkout/portal sessions, admin ops (trial, coupon, override, complimentary, bonus credits, usage reset, suspend/reactivate), billing status | **Deep** ✅ |
| `PlanConfig` PORO | 3 class methods + accessors | YAML parsing, ERB interpolation, env var resolution, lookup strategies | **Deep** ✅ |
| `AccountUsageRecord` | 3 methods | find_or_create, atomic increment, voice-to-AI conversion, bonus credits | Model (correct) |
| `SubscriptionsController` | 6 actions | — (delegates everything) | **Thin controller** ✅ |
| `SuperAdmin::AccountsController` billing actions | 9 actions | — (each calls 1 Billable method) | **Thin controller** ✅ |
| `SuperAdmin::BillingDashboardController` | 1 action (index) | Aggregates billing metrics via AR queries | **Thin controller** ✅ |
| `BillingMailer` | 10 mail methods | Liquid template rendering, recipient resolution, meta data assembly | **Thin mailer** ✅ |
| `BillingNotificationJob` | 1 method (perform) | Trial expiry queries, usage threshold checks, mailer dispatch | **Thin job** ✅ |
| Webhook lambdas | 4 lambdas | — (each calls 1-2 Billable/mailer methods) | **Thin glue** ✅ |

**Rejected shallow modules:**
- ~~`PlanLimitService`~~ → `account.within_ai_limit?` / `account.within_limit?`
- ~~`PlanSyncService`~~ → `account.sync_plan_features!`
- ~~`AdminBillingService`~~ → admin methods live on `Billable` concern
- ~~`SubscriptionCreatedHandler`~~ → lambda in initializer
- ~~`SubscriptionUpdatedHandler`~~ → same lambda
- ~~`SubscriptionDeletedHandler`~~ → same lambda
- ~~`PaymentFailedHandler`~~ → not needed (pay gem handles status update)
- ~~`CheckoutController`~~ → merged into `SubscriptionsController#checkout`
- ~~`BillingPortalController`~~ → merged into `SubscriptionsController#portal`
- ~~`BillingNotificationService`~~ → logic lives directly in `BillingNotificationJob`
- ~~`SuspensionService`~~ → `account.suspend_for_nonpayment!` / `reactivate_after_payment!`

---

## 13. Environment Variables

| Variable | Description |
|----------|-------------|
| `STRIPE_PRIVATE_KEY` | Stripe secret key (pay gem reads this) |
| `STRIPE_PUBLIC_KEY` | Stripe publishable key (frontend, if needed) |
| `STRIPE_SIGNING_SECRET` | Webhook signing secret |
| `STRIPE_BASIC_MONTHLY_PRICE_ID` | Stripe Price ID |
| `STRIPE_BASIC_ANNUAL_PRICE_ID` | Stripe Price ID |
| `STRIPE_PRO_MONTHLY_PRICE_ID` | Stripe Price ID |
| `STRIPE_PRO_ANNUAL_PRICE_ID` | Stripe Price ID |

> **Note:** The existing `STRIPE_SECRET_KEY` in `config/initializers/stripe.rb` should be reconciled. The pay gem expects `STRIPE_PRIVATE_KEY` by default. Either rename the env var or configure pay to read `STRIPE_SECRET_KEY`.

---

## 14. Open Questions

Decisions needed before implementation:

1. **Existing accounts**: Grandfather (no plan required, unlimited) or grace period to choose a plan?

2. **Trial period**: Free trial for new signups? If so, how many days?

3. **Annual = recurring or one-time?** The spec says "one-time payment." Should annual auto-renew, or expire after 12 months requiring manual renewal?

4. **Currency**: KWD only, or also USD for international customers?

5. **AI limit reached**: Hard block AI responses, soft warning, or allow overage?

6. **Signup flow**: Plan selection required before dashboard access (blocking), or optional with banner?

7. **Email in Pro plan**: Pro's integration list omits "Email" but Basic includes it. Intentional?

8. **Downgrade handling**: When Pro → Basic, what happens to documents over 100, CRM integrations, API tokens?

9. **Grace period on failed payment**: How long to allow access? (Stripe default: 3 retries over ~3 weeks)

---

## 15. Post-Launch Iterations

Items to build **after** the core billing system is stable. Ordered by expected impact.

### Tier 1 — High Value

| Feature | Description | Touches |
|---------|-------------|---------|
| **Revenue Dashboard** | MRR/ARR tracking over time, churn rate, upgrade/downgrade trends, revenue by plan. Chart-based view in super admin. | New controller + view, possibly Chartkick gem |
| **Resource Limits per Plan** | Extend `within_limit?` to enforce per-plan caps on inboxes, contacts, automation rules. Add limit keys to `plans.yml`, gate in relevant controllers. | `plans.yml`, `Billable#within_limit?`, inbox/contact/automation controllers |
| **Dunning Emails (Smart Retry)** | Multi-step email sequence on payment failure: reminder at day 1, warning at day 7, final notice + suspension warning at day 14. More granular than single `payment_failed` email. | `BillingNotificationJob`, new templates, status tracking |
| **Usage Analytics for Customers** | Customer-facing usage dashboard showing AI responses used, voice notes, remaining quota, usage trend chart. | New Vue component on billing page, new API endpoint |

### Tier 2 — Medium Value

| Feature | Description | Touches |
|---------|-------------|---------|
| **Subscription Transfer** | Move a subscription from one account to another (e.g., agency managing client accounts). Admin-only. | New `Billable#transfer_subscription!(target_account)` method, Stripe subscription update |
| **Suspension Reason Tracking** | Store detailed suspension reasons (nonpayment, admin action, abuse, etc.) with timestamps and who actioned it. Currently stores only "nonpayment" in `custom_attributes`. | Structured `suspension_logs` or use existing audit trail |
| **Plan Upgrade Prorations** | Show prorated cost preview before plan swap. Use Stripe's proration preview API. | `Billable#swap_preview(plan_key)`, frontend preview modal |
| **Webhook Event Log** | Visible log of processed Stripe webhook events in super admin for debugging billing issues. Pay gem stores raw events in `pay_webhooks` table — just needs a UI. | New super admin view on `pay_webhooks` table |

### Tier 3 — Nice to Have

| Feature | Description | Touches |
|---------|-------------|---------|
| **Multi-Currency Support** | Allow KWD + USD pricing. Requires dual price IDs per plan in Stripe, currency detection in checkout flow. | `plans.yml` restructure, checkout flow, Stripe config |
| **Referral / Affiliate Codes** | Track referral codes, apply automatic discounts for referred signups. | New model, signup flow integration, Stripe coupons |
| **Invoice Customization** | Custom invoice branding, additional fields (VAT number, company details). Uses Stripe Invoice API. | Stripe Dashboard config + optional API calls |
| **Metered Billing (Pay-As-You-Go)** | Alternative to fixed quotas: charge per AI response beyond base quota. Uses Stripe metered billing. | Stripe usage records API, new pricing model in `plans.yml` |

### Extension Points Already in Place

The current architecture supports these iterations without refactoring:

- **`within_limit?(resource, current_count)`** — Adding new resource limits is just a `plans.yml` change + one controller guard
- **`billing_status`** — Revenue dashboard can aggregate this across all accounts
- **`custom_attributes`** — Suspension reason tracking can extend the existing pattern
- **`pay_webhooks` table** — Event log UI just needs a read-only admin view
- **`BillingMailer`** — New email types are just new methods + templates
- **`BillingNotificationJob`** — New scheduled checks are additional query blocks in `perform`
