class V2::Reports::Timeseries::CountReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def timeseries
    grouped_count.each_with_object([]) do |element, arr|
      event_date, event_count = element

      # The `event_date` is in Date format (without time), such as "Wed, 15 May 2024".
      # We need a timestamp for the start of the day. However, we can't use `event_date.to_time.to_i`
      # because it converts the date to 12:00 AM server timezone.
      # The desired output should be 12:00 AM in the specified timezone.
      arr << { value: event_count, timestamp: event_date.in_time_zone(timezone).to_i }
    end
  end

  def aggregate_value
    object_scope.count
  end

  private

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
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(
      name: :conversation_resolved,
      conversations: { status: :resolved }, created_at: range
    ).distinct
  end

  def scope_for_bot_resolutions_count
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(
      name: :conversation_bot_resolved,
      conversations: { status: :resolved }, created_at: range
    ).distinct
  end

  def scope_for_bot_handoffs_count
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(
      name: :conversation_bot_handoff,
      created_at: range
    ).distinct
  end

  def grouped_count
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
