class Enterprise::Billing::TopupFulfillmentService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def fulfill(credits:, amount_cents:, currency:)
    account.with_lock do
      create_stripe_credit_grant(credits, amount_cents, currency)
      update_account_credits(credits)
    end
  end

  private

  def create_stripe_credit_grant(credits, amount_cents, currency)
    Stripe::Billing::CreditGrant.create(
      customer: stripe_customer_id,
      name: "Topup: #{credits} credits",
      amount: {
        type: 'monetary',
        monetary: { currency: currency, value: amount_cents }
      },
      applicability_config: {
        scope: { price_type: 'metered' }
      },
      category: 'paid',
      metadata: {
        account_id: account.id.to_s,
        source: 'topup',
        credits: credits.to_s
      }
    )
  end

  def update_account_credits(credits)
    current_limits = account.limits || {}
    current_total = current_limits['captain_responses'].to_i
    new_total = current_total + credits

    account.update!(
      limits: current_limits.merge(
        'captain_responses' => new_total
      )
    )
  end

  def stripe_customer_id
    account.custom_attributes&.[]('stripe_customer_id')
  end
end
