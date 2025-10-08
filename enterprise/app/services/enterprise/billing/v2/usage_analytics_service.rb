class Enterprise::Billing::V2::UsageAnalyticsService < Enterprise::Billing::V2::BaseService
  def fetch_usage_summary
    return { success: false, message: 'Not on V2 billing' } unless v2_enabled?

    # ALWAYS use Stripe as primary source
    stripe_analytics = fetch_stripe_meter_events

    if stripe_analytics && stripe_analytics[:success]
      Rails.logger.info 'Using Stripe meter events as source of truth'
      return stripe_analytics
    else
      Rails.logger.warn 'Stripe unavailable - using local cache as fallback'
      # Only use local as fallback with warning
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
      meter_id = ENV.fetch('STRIPE_V2_METER_ID', nil)

      # Fetch meter event summaries
      response = stripe_client.execute_request(
        :get,
        "/v1/billing/meters/#{meter_id}/event_summaries",
        params: {
          customer: stripe_customer_id,
          start_time: start_time.to_i,
          end_time: end_time.to_i
        }
      )

      # Handle response - it can be an Array directly or a Hash with 'data'
      summaries = if response.is_a?(Array)
                    response
                  elsif response.is_a?(Hash) && response['data']
                    response['data']
                  end

      if summaries
        # Calculate total usage from summaries
        total_usage = 0
        usage_by_day = {}

        summaries.each do |summary|
          next unless summary.is_a?(Hash)

          value = summary['aggregated_value'].to_i
          total_usage += value

          # Group by day if period info available
          next unless summary['period'] && summary['period']['start']

          day = Time.at(summary['period']['start']).strftime('%Y-%m-%d')
          usage_by_day[day] ||= 0
          usage_by_day[day] += value
        end

        # Get current balance from credit service
        credit_service = Enterprise::Billing::V2::CreditManagementService.new(account: account)
        balance = credit_service.credit_balance

        # For feature breakdown, we'll need to track this locally
        # since meter summaries don't include feature metadata
        usage_by_feature = fetch_local_feature_breakdown(start_time, end_time)

        {
          success: true,
          total_usage: total_usage,
          credits_remaining: balance[:total],
          period_start: start_time,
          period_end: end_time,
          usage_by_feature: usage_by_feature,
          usage_by_day: usage_by_day,
          event_count: summaries.length,
          source: 'stripe_meter_events'
        }
      end
    rescue StandardError => e
      Rails.logger.error "Failed to fetch Stripe meter summaries: #{e.message}"
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

    data = response.is_a?(Hash) ? response : response.data
    return nil unless data

    # Sum up all meter events
    total_usage = 0
    usage_by_day = {}

    if data['data'].is_a?(Array)
      data['data'].each do |event|
        value = event['value'] || 0
        total_usage += value

        # Group by day if timestamp available
        next unless event['timestamp']

        day = Time.at(event['timestamp']).strftime('%Y-%m-%d')
        usage_by_day[day] ||= 0
        usage_by_day[day] += value
      end
    end

    # Get current credit balance
    credit_service = Enterprise::Billing::V2::CreditManagementService.new(account: account)
    balance = credit_service.credit_balance

    {
      success: true,
      total_usage: total_usage,
      credits_remaining: balance[:total],
      period_start: start_time,
      period_end: end_time,
      usage_by_day: usage_by_day,
      source: 'stripe_analytics'
    }
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
end
