class Enterprise::Billing::V2::UsageAnalyticsService < Enterprise::Billing::V2::BaseService
  def fetch_usage_summary
    return { success: false, message: 'Not on V2 billing' } unless v2_enabled?

    stripe_analytics = fetch_stripe_meter_events

    if stripe_analytics && stripe_analytics[:success]
      stripe_analytics
    else
      local_summary = fetch_local_usage_summary
      local_summary[:warning] = 'Using cached data - Stripe unavailable'
      local_summary
    end
  end

  def fetch_stripe_meter_events
    return nil unless stripe_customer_id.present? && ENV['STRIPE_V2_METER_ID'].present?

    begin
      end_time = Time.current
      start_time = end_time.beginning_of_month

      summaries = fetch_meter_summaries_from_stripe(start_time, end_time)
      return nil unless summaries

      build_usage_analytics_result(summaries, start_time, end_time)
    rescue StandardError
      nil
    end
  end

  def fetch_stripe_analytics
    # Legacy method - kept for compatibility
    fetch_stripe_meter_events
  end

  def fetch_local_usage_summary
    # Get current month's usage from local credit transactions
    end_time = Time.current
    start_time = end_time.beginning_of_month

    usage_scope = credit_usage_scope(start_time: start_time, end_time: end_time)

    # Calculate usage from local credit transactions for current month
    total_used = usage_scope.sum(:amount)

    # Get usage by feature
    usage_by_feature = usage_scope
                       .group(feature_grouping_clause)
                       .sum(:amount)

    # Get current credit balance
    credit_service = Enterprise::Billing::V2::CreditManagementService.new(account: account)
    balance = credit_service.credit_balance

    {
      success: true,
      total_usage: total_used,
      credits_remaining: balance[:total],
      period_start: start_time,
      period_end: end_time,
      usage_by_feature: usage_by_feature,
      source: 'local' # Indicate this is from local data
    }
  end

  def recent_transactions(limit: 10)
    account.credit_transactions
           .recent
           .limit(limit)
  end

  private

  def parse_stripe_analytics(response, start_time, end_time)
    return nil unless response

    data = extract_data_from_response(response)
    return nil unless data

    metrics = calculate_usage_metrics_from_events(data)
    balance = fetch_credit_balance

    build_analytics_result(metrics, balance, start_time, end_time)
  end

  def credit_usage_scope(start_time:, end_time:)
    account.credit_transactions
           .where(transaction_type: 'use', created_at: start_time..end_time)
  end

  def feature_grouping_clause
    Arel.sql("COALESCE(metadata->>'feature', 'unattributed')")
  end

  def fetch_local_feature_breakdown(start_time, end_time)
    # Get feature breakdown from local transactions
    # This is needed because meter summaries don't include metadata
    account.credit_transactions
           .where(transaction_type: 'use', created_at: start_time..end_time)
           .group(feature_grouping_clause)
           .sum(:amount)
  end

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  # Helper methods for fetch_stripe_meter_events
  def fetch_meter_summaries_from_stripe(start_time, end_time)
    meter_id = ENV.fetch('STRIPE_V2_METER_ID', nil)
    response = Stripe::Billing::Meter.list_event_summaries(
      meter_id,
      { customer: stripe_customer_id, start_time: start_time.to_i, end_time: end_time.to_i },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
    extract_summaries_from_response(response)
  end

  def extract_summaries_from_response(response)
    return response if response.is_a?(Array)
    return response.data if response.respond_to?(:data)
    return response['data'] if response.is_a?(Hash) && response['data']

    nil
  end

  def build_usage_analytics_result(summaries, start_time, end_time)
    metrics = calculate_usage_metrics(summaries)
    balance = fetch_credit_balance
    usage_by_feature = fetch_local_feature_breakdown(start_time, end_time)

    {
      success: true,
      total_usage: metrics[:total_usage],
      credits_remaining: balance[:total],
      period_start: start_time,
      period_end: end_time,
      usage_by_feature: usage_by_feature,
      usage_by_day: metrics[:usage_by_day],
      event_count: summaries.length,
      source: 'stripe_meter_events'
    }
  end

  def calculate_usage_metrics(summaries)
    total_usage = 0
    usage_by_day = {}

    summaries.each do |summary|
      next unless summary.is_a?(Hash)

      value = summary['aggregated_value'].to_i
      total_usage += value

      next unless summary['period']&.[]('start')

      day = Time.zone.at(summary['period']['start']).strftime('%Y-%m-%d')
      usage_by_day[day] ||= 0
      usage_by_day[day] += value
    end

    { total_usage: total_usage, usage_by_day: usage_by_day }
  end

  def fetch_credit_balance
    Enterprise::Billing::V2::CreditManagementService.new(account: account).credit_balance
  end

  # Helper methods for parse_stripe_analytics
  def extract_data_from_response(response)
    response.is_a?(Hash) ? response : response.data
  end

  def calculate_usage_metrics_from_events(data)
    total_usage = 0
    usage_by_day = {}

    return { total_usage: total_usage, usage_by_day: usage_by_day } unless data['data'].is_a?(Array)

    data['data'].each do |event|
      value = event['value'] || 0
      total_usage += value

      next unless event['timestamp']

      day = Time.zone.at(event['timestamp']).strftime('%Y-%m-%d')
      usage_by_day[day] ||= 0
      usage_by_day[day] += value
    end

    { total_usage: total_usage, usage_by_day: usage_by_day }
  end

  def build_analytics_result(metrics, balance, start_time, end_time)
    {
      success: true,
      total_usage: metrics[:total_usage],
      credits_remaining: balance[:total],
      period_start: start_time,
      period_end: end_time,
      usage_by_day: metrics[:usage_by_day],
      source: 'stripe_analytics'
    }
  end
end
