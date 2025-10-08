# rubocop:disable Metrics/ClassLength
class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  def fetch_stripe_credit_balance
    return nil unless stripe_customer_id.present? && v2_enabled?

    grants = Stripe::Billing::CreditGrant.list(
      { customer: stripe_customer_id, limit: 100 },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )

    parse_credit_grants(grants)
  end

  def create_stripe_credit_grant(amount, type: 'promotional', metadata: {})
    return nil if stripe_customer_id.blank?

    params = build_credit_grant_params(amount, type, metadata)
    create_stripe_grant(params)
  end

  def grant_monthly_credits(amount = 2000, metadata: {})
    with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)
      stripe_grant = create_stripe_credit_grant(amount, type: 'monthly', metadata: metadata)
      update_credits(monthly: amount)

      log_monthly_grant(amount, expired_amount, stripe_grant&.id, metadata) if amount.positive?

      { success: true, granted: amount, expired: expired_amount, remaining: total_credits }
    end
  end

  def use_credit(feature: 'ai_captain', amount: 1, metadata: {})
    return { success: true, credits_used: 0, remaining: total_credits } if amount <= 0

    stripe_result = report_usage_to_stripe(amount, feature, metadata)
    return { success: false, message: "Usage reporting failed: #{stripe_result[:message]}" } unless stripe_result[:success]

    with_locked_account do
      return { success: false, message: 'Insufficient credits' } unless sufficient_balance?(amount)

      credit_type = deduct_credits(amount)
      log_credit_usage(amount, feature, credit_type, stripe_result[:event_id], metadata)

      build_credit_usage_result(amount, stripe_result[:event_id])
    end
  end

  def add_topup_credits(amount, metadata: {})
    with_locked_account do
      stripe_grant = create_stripe_credit_grant(amount, type: 'topup', metadata: metadata)
      grant_id = stripe_grant&.id

      new_balance = topup_credits + amount
      update_credits(topup: new_balance)

      log_credit_transaction(
        type: 'topup',
        amount: amount,
        credit_type: 'topup',
        description: 'Topup credits added',
        metadata: base_metadata(metadata).merge('stripe_grant_id' => grant_id)
      )

      { success: true, topup_balance: new_balance, total: total_credits }
    end
  end

  def total_credits
    monthly_credits + topup_credits
  end

  def credit_balance
    stripe_usage = fetch_stripe_usage_total
    initial_credits = initial_credits_from_local

    if stripe_usage.is_a?(Numeric) && initial_credits
      calculate_balance_from_stripe(stripe_usage, initial_credits)
    else
      local_fallback_balance
    end
  end

  def expire_monthly_credits(metadata: {})
    with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)
      { success: true, expired: expired_amount, remaining: total_credits }
    end
  end

  private

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  def fetch_stripe_usage_total
    return nil unless stripe_customer_id.present? && ENV['STRIPE_V2_METER_ID'].present?

    summaries = Stripe::Billing::Meter.list_event_summaries(
      ENV.fetch('STRIPE_V2_METER_ID', nil),
      {
        customer: stripe_customer_id,
        start_time: Time.current.beginning_of_month.to_i,
        end_time: Time.current.to_i
      },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )

    summaries_data = extract_summaries(summaries)
    summaries_data.sum { |s| (s['aggregated_value'] || s[:aggregated_value] || 0).to_i }
  rescue StandardError
    nil
  end

  def extract_summaries(data)
    return [] unless data

    if data.is_a?(Hash)
      data['data'] || data[:data] || []
    elsif data.is_a?(Array)
      data
    else
      []
    end
  end

  def initial_credits_from_local
    monthly_granted = account.credit_transactions
                             .where(transaction_type: 'grant', credit_type: 'monthly')
                             .sum(:amount)

    topup_granted = account.credit_transactions
                           .where(transaction_type: 'topup')
                           .sum(:amount)

    {
      monthly_granted: monthly_granted,
      topup_granted: topup_granted,
      total_granted: monthly_granted + topup_granted
    }
  end

  def parse_credit_grants(response)
    grants = extract_grants_from_response(response)
    return nil if grants.blank?

    totals = { monthly: 0, topup: 0, grant_details: [] }
    process_grants(grants, totals)

    build_credit_grant_summary(totals)
  end

  def extract_grant_amount(amount_data)
    amount_type = amount_data['type'] || amount_data[:type]
    return 0 unless amount_type

    value_data = amount_data[amount_type] || amount_data[amount_type.to_sym]
    extract_value_from_data(value_data)
  end

  def sync_local_balance_from_stripe(stripe_balance)
    update_credits(
      monthly: stripe_balance[:monthly],
      topup: stripe_balance[:topup]
    )
  end

  def expire_current_monthly_credits(metadata: {})
    current_monthly = monthly_credits
    return 0 if current_monthly.zero?

    update_credits(monthly: 0)

    log_credit_transaction(
      type: 'expire',
      amount: current_monthly,
      credit_type: 'monthly',
      description: 'Monthly credits expired',
      metadata: base_metadata(metadata)
    )

    current_monthly
  end

  def base_metadata(metadata)
    metadata.is_a?(Hash) ? metadata.stringify_keys : {}
  end

  # Helper methods for create_stripe_credit_grant
  def build_credit_grant_params(amount, type, metadata)
    params = {
      customer: stripe_customer_id,
      name: "#{type.titleize} Credits - #{Time.current.strftime('%Y-%m-%d')}",
      amount: { type: 'monetary', monetary: { currency: 'usd', value: amount.to_i } },
      category: type == 'topup' ? 'paid' : 'promotional',
      applicability_config: { scope: { price_type: 'metered' } },
      metadata: metadata.merge(
        account_id: account.id.to_s,
        created_by: 'chatwoot_v2',
        credit_type: type,
        credits: amount.to_s
      )
    }
    params[:expiry_config] = { type: 'end_of_service_period' } if type == 'monthly'
    params
  end

  def create_stripe_grant(params)
    Stripe::Billing::CreditGrant.create(
      params,
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  # Helper methods for grant_monthly_credits
  def log_monthly_grant(amount, expired_amount, grant_id, metadata)
    log_credit_transaction(
      type: 'grant',
      amount: amount,
      credit_type: 'monthly',
      description: 'Monthly credit grant',
      metadata: base_metadata(metadata).merge('expired_amount' => expired_amount, 'stripe_grant_id' => grant_id)
    )
  end

  # Helper methods for use_credit
  def report_usage_to_stripe(amount, feature, metadata)
    reporter = Enterprise::Billing::V2::UsageReporterService.new(account: account)
    reporter.report(amount, feature, metadata)
  end

  def sufficient_balance?(amount)
    current_balance = credit_balance
    current_balance[:total] >= amount
  end

  def deduct_credits(amount)
    current_monthly = monthly_credits
    current_topup = topup_credits

    if current_monthly >= amount
      update_credits(monthly: current_monthly - amount)
      'monthly'
    else
      monthly_used = current_monthly
      topup_used = amount - monthly_used
      update_credits(monthly: 0, topup: current_topup - topup_used)
      monthly_used.positive? ? 'mixed' : 'topup'
    end
  end

  def log_credit_usage(amount, feature, credit_type, event_id, metadata)
    log_credit_transaction(
      type: 'use',
      amount: amount,
      credit_type: credit_type,
      description: "Used for #{feature}",
      metadata: base_metadata(metadata).merge('feature' => feature, 'stripe_event_id' => event_id)
    )
  end

  def build_credit_usage_result(amount, event_id)
    final_balance = credit_balance
    {
      success: true,
      credits_used: amount,
      remaining: final_balance[:total],
      source: final_balance[:source],
      stripe_event_id: event_id
    }
  end

  # Helper methods for parse_credit_grants
  def extract_grants_from_response(response)
    return nil unless response

    data = response.is_a?(Stripe::StripeResponse) ? response.data : response
    return nil unless data

    data.is_a?(Hash) ? (data['data'] || data[:data] || []) : []
  end

  def process_grants(grants, totals)
    grants.each do |grant|
      next unless grant_active?(grant)

      amount_data = grant['amount'] || grant[:amount]
      next unless amount_data

      process_single_grant(grant, amount_data, totals)
    end
  end

  def grant_active?(grant)
    voided_at = grant['voided_at'] || grant[:voided_at]
    voided_at.nil?
  end

  def process_single_grant(grant, amount_data, totals)
    available = extract_grant_amount(amount_data)
    category = grant['category'] || grant[:category]
    expiry_config = grant['expiry_config'] || grant[:expiry_config]
    grant_id = grant['id'] || grant[:id]

    if category == 'paid' || expiry_config.nil?
      totals[:topup] += available
      totals[:grant_details] << { type: 'topup', amount: available, id: grant_id }
    else
      totals[:monthly] += available
      totals[:grant_details] << { type: 'monthly', amount: available, id: grant_id, expiry_config: expiry_config }
    end
  end

  def build_credit_grant_summary(totals)
    {
      monthly: totals[:monthly],
      topup: totals[:topup],
      total: totals[:monthly] + totals[:topup],
      last_synced: Time.current,
      source: 'stripe',
      grant_details: totals[:grant_details]
    }
  end

  # Helper methods for extract_grant_amount
  def extract_value_from_data(value_data)
    return 0 unless value_data

    (value_data['value'] || value_data[:value] || 0).to_i
  end

  # Helper methods for credit_balance
  def calculate_balance_from_stripe(stripe_usage, initial_credits)
    total_used = stripe_usage
    total_granted = initial_credits[:total_granted]
    remaining = [total_granted - total_used, 0].max

    monthly_portion = [remaining, initial_credits[:monthly_granted]].min
    topup_portion = [remaining - monthly_portion, 0].max

    balance = build_stripe_balance(monthly_portion, topup_portion, remaining, total_used, total_granted)
    sync_local_balance_from_stripe(balance)
    balance
  end

  def build_stripe_balance(monthly_portion, topup_portion, remaining, total_used, total_granted)
    {
      monthly: monthly_portion,
      topup: topup_portion,
      total: remaining,
      usage_from_stripe: total_used,
      granted_from_stripe: total_granted,
      last_synced: Time.current,
      source: 'stripe'
    }
  end

  def local_fallback_balance
    {
      monthly: monthly_credits,
      topup: topup_credits,
      total: total_credits,
      last_synced: Time.current,
      source: 'local_fallback'
    }
  end
end
# rubocop:enable Metrics/ClassLength
