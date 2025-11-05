class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  def sync_monthly_credits(amount)
    with_locked_account do
      update_credits(monthly: amount)
    end
  end

  def add_topup_credits(amount)
    with_locked_account do
      update_credits(topup: topup_credits + amount)
    end
  end

  def expire_monthly_credits
    with_locked_account do
      expired = monthly_credits
      update_credits(monthly: 0) if expired.positive?
      expired
    end
  end

  def credit_balance
    {
      monthly: monthly_credits,
      topup: topup_credits,
      total: total_credits
    }
  end

  def fetch_credit_grants
    customer_id = stripe_customer_id
    return [] if customer_id.blank?

    response = Stripe::Billing::CreditGrant.list(
      { customer: customer_id, limit: 100 }
    )

    grants = response.data.map do |grant|
      transform_credit_grant(grant)
    end
    grants.reject { |grant| grant[:credits].zero? }
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to fetch credit grants: #{e.message}")
    []
  end

  def total_credits
    monthly_credits + topup_credits
  end

  private

  def transform_credit_grant(grant)
    category = grant_attribute(grant, :category)
    metadata = grant_attribute(grant, :metadata) || {}

    {
      id: grant_attribute(grant, :id),
      name: grant_attribute(grant, :name),
      credits: calculate_grant_credits(category, metadata),
      category: category,
      source: metadata['source'] || category,
      effective_at: parse_timestamp(grant_attribute(grant, :effective_at)),
      expires_at: parse_timestamp(grant_attribute(grant, :expires_at)),
      voided_at: parse_timestamp(grant_attribute(grant, :voided_at)),
      created_at: parse_timestamp(grant_attribute(grant, :created))
    }
  end

  def grant_attribute(grant, key)
    grant[key] || grant.public_send(key)
  end

  def calculate_grant_credits(category, metadata)
    return metadata['credits'].to_i if category == 'paid' && metadata['credits']

    0
  end

  def parse_timestamp(timestamp)
    return nil unless timestamp

    Time.zone.at(timestamp)
  end

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end
end
