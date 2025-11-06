module Enterprise::Billing::Concerns::StripeV2ClientHelper
  extend ActiveSupport::Concern

  private

  # Stripe client instance with API key
  def stripe_client
    @stripe_client ||= Stripe::StripeClient.new(ENV.fetch('STRIPE_SECRET_KEY', nil))
  end

  # Generic Stripe V2 API request wrapper (for methods not available in gem)
  def stripe_v2_request(method, path, params = {}, api_version: nil)
    StripeV2Client.request(method, path, params, stripe_api_options(api_version))
  end

  # Pricing Plan Subscriptions
  def retrieve_pricing_plan_subscription(subscription_id)
    stripe_client.v2.billing.pricing_plan_subscriptions.retrieve(subscription_id)
  end

  # Pricing Plans
  def retrieve_pricing_plan(pricing_plan_id)
    stripe_client.v2.billing.pricing_plans.retrieve(pricing_plan_id)
  end

  # gem not available - using custom HTTP client
  def update_pricing_plan(plan_id, params)
    stripe_v2_request(:post, "/v2/billing/pricing_plans/#{plan_id}", params)
  end

  # Billing Cadences
  def retrieve_billing_cadence(cadence_id)
    stripe_client.v2.billing.cadences.retrieve(cadence_id)
  end

  # gem not available - using custom HTTP client
  def create_billing_intent(params)
    stripe_v2_request(:post, '/v2/billing/intents', params)
  end

  def reserve_billing_intent(billing_intent)
    stripe_client.v2.billing.intents.reserve(billing_intent.id)
  end

  def commit_billing_intent(billing_intent)
    stripe_client.v2.billing.intents.commit(billing_intent.id)
  end

  # Checkout Sessions (V1 API but used with V2 plans)
  def create_checkout_session(params)
    Stripe::Checkout::Session.create(params, { stripe_version: checkout_stripe_version })
  end

  # Credit Grants (V1 API but used with V2)
  def retrieve_credit_grant(grant_id)
    Stripe::Billing::CreditGrant.retrieve(grant_id)
  end

  # API Options with support for custom versions
  def stripe_api_options(custom_version = nil)
    {
      api_key: ENV.fetch('STRIPE_SECRET_KEY', nil),
      stripe_version: custom_version || default_stripe_version
    }
  end

  def default_stripe_version
    '2025-10-29.preview'
  end

  def checkout_stripe_version
    '2025-10-29.preview;checkout_product_catalog_preview=v1'
  end

  def extract_attribute(object, key)
    object.respond_to?(key) ? object.public_send(key) : object[key.to_s]
  end
end
