# Deep concern that hides all subscription/billing complexity.
#
# Hides: pay gem orchestration, Stripe API interactions, plan config resolution,
#        usage tracking, feature flag syncing, checkout/portal session creation,
#        subscription lifecycle (swap, cancel, resume), webhook-driven sync,
#        admin toolkit (trial, coupon, override, complimentary, suspend/reactivate).
#
# Console usage:
#   account = Account.find(1)
#   account.active_plan              # => PlanConfig or nil
#   account.subscribed?              # => true
#   account.within_ai_limit?         # => true
#   account.track_ai_response!       # increments counter
#   account.checkout_url("pro_monthly", success_url: "...", cancel_url: "...")
#   account.grant_trial!(days: 14)
#   account.billing_status           # => { plan_name: "Pro", ... }
#
module Billable
  extend ActiveSupport::Concern

  included do
    pay_customer stripe_attributes: :stripe_attributes

    has_many :usage_records, class_name: 'AccountUsageRecord', dependent: :destroy
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
    return true unless plan

    usage = current_usage
    effective_limit = plan.ai_response_limit + (usage.bonus_credits || 0)
    usage.ai_responses_count < effective_limit
  end

  # General limit check — works for any resource defined in plans.yml limits.
  def within_limit?(resource, current_count = nil)
    plan = active_plan
    return true unless plan

    limit = plan.limits[resource]
    return true unless limit

    if current_count.nil?
      count_method = :"#{resource}_count"
      current_count = current_usage.send(count_method) if current_usage.respond_to?(count_method)
    end
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
      mode: 'subscription',
      line_items: [{ price: plan.stripe_price_id, quantity: 1 }],
      allow_promotion_codes: true,
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
    raise 'No active subscription to swap' unless sub

    sub.swap(plan.stripe_price_id)
    sync_plan_features!
  end

  def cancel_subscription!
    sub = active_subscription
    raise 'No active subscription to cancel' unless sub

    sub.cancel
  end

  def resume_subscription!
    sub = active_subscription
    raise 'No active subscription to resume' unless sub

    sub.resume
  end

  # ── Plan ↔ Feature Sync (called from webhooks) ────────────────

  def sync_plan_features!
    plan = active_plan

    if plan
      plan.features.each do |feature_key, enabled|
        flag_name = plan_feature_to_flag(feature_key)
        next unless flag_name

        enabled ? enable_features(flag_name) : disable_features(flag_name)
      end

      self.limits = (limits || {}).merge(
        'ai_responses_per_month' => plan.ai_response_limit,
        'knowledge_base_documents' => plan.kb_document_limit
      )
    else
      disable_features(:crm)
      self.limits = (limits || {}).except('ai_responses_per_month', 'knowledge_base_documents')
    end

    save!
  end

  # ── Feature Gating (plan-aware) ────────────────────────────────

  def plan_feature_available?(feature_key)
    plan = active_plan
    return true unless plan

    plan.feature_enabled?(feature_key)
  end

  # ── Admin Toolkit ──────────────────────────────────────────────

  def grant_trial!(days:, plan_key: 'pro_monthly')
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

  def extend_trial!(days:)
    sub = active_subscription
    raise 'No active subscription to extend' unless sub

    new_end = (sub.ends_at || sub.trial_ends_at || Time.current) + days.days

    if sub.customer.processor == 'fake_processor'
      sub.update!(trial_ends_at: new_end, ends_at: new_end)
    else
      ::Stripe::Subscription.update(sub.processor_id, { trial_end: new_end.to_i })
      sub.sync!
    end
  end

  def grant_complimentary!(plan_key: 'pro_monthly')
    plan = PlanConfig.find(plan_key)

    active_subscription&.cancel_now! if active_subscription&.active?

    set_payment_processor :fake_processor, allow_fake: true
    payment_processor.subscribe(plan: plan.stripe_price_id)
    sync_plan_features!
  end

  def apply_coupon!(coupon_id)
    sub = active_subscription
    raise 'No active subscription' unless sub
    raise 'Coupons only work with Stripe subscriptions' unless sub.customer.processor == 'stripe'

    ::Stripe::Subscription.update(sub.processor_id, { discounts: [{ coupon: coupon_id }] })
    sub.sync!
  end

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

  def add_bonus_credits!(amount)
    usage = current_usage
    usage.update!(bonus_credits: (usage.bonus_credits || 0) + amount)
  end

  def reset_usage!
    current_usage.update!(ai_responses_count: 0, voice_notes_count: 0)
  end

  def suspend_for_nonpayment!
    update!(status: :suspended)
    self.custom_attributes = (custom_attributes || {}).merge(
      'suspension_reason' => 'nonpayment',
      'suspended_at' => Time.current.iso8601
    )
    save!
  end

  def reactivate_after_payment!
    return unless suspended? && custom_attributes&.dig('suspension_reason') == 'nonpayment'

    update!(status: :active)
    self.custom_attributes = (custom_attributes || {}).except('suspension_reason', 'suspended_at')
    save!
    sync_plan_features!
  end

  def billing_status
    sub = active_subscription
    plan = active_plan

    {
      plan_name: plan&.name,
      plan_key: plan&.key,
      plan_tier: plan&.tier,
      subscription_status: sub&.status,
      processor: sub&.customer&.processor,
      is_complimentary: sub&.customer&.processor == 'fake_processor',
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

  # Maps plan feature keys (from plans.yml) to Account feature flag names (from features.yml)
  def plan_feature_to_flag(feature_key)
    mapping = {
      crm_integration: :crm
    }
    mapping[feature_key]
  end
end
