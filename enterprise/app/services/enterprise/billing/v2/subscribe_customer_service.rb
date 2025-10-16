# rubocop:disable Metrics/ClassLength
class Enterprise::Billing::V2::SubscribeCustomerService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::V2::Concerns::PaymentIntentHandler
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::PlanFeatureManager

  def subscribe_to_pricing_plan(pricing_plan_id:, customer_id: nil, meter_id: nil, meter_event_name: nil)
    @pricing_plan_id = pricing_plan_id
    @customer_id = customer_id || stripe_customer_id
    # Use shared meter from ENV if not explicitly provided
    @meter_id = meter_id || shared_meter_id
    @meter_event_name = meter_event_name || shared_meter_event_name

    validate_subscription_params
    execute_subscription_flow
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe API error: #{e.message}", error: e }
  rescue StandardError => e
    { success: false, message: "Subscription error: #{e.message}", error: e }
  end

  private

  def validate_subscription_params
    return { success: false, message: 'Customer ID required' } if @customer_id.blank?
    return { success: false, message: 'Pricing Plan ID required' } if @pricing_plan_id.blank?

    nil
  end

  def execute_subscription_flow
    with_locked_account do
      cadence = create_billing_cadence
      return { success: false, message: 'Failed to create billing cadence' } unless cadence

      pricing_plan = pricing_plan_details
      return { success: false, message: 'Failed to get pricing plan details' } unless pricing_plan

      intent = create_billing_intent(cadence.id, pricing_plan)
      return { success: false, message: 'Failed to create billing intent' } unless intent

      reserve_and_commit_intent(intent.id)
      update_account_subscription_info(pricing_plan, cadence.id)
      refresh_monthly_credits(pricing_plan)
      enable_plan_features(pricing_plan)

      build_subscription_result(cadence.id, intent.id)
    end
  end

  def reserve_and_commit_intent(intent_id)
    reserved_intent = reserve_intent(intent_id)
    return { success: false, message: 'Failed to reserve intent' } unless reserved_intent

    committed_intent = commit_intent(intent_id)
    return { success: false, message: 'Failed to commit intent' } unless committed_intent

    committed_intent
  end

  def build_subscription_result(cadence_id, intent_id)
    {
      success: true,
      customer_id: @customer_id,
      pricing_plan_id: @pricing_plan_id,
      cadence_id: cadence_id,
      intent_id: intent_id,
      status: 'subscribed'
    }
  end

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  def create_billing_cadence
    cadence_params = {
      payer: {
        type: 'customer',
        customer: @customer_id
      },
      billing_cycle: {
        type: 'month',
        interval_count: 1,
        month: {
          day_of_month: 1
        }
      }
    }

    StripeV2Client.request(
      :post,
      '/v2/billing/cadences',
      cadence_params,
      stripe_api_options
    )
  end

  def pricing_plan_details
    StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plans/#{@pricing_plan_id}",
      {},
      stripe_api_options
    )
  end

  def create_billing_intent(cadence_id, pricing_plan)
    plan_version = extract_plan_version(pricing_plan)
    intent_params = build_intent_params(cadence_id, plan_version)

    StripeV2Client.request(
      :post,
      '/v2/billing/intents',
      intent_params,
      stripe_api_options
    )
  end

  def extract_plan_version(pricing_plan)
    pricing_plan['latest_version'] || pricing_plan['live_version'] || pricing_plan['version']
  end

  def build_intent_params(cadence_id, plan_version)
    {
      currency: 'usd',
      cadence: cadence_id,
      actions: [build_subscription_action(plan_version)]
    }
  end

  def build_subscription_action(plan_version)
    {
      type: 'subscribe',
      subscribe: {
        type: 'pricing_plan_subscription_details',
        pricing_plan_subscription_details: {
          pricing_plan: @pricing_plan_id,
          pricing_plan_version: plan_version,
          component_configurations: []
        }
      }
    }
  end

  def reserve_intent(intent_id)
    StripeV2Client.request(
      :post,
      "/v2/billing/intents/#{intent_id}/reserve",
      {},
      stripe_api_options
    )
  end

  def commit_intent(intent_id)
    intent = fetch_billing_intent(intent_id)

    # Only require payment method if there's an amount due
    ensure_payment_method(intent) if requires_payment?(intent)

    payment_intent_id = create_payment_if_needed(intent, intent_id)
    commit_billing_intent(intent_id, payment_intent_id)
  end

  def requires_payment?(intent)
    amount_due = intent.amount_details&.total || intent.amount_details.total
    amount_due&.to_i&.positive?
  end

  def ensure_payment_method(_intent)
    # Check if customer already has a payment method
    customer = Stripe::Customer.retrieve(
      @customer_id,
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )

    return if customer.invoice_settings&.default_payment_method.present?

    # In production, payment methods must be added via Checkout or SetupIntent
    # This ensures proper customer authentication and PCI compliance
    raise Stripe::StripeError,
          'Payment method required. Customer must add payment method via Stripe Checkout or SetupIntent before subscribing.'
  end

  def update_account_subscription_info(pricing_plan, cadence_id)
    attributes = {
      'stripe_billing_version' => 2,
      'stripe_customer_id' => @customer_id,
      'stripe_pricing_plan_id' => @pricing_plan_id,
      'stripe_cadence_id' => cadence_id,
      'plan_name' => extract_plan_name(pricing_plan),
      'subscription_status' => 'active'
    }
    # Store meter configuration if provided
    attributes['stripe_meter_id'] = @meter_id if @meter_id.present?
    attributes['stripe_meter_event_name'] = @meter_event_name if @meter_event_name.present?

    update_custom_attributes(attributes)
  end

  def extract_plan_name(pricing_plan)
    display_name = pricing_plan['display_name'] || pricing_plan[:display_name]
    return 'Business' unless display_name

    # Extract plan name from display name
    # Supports formats:
    #   - "Chatwoot Business - 2000 Credits" → Business
    #   - "Chatwoot Startup Plan" → Startup
    name_part = display_name.split('-').first.strip

    # Try to find known tier names in the string
    %w[Enterprise Business Startup Hacker].each do |tier|
      return tier if name_part.include?(tier)
    end

    # Fallback: try to extract last word before "Plan" or just last word
    name_part.gsub(/\s+Plan$/, '').strip.split.last || 'Business'
  end

  def refresh_monthly_credits(pricing_plan)
    credits = Enterprise::Billing::V2::PlanCatalog.monthly_credits_for(@pricing_plan_id)
    credits ||= extract_credits_from_pricing_plan(pricing_plan)
    return unless credits

    Enterprise::Billing::V2::CreditManagementService
      .new(account: account)
      .sync_monthly_credits(credits.to_i)
  end

  def extract_credits_from_pricing_plan(pricing_plan)
    components = get_plan_components(pricing_plan)
    return unless components&.any?

    find_service_action_credits(components)
  end

  def get_plan_components(pricing_plan)
    components = pricing_plan['components']
    components&.any? ? components : fetch_plan_components
  end

  def find_service_action_credits(components)
    components.each do |component|
      next unless safe_fetch(component, :type) == 'service_action'

      amount = service_action_credit_amount(component)
      return amount if amount.present?
    end
    nil
  end

  def fetch_plan_components
    response = StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plans/#{@pricing_plan_id}/components",
      {},
      stripe_api_options
    )
    response.data
  rescue StandardError => e
    Rails.logger.error("Failed to fetch plan components for #{@pricing_plan_id}: #{e.message}")
    []
  end

  def service_action_credit_amount(component)
    action_id = safe_fetch(component, :service_action, :id)
    return unless action_id

    action_response = StripeV2Client.request(
      :get,
      "/v2/billing/service_actions/#{action_id}",
      {},
      stripe_api_options
    )

    credit = action_response.credit_grant&.amount&.custom_pricing_unit&.value
    credit&.to_i
  rescue StandardError => e
    Rails.logger.error("Failed to fetch service action #{action_id}: #{e.message}")
    nil
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end

  def shared_meter_id
    InstallationConfig.find_by(name: 'STRIPE_METER_ID')&.value ||
      ENV.fetch('STRIPE_METER_ID', nil)
  end

  def shared_meter_event_name
    InstallationConfig.find_by(name: 'STRIPE_METER_EVENT_NAME')&.value ||
      ENV.fetch('STRIPE_METER_EVENT_NAME', nil)
  end

  def safe_fetch(object, *keys)
    keys.reduce(object) do |memo, key|
      break nil if memo.nil?

      if memo.respond_to?(key)
        memo.public_send(key)
      elsif memo.respond_to?(:[])
        memo[key.to_s] || memo[key]
      end
    end
  end

  def enable_plan_features(pricing_plan)
    plan_name = extract_plan_name(pricing_plan)
    Rails.logger.info "Enabling features for V2 plan: #{plan_name} (account #{account.id})"

    # Use shared feature management logic
    update_plan_features(plan_name)

    # Reset AI usage counters
    reset_captain_usage

    Rails.logger.info "Features enabled for account #{account.id}: #{account.enabled_features.keys.join(', ')}"
  end
end
# rubocop:enable Metrics/ClassLength
