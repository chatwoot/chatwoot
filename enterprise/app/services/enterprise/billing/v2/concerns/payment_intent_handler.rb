module Enterprise::Billing::V2::Concerns::PaymentIntentHandler
  extend ActiveSupport::Concern

  private

  def create_payment_if_needed(intent, intent_id)
    amount_due = intent.amount_details&.total || intent.amount_details.total
    return nil unless amount_due&.to_i&.positive?

    payment_method_id = fetch_default_payment_method
    create_upfront_payment_intent(amount_due, intent.currency, payment_method_id, intent_id)
  end

  def fetch_default_payment_method
    customer = Stripe::Customer.retrieve(
      @customer_id,
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
    customer.invoice_settings&.default_payment_method
  end

  def create_upfront_payment_intent(amount_due, currency, payment_method_id, intent_id)
    payment_intent = Stripe::PaymentIntent.create(
      payment_intent_params(amount_due, currency, payment_method_id, intent_id),
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )

    payment_intent.id
  end

  def payment_intent_params(amount_due, currency, payment_method_id, intent_id)
    {
      amount: amount_due,
      currency: currency || 'usd',
      customer: @customer_id,
      payment_method: payment_method_id,
      automatic_payment_methods: {
        enabled: true,
        allow_redirects: 'never'
      },
      confirm: true,
      off_session: true,
      metadata: { billing_intent_id: intent_id }
    }
  end

  def fetch_billing_intent(intent_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/intents/#{intent_id}",
      {},
      stripe_api_options
    )
  end

  def commit_billing_intent(intent_id, payment_intent_id)
    commit_params = payment_intent_id ? { payment_intent: payment_intent_id } : {}

    StripeV2Client.request(
      :post,
      "/v2/billing/intents/#{intent_id}/commit",
      commit_params,
      stripe_api_options
    )
  end
end
