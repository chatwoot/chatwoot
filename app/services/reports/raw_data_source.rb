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

    merge_summary_results(metric_results, summary_conversation_counts, summary_handled_counts)
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

  def count_scope # rubocop:disable Metrics/AbcSize
    case metric.to_s
    when 'conversations_count'
      scope.conversations.where(account_id: account.id, created_at: range)
    when 'incoming_messages_count'
      scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
    when 'outgoing_messages_count'
      scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
    when Reports::HandledConversations::METRIC
      handled_count_scope
    else
      reporting_event_count_scope
    end
  end

  def handled_count_scope
    Reports::HandledConversations.distinct_conversations(scope.messages.where(account_id: account.id, created_at: range))
  end

  def reporting_event_count_scope
    events = scope.reporting_events.where(
      name: raw_event_name,
      account_id: account.id,
      created_at: range
    )

    return events.where.not(conversation_id: bot_handoff_conversation_ids_subquery) if raw_count_strategy == :exclude_bot_handoffs
    return events unless raw_count_strategy == :distinct_conversation

    events.joins(:conversation).select(:conversation_id).distinct
  end

  def bot_handoff_conversation_ids_subquery
    scope.reporting_events.where(
      name: :conversation_bot_handoff,
      account_id: account.id,
      created_at: range
    ).where.not(conversation_id: nil).select(:conversation_id)
  end

  def summary_scope
    scope = account.reporting_events.where(created_at: range)
    scope = scope.joins(:conversation) if dimension_type == 'team'

    apply_event_filters(scope)
  end

  def summary_conversation_counts
    apply_conversation_filters(account.conversations.where(created_at: range))
      .group(summary_conversation_group_by_key)
      .count
  end

  def summary_handled_counts
    Reports::HandledConversations.summary_counts(account: account, dimension_type: dimension_type, range: range, filters: filters)
  end

  # Narrows a summary to a second dimension, so a report grouped by agent can be
  # read for a single inbox and the other way around.
  def apply_event_filters(events)
    events = events.where(inbox_id: filters[:inbox_id]) if filters[:inbox_id].present?
    events = events.where(user_id: filters[:user_id]) if filters[:user_id].present?
    events
  end

  def apply_conversation_filters(conversations)
    conversations = conversations.where(inbox_id: filters[:inbox_id]) if filters[:inbox_id].present?
    conversations = conversations.where(assignee_id: filters[:user_id]) if filters[:user_id].present?
    conversations
  end

  def merge_summary_results(metric_results, conversation_counts, handled_counts)
    (metric_results.keys | conversation_counts.keys | handled_counts.keys).each_with_object({}) do |dimension_id, results|
      record = metric_results[dimension_id]
      results[dimension_id] = summary_attributes_for(record, conversation_counts[dimension_id])
                              .merge(handled_conversations_count: handled_counts[dimension_id].to_i)
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
