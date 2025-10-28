class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  # rubocop:disable Metrics/MethodLength
  def use_credit(feature: 'ai_captain', amount: 1, metadata: {})
    with_locked_account do
      # Handle refunds (negative amounts)
      if amount.negative?
        refund_credits(amount.abs)
        log_credit_transaction(
          type: 'use',
          amount: amount,
          credit_type: 'topup',
          description: "Refund for #{feature}",
          metadata: metadata
        )
        { success: true, credits_refunded: amount.abs, remaining: total_credits }
      elsif total_credits < amount
        # Handle usage (positive amounts)
        { success: false, message: 'Insufficient credits' }
      else
        # Report usage to Stripe
        stripe_result = report_usage_to_stripe(amount, feature)

        if stripe_result[:success]
          # Deduct credits locally (monthly first, then topup)
          deduct_credits(amount)

          # Log transaction
          log_credit_transaction(
            type: 'use',
            amount: amount,
            credit_type: determine_credit_type(amount),
            description: "Used for #{feature}",
            metadata: metadata
          )

          { success: true, credits_used: amount, remaining: total_credits }
        else
          { success: false, message: stripe_result[:message] }
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def sync_monthly_credits(amount, metadata: {})
    with_locked_account do
      update_credits(monthly: amount)
      if amount.positive?
        log_credit_transaction(
          type: 'grant',
          amount: amount,
          credit_type: 'monthly',
          description: 'Monthly credits from Stripe',
          metadata: metadata
        )
      end
    end
  end

  def add_topup_credits(amount, metadata: {})
    with_locked_account do
      update_credits(topup: topup_credits + amount)
      log_credit_transaction(
        type: 'topup',
        amount: amount,
        credit_type: 'topup',
        description: 'Topup credits added',
        metadata: metadata
      )
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
    usage_stats = calculate_usage_stats

    {
      monthly: monthly_credits,
      topup: topup_credits,
      total: total_credits,
      usage_this_month: usage_stats[:this_month],
      usage_total: usage_stats[:total]
    }
  end

  def fetch_credit_grants
    customer_id = stripe_customer_id
    return [] if customer_id.blank?

    response = Stripe::Billing::CreditGrant.list(
      { customer: customer_id, limit: 100 },
      stripe_api_options
    )

    grants = response.data.map do |grant|
      transform_credit_grant(grant)
    end
    grants.reject { |grant| grant[:credits].zero? }
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to fetch credit grants: #{e.message}")
    []
  end

  def calculate_usage_stats
    month_start = Time.current.beginning_of_month

    this_month_usage = account.credit_transactions
                              .where(transaction_type: 'use', created_at: month_start..Time.current)
                              .sum(:amount)
                              .abs

    total_usage = account.credit_transactions
                         .where(transaction_type: 'use')
                         .sum(:amount)
                         .abs

    {
      this_month: this_month_usage,
      total: total_usage
    }
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

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end

  def report_usage_to_stripe(amount, feature)
    Enterprise::Billing::V2::UsageReporterService.new(account: account).report(amount, feature)
  end

  def deduct_credits(amount)
    if monthly_credits >= amount
      update_credits(monthly: monthly_credits - amount)
    else
      remaining = amount - monthly_credits
      update_credits(monthly: 0, topup: topup_credits - remaining)
    end
  end

  def refund_credits(amount)
    # Refunds are added to topup credits
    update_credits(topup: topup_credits + amount)
  end

  def determine_credit_type(amount)
    if monthly_credits >= amount
      'monthly'
    elsif monthly_credits.positive?
      'mixed'
    else
      'topup'
    end
  end
end
