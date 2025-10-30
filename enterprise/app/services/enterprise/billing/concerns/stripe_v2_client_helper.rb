module Enterprise::Billing::Concerns::StripeV2ClientHelper
  extend ActiveSupport::Concern

  private

  # Generic Stripe V2 API request wrapper
  def stripe_v2_request(method, path, params = {}, api_version: nil)
    StripeV2Client.request(method, path, params, stripe_api_options(api_version))
  end

  # Pricing Plan Subscriptions
  def retrieve_pricing_plan_subscription(subscription_id)
    stripe_v2_request(:get, "/v2/billing/pricing_plan_subscriptions/#{subscription_id}")
  end

  # Pricing Plans
  def retrieve_pricing_plan(pricing_plan_id)
    stripe_v2_request(:get, "/v2/billing/pricing_plans/#{pricing_plan_id}")
  end

  def create_pricing_plan(params)
    stripe_v2_request(:post, '/v2/billing/pricing_plans', params)
  end

  def update_pricing_plan(plan_id, params)
    stripe_v2_request(:post, "/v2/billing/pricing_plans/#{plan_id}", params)
  end

  # Billing Cadences
  def retrieve_billing_cadence(cadence_id)
    stripe_v2_request(:get, "/v2/billing/cadences/#{cadence_id}")
  end

  # Billing Intents
  def create_billing_intent(params)
    stripe_v2_request(:post, '/v2/billing/intents', params)
  end

  def reserve_billing_intent(billing_intent)
    stripe_v2_request(:post, "/v2/billing/intents/#{billing_intent.id}/reserve")
  end

  def commit_billing_intent(billing_intent)
    stripe_v2_request(:post, "/v2/billing/intents/#{billing_intent.id}/commit")
  end

  # Custom Pricing Units
  def create_custom_pricing_unit(params)
    stripe_v2_request(:post, '/v2/billing/custom_pricing_units', params)
  end

  # Licensed Items
  def create_licensed_item(params)
    stripe_v2_request(:post, '/v2/billing/licensed_items', params)
  end

  # License Fees
  def create_license_fee(params)
    stripe_v2_request(:post, '/v2/billing/license_fees', params)
  end

  # Service Actions
  def create_service_action(params)
    stripe_v2_request(:post, '/v2/billing/service_actions', params)
  end

  # Rate Cards
  def create_rate_card(params)
    stripe_v2_request(:post, '/v2/billing/rate_cards', params)
  end

  def add_rate_to_card(card_id, params)
    stripe_v2_request(:post, "/v2/billing/rate_cards/#{card_id}/rates", params)
  end

  # Metered Items
  def create_metered_item(params)
    stripe_v2_request(:post, '/v2/billing/metered_items', params)
  end

  # Meters (V1 API but used with V2)
  def create_meter(params)
    stripe_v2_request(:post, '/v1/billing/meters', params)
  end

  # Pricing Plan Components
  def add_pricing_plan_component(plan_id, params)
    stripe_v2_request(:post, "/v2/billing/pricing_plans/#{plan_id}/components", params)
  end

  # Checkout Sessions (V1 API but used with V2 plans)
  def create_checkout_session(params, api_version: nil)
    stripe_v2_request(:post, '/v1/checkout/sessions', params, api_version: api_version)
  end

  # Credit Grants (V1 API but used with V2)
  def retrieve_credit_grant(grant_id)
    stripe_v2_request(:get, "/v1/billing/credit_grants/#{grant_id}")
  end

  # API Options with support for custom versions
  def stripe_api_options(custom_version = nil)
    {
      api_key: ENV.fetch('STRIPE_SECRET_KEY', nil),
      stripe_version: custom_version || default_stripe_version
    }
  end

  def default_stripe_version
    '2025-08-27.preview'
  end

  def checkout_stripe_version
    '2025-08-27.preview;checkout_product_catalog_preview=v1'
  end

  def extract_attribute(object, key)
    object.respond_to?(key) ? object.public_send(key) : object[key.to_s]
  end
end
