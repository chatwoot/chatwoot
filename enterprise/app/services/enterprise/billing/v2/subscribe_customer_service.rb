class Enterprise::Billing::V2::SubscribeCustomerService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::V2::Concerns::PaymentIntentHandler

  def subscribe_to_pricing_plan(pricing_plan_id:, customer_id: nil, meter_id: nil, meter_event_name: nil)
    @pricing_plan_id = pricing_plan_id
    @customer_id = customer_id || stripe_customer_id
    @meter_id = meter_id
    @meter_event_name = meter_event_name

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
      update_account_subscription_info(pricing_plan)

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
    ensure_payment_method

    intent = fetch_billing_intent(intent_id)
    payment_intent_id = create_payment_if_needed(intent, intent_id)

    commit_billing_intent(intent_id, payment_intent_id)
  end

  def ensure_payment_method
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

  def update_account_subscription_info(pricing_plan)
    attributes = {
      'stripe_billing_version' => 2,
      'stripe_customer_id' => @customer_id,
      'stripe_pricing_plan_id' => @pricing_plan_id,
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

    # Extract plan name from display name like "Chatwoot Business - 2000 Credits"
    display_name.split('-').first.strip.split.last || 'Business'
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end
end
