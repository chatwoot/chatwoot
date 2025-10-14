class V2::Reports::Conversations::ReportingEventsAggregator < V2::Reports::Conversations::BaseAggregator
  COUNT_MAPPINGS = {
    resolutions_count: :conversation_resolved,
    bot_resolutions_count: :conversation_bot_resolved,
    bot_handoffs_count: :conversation_bot_handoff
  }.freeze

  AVERAGE_MAPPINGS = {
    avg_first_response_time: :first_response,
    avg_resolution_time: :conversation_resolved,
    reply_time: :reply_time
  }.freeze

  private

  def compute_metrics
    row = base_relation.pluck(*select_fragments).first || default_row

    counts_hash(row.first(COUNT_MAPPINGS.size)).merge(averages_hash(row.last(AVERAGE_MAPPINGS.size)))
  end

  def counts_hash(values)
    COUNT_MAPPINGS.keys.zip(values).to_h.transform_values { |value| value || 0 }
  end

  def averages_hash(values)
    AVERAGE_MAPPINGS.keys.zip(values).to_h
  end

  def select_fragments
    COUNT_MAPPINGS.map { |_metric, event_name| count_fragment(event_name) } +
      AVERAGE_MAPPINGS.map { |_metric, event_name| average_fragment(event_name) }
  end

  def count_fragment(event_name)
    if event_name == :conversation_bot_handoff
      Arel.sql("COUNT(DISTINCT CASE WHEN name = '#{event_name}' THEN conversation_id END)")
    else
      Arel.sql("COUNT(*) FILTER (WHERE name = '#{event_name}')")
    end
  end

  def average_fragment(event_name)
    Arel.sql("AVG(CASE WHEN name = '#{event_name}' THEN #{value_column} END)")
  end

  def base_relation
    scope.reporting_events
         .where(account_id: account.id, created_at: range)
         .unscope(:order)
         .reorder(nil)
  end

  def value_column
    params[:business_hours].present? ? 'value_in_business_hours' : 'value'
  end

  def default_row
    Array.new(COUNT_MAPPINGS.size, 0) + Array.new(AVERAGE_MAPPINGS.size)
  end
end
