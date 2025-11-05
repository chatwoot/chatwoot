class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  # Sync monthly response credits (resets on billing cycle with topup preservation)
  def sync_monthly_response_credits(amount)
    with_locked_account do
      # Preserve topup credits but cap at remaining balance
      preserved_topup = preserve_topup_on_reset(
        current_topup: response_topup_credits,
        new_monthly: amount,
        current_usage: response_usage
      )
      update_response_credits(monthly: amount, topup: preserved_topup)
    end
  end

  # Add topup credits for responses
  def add_response_topup_credits(amount)
    with_locked_account do
      new_topup = response_topup_credits + amount
      update_response_credits(topup: new_topup)
    end
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

  private

  # Preserve topup credits on monthly reset, capped at remaining balance
  # Formula: min(current_topup, max(0, (new_monthly + current_topup) - current_usage))
  def preserve_topup_on_reset(current_topup:, new_monthly:, current_usage:)
    # Calculate remaining balance after usage
    total_after_sync = new_monthly + current_topup
    remaining_balance = [total_after_sync - current_usage, 0].max

    # Cap topup at remaining balance to avoid over-crediting
    [current_topup, remaining_balance].min
  end

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
