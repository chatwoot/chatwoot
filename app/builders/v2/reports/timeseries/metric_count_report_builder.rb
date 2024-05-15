class V2::Reports::Timeseries::MetricCountReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def build
    grouped_count.each_with_object([]) do |element, arr|
      event_date, event_count = element
      arr << { value: event_count, timestamp: event_date.to_time.to_i }
    end
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
