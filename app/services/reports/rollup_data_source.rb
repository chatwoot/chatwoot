class Reports::RollupDataSource < Reports::DataSource
  def timeseries
    count_metric? ? count_timeseries : average_timeseries
  end

  def aggregate
    count_metric? ? count_aggregate : average_aggregate
  end

  def summary
    metric_results = summary_rows.index_by(&:dimension_id)

    merge_summary_results(metric_results, summary_conversation_counts)
  end

  private

  def count_timeseries
    grouped_data = all_periods_in_range.index_with { 0 }

    rollup_scope.each do |row|
      date_key = normalized_period_key(row.date)
      grouped_data[date_key] ||= 0
      grouped_data[date_key] += row.count
    end

    results = grouped_data.map do |date_key, count|
      { value: count, timestamp: date_key.in_time_zone(timezone).to_i }
    end

    results.sort_by { |result| result[:timestamp] }
  end

  def average_timeseries
    grouped_data = all_periods_in_range.index_with { { count: 0, sum_value: 0.0 } }

    rollup_scope.each { |row| accumulate_average_row(grouped_data, row) }

    results = grouped_data.map do |date_key, data|
      {
        value: data[:count].zero? ? 0 : data[:sum_value] / data[:count],
        timestamp: date_key.in_time_zone(timezone).to_i,
        count: data[:count]
      }
    end

    results.sort_by { |result| result[:timestamp] }
  end

  def count_aggregate
    rollup_scope.sum(:count).to_i
  end

  def average_aggregate
    result = rollup_scope.pick(Arel.sql("SUM(count), SUM(#{rollup_value_column})"))
    return nil if result.blank? || result[0].to_i.zero?

    result[1].to_f / result[0].to_i
  end

  def rollup_scope
    ReportingEventsRollup.where(
      account_id: account.id,
      metric: rollup_metric,
      dimension_type: dimension_type,
      dimension_id: dimension_id_for_rollup,
      date: rollup_date_range
    )
  end

  def summary_rows
    ReportingEventsRollup.where(
      account_id: account.id,
      dimension_type: dimension_type,
      date: rollup_date_range
    ).group(:dimension_id).select(*summary_select_fields)
  end

  def summary_conversation_counts
    account.conversations
           .where(created_at: range)
           .group(summary_conversation_group_by_key)
           .count
  end

  def merge_summary_results(metric_results, conversation_counts)
    (metric_results.keys | conversation_counts.keys).index_with do |dimension_id|
      summary_attributes_for(metric_results[dimension_id], conversation_counts[dimension_id])
    end
  end

  def summary_select_fields
    [
      'dimension_id',
      sum_count_select(:resolutions_count, :resolved_count),
      sum_count_select(:avg_resolution_time, :resolution_count),
      sum_value_select(:avg_resolution_time, :resolution_sum_value),
      sum_count_select(:avg_first_response_time, :first_response_count),
      sum_value_select(:avg_first_response_time, :first_response_sum_value),
      sum_count_select(:reply_time, :reply_count),
      sum_value_select(:reply_time, :reply_sum_value)
    ]
  end

  def sum_count_select(metric_name, alias_name)
    "SUM(CASE WHEN metric = '#{rollup_metric_name(metric_name)}' THEN count ELSE 0 END) as #{alias_name}"
  end

  def sum_value_select(metric_name, alias_name)
    "SUM(CASE WHEN metric = '#{rollup_metric_name(metric_name)}' THEN #{rollup_value_column} ELSE 0 END) as #{alias_name}"
  end

  def rollup_metric_name(metric_name)
    ReportingEvents::MetricRegistry.rollup_metric_for(metric_name)
  end

  def summary_attributes_for(row, conversations_count = 0)
    {
      conversations_count: conversations_count.to_i,
      resolved_conversations_count: row&.resolved_count.to_i,
      avg_resolution_time: average_from(row&.resolution_sum_value, row&.resolution_count),
      avg_first_response_time: average_from(row&.first_response_sum_value, row&.first_response_count),
      avg_reply_time: average_from(row&.reply_sum_value, row&.reply_count)
    }
  end

  def dimension_id_for_rollup
    dimension_type == 'account' ? account.id : scope.id
  end

  def summary_conversation_group_by_key
    {
      'account' => :account_id,
      'agent' => :assignee_id,
      'inbox' => :inbox_id,
      'team' => :team_id
    }[dimension_type]
  end

  def rollup_value_column
    use_business_hours? ? :sum_value_business_hours : :sum_value
  end

  def rollup_date_range
    tz = ActiveSupport::TimeZone[account.reporting_timezone]
    start_date = range.first.in_time_zone(tz).to_date
    end_date = (range.last - 1.second).in_time_zone(tz).to_date
    start_date..end_date
  end

  def all_periods_in_range
    current = normalized_period_key(rollup_date_range.first)
    periods = []

    while current <= rollup_date_range.last
      periods << current
      current = advance_period(current)
    end

    periods
  end

  def accumulate_average_row(grouped_data, row)
    date_key = normalized_period_key(row.date)
    grouped_data[date_key] ||= { count: 0, sum_value: 0.0 }
    grouped_data[date_key][:count] += row.count
    grouped_data[date_key][:sum_value] += row.public_send(rollup_value_column)
  end

  def normalized_period_key(date)
    case group_by
    when 'week' then date.beginning_of_week(:sunday)
    when 'month' then date.beginning_of_month
    when 'year' then date.beginning_of_year
    else date
    end
  end

  def advance_period(date)
    case group_by
    when 'week' then date + 1.week
    when 'month' then date + 1.month
    when 'year' then date + 1.year
    else date + 1.day
    end
  end

  def average_from(sum_value, count)
    return nil if count.to_i.zero?

    sum_value.to_f / count.to_i
  end
end
