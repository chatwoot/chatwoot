class Enterprise::Billing::TopupFulfillmentService
  pattr_initialize [:account!]

  def fulfill(credits:, amount_cents:, currency:)
    account.with_lock do
      create_stripe_credit_grant(credits, amount_cents, currency)
      update_account_credits(credits)
    end

    Rails.logger.info("Topup fulfilled for account #{account.id}: #{credits} credits, #{amount_cents} cents")
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
      expires_at: 6.months.from_now.to_i,
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
    account.custom_attributes['stripe_customer_id']
  end
end
