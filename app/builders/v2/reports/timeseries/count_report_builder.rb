class V2::Reports::Timeseries::CountReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def timeseries
    use_rollup? ? rollup_timeseries : raw_timeseries
  end

  def aggregate_value
    use_rollup? ? rollup_aggregate_value : raw_aggregate_value
  end

  private

  def raw_timeseries
    grouped_count.each_with_object([]) do |element, arr|
      event_date, event_count = element

      # The `event_date` is in Date format (without time), such as "Wed, 15 May 2024".
      # We need a timestamp for the start of the day. However, we can't use `event_date.to_time.to_i`
      # because it converts the date to 12:00 AM server timezone.
      # The desired output should be 12:00 AM in the specified timezone.
      arr << { value: event_count, timestamp: event_date.in_time_zone(timezone).to_i }
    end
  end

  def rollup_timeseries
    metric = metric_to_rollup_metric(params[:metric])
    return [] if metric.blank?

    dimension_type = dimension_type_to_rollup
    dimension_id = dimension_id_for_rollup

    rollup_rows = ReportingEventsRollup.where(
      account_id: account.id,
      metric: metric,
      dimension_type: dimension_type,
      dimension_id: dimension_id,
      date: rollup_date_range
    )

    group_and_aggregate_rollup_counts(rollup_rows)
  end

  def raw_aggregate_value
    object_scope.count
  end

  def rollup_aggregate_value
    metric = metric_to_rollup_metric(params[:metric])
    return 0 if metric.blank?

    dimension_type = dimension_type_to_rollup
    dimension_id = dimension_id_for_rollup

    ReportingEventsRollup.where(
      account_id: account.id,
      metric: metric,
      dimension_type: dimension_type,
      dimension_id: dimension_id,
      date: rollup_date_range
    ).sum(:count).to_i
  end

  def dimension_id_for_rollup
    case params[:type].to_s
    when 'account'
      account.id
    when 'agent'
      params[:id].to_i
    when 'inbox'
      params[:id].to_i
    when 'team'
      params[:id].to_i
    end
  end

  def group_and_aggregate_rollup_counts(rollup_rows)
    grouped_data = {}

    rollup_rows.each do |row|
      date_key = case group_by
                 when 'day'
                   row.date
                 when 'week'
                   row.date.beginning_of_week(:monday)
                 when 'month'
                   row.date.beginning_of_month
                 when 'year'
                   row.date.beginning_of_year
                 else
                   row.date
                 end

      grouped_data[date_key] ||= 0
      grouped_data[date_key] += row.count
    end

    grouped_data.each_with_object([]) do |(date_key, count), arr|
      arr << {
        value: count,
        timestamp: date_key.in_time_zone(timezone).to_i
      }
    end.sort_by { |h| h[:timestamp] }
  end

  def metric
    @metric ||= params[:metric]
  end

  def object_scope
    send("scope_for_#{metric}")
  end

  def scope_for_conversations_count
    scope.conversations.where(account_id: account.id, created_at: range)
  end

  def scope_for_incoming_messages_count
    scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
  end

  def scope_for_outgoing_messages_count
    scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
  end

  def scope_for_resolutions_count
    scope.reporting_events.where(
      name: :conversation_resolved,
      account_id: account.id,
      created_at: range
    )
  end

  def scope_for_bot_resolutions_count
    scope.reporting_events.where(
      name: :conversation_bot_resolved,
      account_id: account.id,
      created_at: range
    )
  end

  def scope_for_bot_handoffs_count
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(
      name: :conversation_bot_handoff,
      account_id: account.id,
      created_at: range
    ).distinct
  end

  def grouped_count
    # IMPORTANT: time_zone parameter affects both data grouping AND output timestamps
    # It converts timestamps to the target timezone before grouping, which means
    # the same event can fall into different day buckets depending on timezone
    # Example: 2024-01-15 00:00 UTC becomes 2024-01-14 16:00 PST (falls on different day)
    @grouped_values = object_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: timezone
    ).count
  end
end
