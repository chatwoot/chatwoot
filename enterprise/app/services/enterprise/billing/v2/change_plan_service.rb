class Enterprise::Billing::V2::ChangePlanService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  # Change customer's pricing plan using Stripe's V2 Billing Intent API
  # Creates a modify billing intent to migrate to a new pricing plan
  #
  # @param new_pricing_plan_id [String] The new Stripe pricing plan ID
  # @param quantity [Integer] The quantity for the new plan
  # @return [Hash] { success:, message: }
  #
  def change_plan(new_pricing_plan_id:, quantity: 1)
    return { success: false, message: 'Invalid quantity' } unless quantity.positive?

    with_locked_account do
      billing_intent = create_change_plan_intent(new_pricing_plan_id, quantity)
      reserve_billing_intent(billing_intent)
      commit_billing_intent(billing_intent)
      update_account_plan(new_pricing_plan_id, quantity)
      success_response(new_pricing_plan_id, quantity)
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  end

  private

  def create_change_plan_intent(new_pricing_plan_id, quantity)
    subscription_id = fetch_subscription_id
    cadence_id = fetch_cadence_from_subscription(subscription_id)
    plan_version = fetch_new_plan_version(new_pricing_plan_id)
    lookup_key = fetch_plan_lookup_key(new_pricing_plan_id)
    component_config = { lookup_key: lookup_key, quantity: quantity }

    StripeV2Client.request(
      :post,
      '/v2/billing/intents',
      build_change_plan_params(subscription_id, cadence_id, new_pricing_plan_id, plan_version, component_config),
      stripe_api_options
    )
  end

  def fetch_subscription_id
    custom_attribute('stripe_subscription_id').tap do |id|
      raise StandardError, 'No pricing plan subscription ID found' if id.blank?
    end
  end

  def fetch_cadence_from_subscription(subscription_id)
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    extract_attribute(subscription, :billing_cadence).tap do |cadence_id|
      raise StandardError, 'No billing cadence found in subscription' if cadence_id.blank?
    end
  end

  def fetch_new_plan_version(plan_id)
    plan = retrieve_pricing_plan(plan_id)
    extract_attribute(plan, :latest_version).tap do |version|
      raise StandardError, "No version found for pricing plan #{plan_id}" if version.blank?
    end
  end

  def fetch_plan_lookup_key(plan_id)
    Enterprise::Billing::V2::PlanCatalog.lookup_key_for_plan(plan_id).tap do |key|
      raise StandardError, "Lookup key not found for pricing plan #{plan_id}" unless key
    end
  end

  def build_change_plan_params(subscription_id, cadence_id, plan_id, plan_version, component_config)
    {
      cadence: cadence_id,
      currency: 'usd',
      actions: [{
        type: 'modify',
        modify: {
          type: 'pricing_plan_subscription_details',
          pricing_plan_subscription_details: {
            pricing_plan_subscription: subscription_id,
            new_pricing_plan: plan_id,
            new_pricing_plan_version: plan_version,
            component_configurations: [component_config]
          }
        }
      }]
    }
  end

  def reserve_billing_intent(billing_intent)
    StripeV2Client.request(
      :post,
      "/v2/billing/intents/#{billing_intent.id}/reserve",
      {},
      stripe_api_options
    )
  end

  def commit_billing_intent(billing_intent)
    StripeV2Client.request(
      :post,
      "/v2/billing/intents/#{billing_intent.id}/commit",
      {},
      stripe_api_options
    )
  end

  def retrieve_pricing_plan_subscription(subscription_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plan_subscriptions/#{subscription_id}",
      {},
      stripe_api_options
    )
  end

  def retrieve_pricing_plan(pricing_plan_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plans/#{pricing_plan_id}",
      {},
      stripe_api_options
    )
  end

  def update_account_plan(new_pricing_plan_id, quantity)
    attributes = {
      'pending_stripe_pricing_plan_id' => new_pricing_plan_id,
      'pending_subscription_quantity' => quantity
    }

    # Add plan name from catalog
    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(new_pricing_plan_id)
    attributes['plan_name'] = plan_definition[:display_name] if plan_definition

    update_custom_attributes(attributes)
  end

  def extract_plan_name(plan_definition)
    # Extract plan name like "Startup", "Business", or "Enterprise" from display_name
    plan_definition[:display_name].split.find { |word| %w[Startup Startups Business Enterprise].include?(word) }
  end

  def success_response(new_pricing_plan_id, quantity)
    {
      success: true,
      pricing_plan_id: new_pricing_plan_id,
      quantity: quantity,
      message: 'Pricing plan changed successfully'
    }
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end

  def extract_attribute(object, key)
    object.respond_to?(key) ? object.public_send(key) : object[key.to_s]
  end
end
