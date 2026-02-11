module V2::Reports::Concerns::RollupConditions
  COVERED_METRICS = {
    avg_first_response_time: :first_response,
    avg_resolution_time: :resolution_time,
    reply_time: :reply_time,
    resolutions_count: :resolutions_count,
    bot_resolutions_count: :bot_resolutions_count,
    bot_handoffs_count: :bot_handoffs_count
  }.freeze

  SUPPORTED_DIMENSIONS = %w[account agent inbox team].freeze

  def use_rollup?
    # Condition 0: reporting_timezone must be configured on account
    return false if account.reporting_timezone.blank?

    # Condition 1: Feature flag must be enabled
    return false unless account.feature_enabled?('reporting_events_rollup')

    # Condition 2: Metric must be covered by rollup
    return false unless metric_covered?

    # Condition 3: Not hourly granularity
    return false if group_by == 'hour'

    # Condition 4: Dimension must be supported
    return false unless dimension_supported?

    # Condition 5: Timezone must match
    timezone_matches_account?
  end

  private

  def metric_covered?
    COVERED_METRICS.key?(params[:metric].to_sym)
  end

  def dimension_supported?
    return true if params[:type].blank? # account dimension (no specific ID)

    SUPPORTED_DIMENSIONS.include?(params[:type].to_s)
  end

  def timezone_matches_account?
    return true if params[:timezone_offset].blank?

    account_timezone = account.reporting_timezone
    offset_in_seconds = params[:timezone_offset].to_f * 3600

    # Find the timezone that matches the offset
    matching_zone = ActiveSupport::TimeZone.all.find do |zone|
      zone.now.utc_offset == offset_in_seconds
    end

    return false if matching_zone.blank?

    # Convert account timezone to current UTC offset and compare
    account_zone = ActiveSupport::TimeZone[account_timezone]
    account_zone&.now&.utc_offset == offset_in_seconds
  end

  def metric_to_rollup_metric(metric)
    COVERED_METRICS[metric.to_sym]
  end

  def dimension_type_to_rollup
    case params[:type].to_s
    when 'account'
      :account
    when 'agent'
      :agent
    when 'inbox'
      :inbox
    when 'team'
      :team
    end
  end
end
