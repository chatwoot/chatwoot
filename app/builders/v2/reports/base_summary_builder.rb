class V2::Reports::BaseSummaryBuilder
  include DateRangeHelper
  include V2::Reports::Concerns::RollupConditions

  def build
    load_data
    prepare_report
  end

  private

  # Summary builders fetch all metrics in a single query, so the per-metric
  # check from RollupConditions does not apply.
  def metric_covered?
    true
  end

  def load_data
    @conversations_count = fetch_conversations_count
    use_rollup? ? load_rollup_data : load_reporting_events_data
  end

  def load_reporting_events_data
    # Extract the column name for indexing (e.g., 'conversations.team_id' -> 'team_id')
    index_key = group_by_key.to_s.split('.').last

    results = reporting_events
              .select(
                "#{group_by_key} as #{index_key}",
                "COUNT(CASE WHEN name = 'conversation_resolved' THEN 1 END) as resolved_count",
                "AVG(CASE WHEN name = 'conversation_resolved' THEN #{average_value_key} END) as avg_resolution_time",
                "AVG(CASE WHEN name = 'first_response' THEN #{average_value_key} END) as avg_first_response_time",
                "AVG(CASE WHEN name = 'reply_time' THEN #{average_value_key} END) as avg_reply_time"
              )
              .group(group_by_key)
              .index_by { |record| record.public_send(index_key) }

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def load_rollup_data
    group_by_key.to_s.split('.').last
    dimension_type = dimension_type_to_rollup
    value_col = rollup_value_column

    # Fetch rollup data grouped by dimension_id
    rollup_rows = ReportingEventsRollup.where(
      account_id: account.id,
      dimension_type: dimension_type,
      date: rollup_date_range
    ).group(:dimension_id).select(
      'dimension_id',
      'SUM(CASE WHEN metric = \'resolutions_count\' THEN count ELSE 0 END) as resolved_count',
      "SUM(CASE WHEN metric = 'resolution_time' THEN count ELSE 0 END) as resolution_count",
      "SUM(CASE WHEN metric = 'resolution_time' THEN #{value_col} ELSE 0 END) as resolution_sum_value",
      "SUM(CASE WHEN metric = 'first_response' THEN count ELSE 0 END) as first_response_count",
      "SUM(CASE WHEN metric = 'first_response' THEN #{value_col} ELSE 0 END) as first_response_sum_value",
      "SUM(CASE WHEN metric = 'reply_time' THEN count ELSE 0 END) as reply_count",
      "SUM(CASE WHEN metric = 'reply_time' THEN #{value_col} ELSE 0 END) as reply_sum_value"
    )

    # Convert to the expected format
    results = {}
    rollup_rows.each do |row|
      results[row.dimension_id] = row
    end

    @resolved_count = results.transform_values { |r| r.resolved_count.to_i }
    @avg_resolution_time = results.transform_values do |r|
      r.resolution_count.to_i.zero? ? nil : (r.resolution_sum_value.to_f / r.resolution_count.to_i)
    end
    @avg_first_response_time = results.transform_values do |r|
      r.first_response_count.to_i.zero? ? nil : (r.first_response_sum_value.to_f / r.first_response_count.to_i)
    end
    @avg_reply_time = results.transform_values do |r|
      r.reply_count.to_i.zero? ? nil : (r.reply_sum_value.to_f / r.reply_count.to_i)
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range)
  end

  def fetch_conversations_count
    # Override this method
  end

  def group_by_key
    # Override this method
  end

  def prepare_report
    # Override this method
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]).present? ? :value_in_business_hours : :value
  end
end
