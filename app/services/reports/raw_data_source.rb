class Reports::RawDataSource < Reports::DataSource
  def timeseries
    average_metric? ? average_timeseries : count_timeseries
  end

  def aggregate
    average_metric? ? average_scope.average(average_value_key) : count_scope.count
  end

  def summary
    results = summary_scope
              .select(*summary_select_fields)
              .group(summary_group_by_key)
              .index_by { |record| record.public_send(summary_index_key) }

    results.transform_values do |record|
      {
        resolved_conversations_count: record.resolved_count.to_i,
        avg_resolution_time: record.avg_resolution_time,
        avg_first_response_time: record.avg_first_response_time,
        avg_reply_time: record.avg_reply_time
      }
    end
  end

  private

  def count_timeseries
    grouped_count.map do |event_date, event_count|
      { value: event_count, timestamp: event_date.in_time_zone(timezone).to_i }
    end
  end

  def average_timeseries
    grouped_average_time = grouped_average_scope.average(average_value_key)
    grouped_event_count = grouped_average_scope.count

    grouped_average_time.each_with_object([]) do |(event_date, average_time), results|
      results << {
        value: average_time,
        timestamp: event_date.in_time_zone(timezone).to_i,
        count: grouped_event_count[event_date]
      }
    end
  end

  def grouped_average_scope
    average_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: timezone
    )
  end

  def grouped_count
    count_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: timezone
    ).count
  end

  def average_scope
    scope.reporting_events.where(name: raw_event_name, created_at: range, account_id: account.id)
  end

  def count_scope
    case metric.to_s
    when 'conversations_count'
      scope.conversations.where(account_id: account.id, created_at: range)
    when 'incoming_messages_count'
      scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
    when 'outgoing_messages_count'
      scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
    else
      reporting_event_count_scope
    end
  end

  def reporting_event_count_scope
    events = scope.reporting_events.where(
      name: raw_event_name,
      account_id: account.id,
      created_at: range
    )

    return events unless raw_count_strategy == :distinct_conversation

    events.joins(:conversation).select(:conversation_id).distinct
  end

  def summary_scope
    scope = account.reporting_events.where(created_at: range)
    return scope.joins(:conversation) if dimension_type == 'team'

    scope
  end

  def summary_select_fields
    [
      "#{summary_group_by_key} as #{summary_index_key}",
      count_select(:resolutions_count, :resolved_count),
      average_select(:avg_resolution_time, :avg_resolution_time),
      average_select(:avg_first_response_time, :avg_first_response_time),
      average_select(:reply_time, :avg_reply_time)
    ]
  end

  def count_select(metric_name, alias_name)
    "COUNT(CASE WHEN name = '#{raw_metric_event_name(metric_name)}' THEN 1 END) as #{alias_name}"
  end

  def average_select(metric_name, alias_name)
    "AVG(CASE WHEN name = '#{raw_metric_event_name(metric_name)}' THEN #{average_value_key} END) as #{alias_name}"
  end

  def raw_metric_event_name(metric_name)
    ReportingEvents::MetricRegistry.raw_event_name_for(metric_name)
  end

  def summary_group_by_key
    {
      'account' => :account_id,
      'agent' => :user_id,
      'inbox' => :inbox_id,
      'team' => 'conversations.team_id'
    }[dimension_type]
  end

  def summary_index_key
    summary_group_by_key.to_s.split('.').last
  end

  def average_value_key
    use_business_hours? ? :value_in_business_hours : :value
  end
end
