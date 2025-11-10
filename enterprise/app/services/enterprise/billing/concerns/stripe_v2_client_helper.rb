module Enterprise::Billing::Concerns::StripeV2ClientHelper
  extend ActiveSupport::Concern

  private

  # Stripe client instance with API key
  def stripe_client
    @stripe_client ||= Stripe::StripeClient.new(ENV.fetch('STRIPE_SECRET_KEY', nil))
  end

  # Pricing Plan Subscriptions
  def retrieve_pricing_plan_subscription(subscription_id)
    stripe_client.v2.billing.pricing_plan_subscriptions.retrieve(subscription_id)
  end

  # Pricing Plans
  def retrieve_pricing_plan(pricing_plan_id)
    stripe_client.v2.billing.pricing_plans.retrieve(pricing_plan_id)
  end

  def retrieve_billing_cadence(cadence_id)
    stripe_client.v2.billing.cadences.retrieve(cadence_id)
  end

  def create_billing_intent(params)
    response = Faraday.post('https://api.stripe.com/v2/billing/intents') do |req|
      req.headers['Authorization'] = "Bearer #{ENV.fetch('STRIPE_SECRET_KEY', nil)}"
      req.headers['Stripe-Version'] = default_stripe_version
      req.headers['Content-Type'] = 'application/json'
      req.body = params.to_json
    end

    JSON.parse(response.body)
  end

  def reserve_billing_intent(billing_intent_id)
    stripe_client.v2.billing.intents.reserve(billing_intent_id)
  end

  def commit_billing_intent(billing_intent_id)
    stripe_client.v2.billing.intents.commit(billing_intent_id)
  end

  # Checkout Sessions (V1 API but used with V2 plans)
  def create_checkout_session(params)
    Stripe::Checkout::Session.create(params, { stripe_version: checkout_stripe_version })
  end

  # Credit Grants (V1 API but used with V2)
  def retrieve_credit_grant(grant_id)
    Stripe::Billing::CreditGrant.retrieve(grant_id)
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
