class Enterprise::Billing::HandleStripeEventService
  include BillingHelper

  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  CAPTAIN_CLOUD_PLAN_LIMITS = 'CAPTAIN_CLOUD_PLAN_LIMITS'.freeze

  STARTUP_PLAN_FEATURES = Enterprise::Billing::ReconcilePlanFeaturesService::STARTUP_PLAN_FEATURES
  BUSINESS_PLAN_FEATURES = Enterprise::Billing::ReconcilePlanFeaturesService::BUSINESS_PLAN_FEATURES
  ENTERPRISE_PLAN_FEATURES = Enterprise::Billing::ReconcilePlanFeaturesService::ENTERPRISE_PLAN_FEATURES

  def perform(event:)
    @event = event
    log_event

    case @event.type
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def log_event
    object = @event.data.object
    Rails.logger.info("Stripe event: id=#{@event.id} type=#{@event.type} customer=#{object['customer']} status=#{object['status']}")
  end

  def process_subscription_updated
    # skipping self hosted plan events
    return unless stripe_billed_account?

    # A cancelled subscription keeps emitting updates that still carry its old plan.
    # Acting on one re-applies that plan over the downgrade customer.subscription.deleted
    # just made, so the account keeps paid features it no longer pays for.
    return if subscription['status'] == 'canceled'

    plan = find_plan(subscription['plan']['product']) if subscription['plan'].present?

    # skipping self hosted plan events
    return if plan.blank?

    account.with_lock { apply_subscription(plan) }
    track_marketing_plan_activation(previous_plan_name) if event_changed_plan?
    broadcast_billing_updated
  end

  # Credits are settled by diffing the stored account against the current subscription, so the plan and
  # credit writes commit together: a failed delivery leaves the old state for its retry to diff again,
  # and concurrent deliveries can't both settle the same change.
  def apply_subscription(plan)
    # Stripe is read before taking the lock, so a slow call never holds it, but concurrent deliveries
    # can then reach the lock out of order.
    return if subscription_read.overtaken_on?(account)

    previous_usage = capture_previous_usage
    update_account_attributes(subscription, plan)
    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
    sync_subscription_credits(plan, previous_usage)
  end

  def sync_subscription_credits(plan, previous_usage)
    if billing_period_renewed?(previous_usage)
      handle_subscription_credits(plan, previous_usage)
      account.reset_response_usage
    # Compare with the stored plan, not the event: whichever event first applies a new plan settles its credits.
    elsif previous_usage[:plan_name] != plan['name']
      handle_plan_change_credits(plan, previous_usage)
    end
  end

  def capture_previous_usage
    {
      responses: account.custom_attributes['captain_responses_usage'].to_i,
      monthly: current_plan_credits[:responses],
      plan_name: account.custom_attributes['plan_name'],
      period_ends_on: account.custom_attributes['subscription_ends_on']
    }
  end

  def current_plan_credits
    plan_name = account.custom_attributes['plan_name']
    plan_credits = get_plan_credits(plan_name) if plan_name.present?
    plan_credits || { responses: 0, documents: 0 }
  end

  def update_account_attributes(subscription, plan)
    # https://stripe.com/docs/api/subscriptions/object
    account.update(
      custom_attributes: account.custom_attributes.merge(
        'stripe_customer_id' => subscription.customer,
        'stripe_price_id' => subscription['plan']['id'],
        'stripe_product_id' => subscription['plan']['product'],
        'plan_name' => plan['name'],
        'subscribed_quantity' => subscription['quantity'],
        'subscription_status' => subscription['status'],
        'subscription_ends_on' => subscription_ends_on(subscription),
        'subscription_cancels_on' => subscription_cancels_on(subscription),
        'billing_currency' => billing_currency_for(subscription, plan)
      ),
      internal_attributes: subscription_read.mark_applied(account.internal_attributes)
    )
  end

  # Paid subscriptions define the currency; the free/default plan keeps the stored preference.
  def billing_currency_for(subscription, plan)
    return account.billing_currency if plan['name'] == Enterprise::Billing::PlanConfiguration.default_plan&.dig('name')

    Enterprise::Billing::Currencies.to_supported(subscription['plan']['currency'])
  end

  # Records the activation this event describes, so it reads the event's payload, not the current subscription.
  def track_marketing_plan_activation(previous_plan_name)
    subscription_plan = event_subscription['plan']

    Internal::Accounts::CloudPlanActivationConversionService.new(
      account: account,
      previous_plan_name: previous_plan_name,
      current_plan_name: find_plan(subscription_plan['product'])&.dig('name'),
      activated_at: Time.zone.at(@event.created),
      conversion_value: subscription_conversion_value(subscription_plan),
      currency_code: subscription_plan['currency'].upcase
    ).perform
  end

  def subscription_conversion_value(subscription_plan)
    ((subscription_plan['amount'] || subscription_plan['amount_decimal']).to_d * event_subscription['quantity'].to_i / 100).to_f
  end

  def process_subscription_deleted
    # skipping self hosted plan events
    return unless stripe_billed_account?

    previous_monthly_credits = current_plan_credits[:responses]
    return unless Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform

    account.with_lock do
      previous_usage = { responses: account.custom_attributes['captain_responses_usage'].to_i, monthly: previous_monthly_credits }
      adjust_captain_credits(previous_usage, new_plan_credits: 0)
      account.reset_response_usage
    end
    broadcast_billing_updated
  end

  # Stripe returns the admin from the billing portal before this webhook lands, so push the
  # refreshed status to any dashboard already open instead of waiting for another reload.
  def broadcast_billing_updated
    ActionCableBroadcastJob.perform_later(["account_#{account.id}"], 'account.billing_updated', { account_id: account.id })
  end

  def handle_subscription_credits(plan, previous_usage)
    adjust_captain_credits(previous_usage, new_plan_credits: get_plan_credits(plan['name'])[:responses])
  end

  def adjust_captain_credits(previous_usage, new_plan_credits:)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    consumed_topup_credits = [previous_usage[:responses] - previous_usage[:monthly], 0].max
    updated_credits = [current_credits - consumed_topup_credits - previous_usage[:monthly] + new_plan_credits, 0].max

    Rails.logger.info("Updating captain credits for account #{account.id}: #{current_credits} -> #{updated_credits}")
    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def handle_plan_change_credits(new_plan, previous_usage)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    previous_plan_credits = previous_usage[:monthly]
    new_plan_credits = get_plan_credits(new_plan['name'])[:responses]

    updated_credits = current_credits - previous_plan_credits + new_plan_credits

    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def get_plan_credits(plan_name)
    config = InstallationConfig.find_by(name: CAPTAIN_CLOUD_PLAN_LIMITS).value
    config = JSON.parse(config) if config.is_a?(String)
    config[plan_name.downcase]&.symbolize_keys
  end

  # Stripe delivers events out of order and retries a failed one for days, so a payload can be older
  # than state already applied. Read the subscription as it is now, in the payload's API version.
  def subscription
    subscription_read.subscription
  end

  def subscription_read
    @subscription_read ||= Enterprise::Billing::StripeSubscriptionRead.new(
      subscription_id: event_subscription.id, stripe_version: @event.api_version
    )
  end

  def event_subscription
    @event.data.object
  end

  def previous_attributes
    @previous_attributes ||= JSON.parse((@event.data.previous_attributes || {}).to_json)
  end

  def event_changed_plan?
    return false if previous_attributes['plan'].blank?

    previous_plan_id = previous_attributes.dig('plan', 'id')
    current_plan_id = event_subscription['plan']['id']

    previous_plan_id != current_plan_id
  end

  # Like the plan, a renewal is detected against the stored period, so whichever event first sees the
  # new period settles it with the old plan's allowance, even if that event isn't the renewal itself.
  def billing_period_renewed?(previous_usage)
    return false if previous_usage[:period_ends_on].blank?

    Time.zone.parse(previous_usage[:period_ends_on].to_s) != subscription_ends_on(subscription)
  end

  def account
    # A subscription never changes customer, so the payload finds the account without a Stripe read.
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", event_subscription.customer).first
  end

  def stripe_billed_account?
    account&.billing_provider == Account::DEFAULT_BILLING_PROVIDER
  end

  def find_plan(product_id)
    Enterprise::Billing::PlanConfiguration.find_plan_by_product_id(product_id)
  end

  def previous_plan_name
    stripe_plan = previous_attributes['plan']
    return if stripe_plan.blank?

    find_plan(stripe_plan['product'])&.dig('name')
  end
end
