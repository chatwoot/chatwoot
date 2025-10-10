class Enterprise::Billing::V2::StripeCreditSyncService < Enterprise::Billing::V2::BaseService
  def fetch_stripe_credit_balance
    return nil unless stripe_customer_id.present? && v2_enabled?

    grants = Stripe::Billing::CreditGrant.list(
      { customer: stripe_customer_id, limit: 100 },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )

    parse_credit_grants(grants)
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

  def create_stripe_credit_grant(amount, type: 'promotional', metadata: {})
    return nil if stripe_customer_id.blank?

    params = build_credit_grant_params(amount, type, metadata)
    create_stripe_grant(params)
  end

  def calculate_balance_from_stripe(stripe_usage, initial_credits)
    total_used = stripe_usage
    total_granted = initial_credits[:total_granted]
    remaining = [total_granted - total_used, 0].max

    monthly_portion = [remaining, initial_credits[:monthly_granted]].min
    topup_portion = [remaining - monthly_portion, 0].max

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
      total: monthly_credits + topup_credits,
      last_synced: Time.current,
      source: 'local_fallback'
    }
  end

  private

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
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

  def parse_credit_grants(response)
    grants = extract_grants_from_response(response)
    return nil if grants.blank?

    totals = { monthly: 0, topup: 0, grant_details: [] }
    process_grants(grants, totals)

    build_credit_grant_summary(totals)
  end

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

  def extract_grant_amount(amount_data)
    amount_type = amount_data['type'] || amount_data[:type]
    return 0 unless amount_type

    value_data = amount_data[amount_type] || amount_data[amount_type.to_sym]
    extract_value_from_data(value_data)
  end

  def extract_value_from_data(value_data)
    return 0 unless value_data

    (value_data['value'] || value_data[:value] || 0).to_i
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

  def build_credit_grant_params(amount, type, metadata)
    {
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
  end

  def create_stripe_grant(params)
    Stripe::Billing::CreditGrant.create(
      params,
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end
end
