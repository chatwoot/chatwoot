# rubocop:disable Metrics/ClassLength
class Enterprise::Billing::V2::CreditManagementService < Enterprise::Billing::V2::BaseService
  def fetch_stripe_credit_balance
    return nil unless stripe_customer_id.present? && v2_enabled?

    with_stripe_error_handling do
      response, _api_key = stripe_client.execute_request(
        :get,
        '/v1/billing/credit_grants',
        params: { customer: stripe_customer_id, limit: 100 }
      )

      parse_credit_grants(response)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch credit grants: #{e.message}"
    nil
  end

  def create_stripe_credit_grant(amount, type: 'promotional', metadata: {})
    return nil unless stripe_customer_id.present?

    params = {
      customer: stripe_customer_id,
      name: "#{type.titleize} Credits - #{Time.current.strftime('%Y-%m-%d')}",
      amount: {
        type: 'monetary',
        monetary: {
          currency: 'usd',
          value: amount.to_i
        }
      },
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

    response, _api_key = stripe_client.execute_request(:post, '/v1/billing/credit_grants', params: params)
    response.is_a?(Stripe::StripeResponse) ? response.data : response
  rescue StandardError => e
    Rails.logger.error "Failed to create credit grant: #{e.message}"
    nil
  end

  def grant_monthly_credits(amount = 2000, metadata: {})
    with_locked_account do
      expired_amount = expire_current_monthly_credits(metadata: metadata)

      stripe_grant = create_stripe_credit_grant(amount, type: 'monthly', metadata: metadata)
      grant_id = stripe_grant ? (stripe_grant['id'] || stripe_grant[:id]) : nil

      update_credits(monthly: amount)

      if amount.positive?
        log_credit_transaction(
          type: 'grant',
          amount: amount,
          credit_type: 'monthly',
          description: 'Monthly credit grant',
          metadata: base_metadata(metadata).merge(
            'expired_amount' => expired_amount,
            'stripe_grant_id' => grant_id
          )
        )
      end

      { success: true, granted: amount, expired: expired_amount, remaining: total_credits }
    end

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to grant monthly credits: #{e.message}"
    { success: false, message: e.message }
  end

  # rubocop:disable Metrics/MethodLength
  def use_credit(feature: 'ai_captain', amount: 1, metadata: {})
    return { success: true, credits_used: 0, remaining: total_credits } if amount <= 0

    reporter = Enterprise::Billing::V2::UsageReporterService.new(account: account)
    stripe_result = reporter.report(amount, feature, metadata)

    return { success: false, message: "Usage reporting failed: #{stripe_result[:message]}" } unless stripe_result[:success]

    with_locked_account do
      current_balance = credit_balance

      if current_balance[:total] < amount
        Rails.logger.warn 'Local cache out of sync with Stripe'
        return { success: false, message: 'Insufficient credits' }
      end

      current_monthly = monthly_credits
      current_topup = topup_credits
      credit_type = 'monthly'

      if current_monthly >= amount
        update_credits(monthly: current_monthly - amount)
      else
        monthly_used = current_monthly
        topup_used = amount - monthly_used
        update_credits(monthly: 0, topup: current_topup - topup_used)
        credit_type = monthly_used.positive? ? 'mixed' : 'topup'
      end

      log_credit_transaction(
        type: 'use',
        amount: amount,
        credit_type: credit_type,
        description: "Used for #{feature}",
        metadata: base_metadata(metadata).merge(
          'feature' => feature,
          'stripe_event_id' => stripe_result[:event_id]
        )
      )

      final_balance = credit_balance
      {
        success: true,
        credits_used: amount,
        remaining: final_balance[:total],
        source: final_balance[:source],
        stripe_event_id: stripe_result[:event_id]
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def add_topup_credits(amount, metadata: {})
    with_locked_account do
      stripe_grant = create_stripe_credit_grant(amount, type: 'topup', metadata: metadata)
      grant_id = stripe_grant ? (stripe_grant['id'] || stripe_grant[:id]) : nil

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

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to add topup credits: #{e.message}"
    { success: false, message: e.message }
  end

  def total_credits
    monthly_credits + topup_credits
  end

  def credit_balance
    stripe_usage = fetch_stripe_usage_total
    initial_credits = initial_credits_from_local

    if stripe_usage.is_a?(Numeric) && initial_credits
      total_used = stripe_usage
      total_granted = initial_credits[:total_granted]
      remaining = [total_granted - total_used, 0].max

      monthly_portion = [remaining, initial_credits[:monthly_granted]].min
      topup_portion = [remaining - monthly_portion, 0].max

      balance = {
        monthly: monthly_portion,
        topup: topup_portion,
        total: remaining,
        usage_from_stripe: total_used,
        granted_from_stripe: total_granted,
        last_synced: Time.current,
        source: 'stripe'
      }

      sync_local_balance_from_stripe(balance)
      balance
    else
      {
        monthly: monthly_credits,
        topup: topup_credits,
        total: total_credits,
        last_synced: Time.current,
        source: 'local_fallback'
      }
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

    response, _api_key = stripe_client.execute_request(
      :get,
      "/v1/billing/meters/#{ENV.fetch('STRIPE_V2_METER_ID', nil)}/event_summaries",
      headers: { 'Stripe-Version' => '2025-08-27.preview' },
      params: {
        customer: stripe_customer_id,
        start_time: Time.current.beginning_of_month.to_i,
        end_time: Time.current.to_i
      }
    )

    data = response.is_a?(Stripe::StripeResponse) ? response.data : response
    summaries = extract_summaries(data)

    summaries.sum { |s| (s['aggregated_value'] || s[:aggregated_value] || 0).to_i }
  rescue StandardError => e
    Rails.logger.error "Failed to fetch meter summaries: #{e.message}"
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
    return nil unless response

    data = response.is_a?(Stripe::StripeResponse) ? response.data : response
    return nil unless data

    grants = data.is_a?(Hash) ? (data['data'] || data[:data] || []) : []
    return nil if grants.empty?

    monthly = 0
    topup = 0
    grant_details = []

    grants.each do |grant|
      voided_at = grant['voided_at'] || grant[:voided_at]
      next unless voided_at.nil?

      amount_data = grant['amount'] || grant[:amount]
      next unless amount_data

      available = extract_grant_amount(amount_data)
      category = grant['category'] || grant[:category]
      expiry_config = grant['expiry_config'] || grant[:expiry_config]
      grant_id = grant['id'] || grant[:id]

      if category == 'paid' || expiry_config.nil?
        topup += available
        grant_details << { type: 'topup', amount: available, id: grant_id }
      else
        monthly += available
        grant_details << { type: 'monthly', amount: available, id: grant_id, expiry_config: expiry_config }
      end
    end

    {
      monthly: monthly,
      topup: topup,
      total: monthly + topup,
      last_synced: Time.current,
      source: 'stripe',
      grant_details: grant_details
    }
  end

  def extract_grant_amount(amount_data)
    amount_type = amount_data['type'] || amount_data[:type]

    case amount_type
    when 'custom_pricing_unit'
      cpu_data = amount_data['custom_pricing_unit'] || amount_data[:custom_pricing_unit]
      (cpu_data&.[]('value') || cpu_data&.[](:value) || 0).to_i
    when 'monetary'
      monetary_data = amount_data['monetary'] || amount_data[:monetary]
      (monetary_data&.[]('value') || monetary_data&.[](:value) || 0).to_i
    else
      0
    end
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
end
# rubocop:enable Metrics/ClassLength
