class Reports::RawDataSource < Reports::DataSource
  def timeseries
    average_metric? ? average_timeseries : count_timeseries
  end

  def aggregate
    average_metric? ? average_scope.average(average_value_key) : count_scope.count
  end

  def summary
    metric_results = summary_scope
                     .select(*summary_select_fields)
                     .group(summary_group_by_key)
                     .index_by { |record| record.public_send(summary_index_key) }

    merge_summary_results(metric_results, summary_conversation_counts)
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

  def summary_conversation_counts
    account.conversations
           .where(created_at: range)
           .group(summary_conversation_group_by_key)
           .count
  end

  def merge_summary_results(metric_results, conversation_counts)
    (metric_results.keys | conversation_counts.keys).each_with_object({}) do |dimension_id, results|
      record = metric_results[dimension_id]
      results[dimension_id] = summary_attributes_for(record, conversation_counts[dimension_id])
    end
  end

  def summary_select_fields
    ["#{summary_group_by_key} as #{summary_index_key}"] + summary_metrics.map { |definition| summary_select_field(definition) }
  end

  def summary_select_field(definition)
    if definition.count?
      "COUNT(CASE WHEN name = '#{definition.raw_event_name}' THEN 1 END) as #{definition.summary_key}"
    else
      "AVG(CASE WHEN name = '#{definition.raw_event_name}' THEN #{average_value_key} END) as #{definition.summary_key}"
    end
  end

  def summary_attributes_for(record, conversations_count = 0)
    summary_metrics.each_with_object({ conversations_count: conversations_count.to_i }) do |definition, attributes|
      value = record&.public_send(definition.summary_key)
      attributes[definition.summary_key] = definition.count? ? value.to_i : value
    end
  end

  def summary_group_by_key
    {
      'account' => :account_id,
      'agent' => :user_id,
      'inbox' => :inbox_id,
      'team' => 'conversations.team_id'
    }[dimension_type]
  end

  def summary_conversation_group_by_key
    {
      'account' => :account_id,
      'agent' => :assignee_id,
      'inbox' => :inbox_id,
      'team' => :team_id
    }[dimension_type]
  end

  def summary_index_key
    summary_group_by_key.to_s.split('.').last
  end

  def average_value_key
    use_business_hours? ? :value_in_business_hours : :value
  end
end
