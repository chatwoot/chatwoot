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
    result = base_relation.select(*select_fragments).first
    return default_metrics unless result

    COUNT_MAPPINGS.keys.index_with { |key| result.public_send(key) || 0 }
                  .merge(AVERAGE_MAPPINGS.keys.index_with { |key| result.public_send(key) })
  end

  def select_fragments
    COUNT_MAPPINGS.map { |metric, event_name| "#{count_fragment(event_name)} AS #{metric}" } +
      AVERAGE_MAPPINGS.map { |metric, event_name| "#{average_fragment(event_name)} AS #{metric}" }
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

  def default_metrics
    COUNT_MAPPINGS.keys.index_with { 0 }
                  .merge(AVERAGE_MAPPINGS.keys.index_with { nil })
  end
end
