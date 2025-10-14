class V2::Reports::Conversations::BetterMetricBuilder < V2::Reports::Conversations::BaseReportBuilder
  COUNT_METRICS = %i[
    conversations_count
    incoming_messages_count
    outgoing_messages_count
    resolutions_count
    bot_resolutions_count
    bot_handoffs_count
  ].freeze

  AVERAGE_METRICS = %i[
    avg_first_response_time
    avg_resolution_time
    reply_time
  ].freeze

  SUMMARY_METRICS = %i[
    conversations_count
    outgoing_messages_count
    avg_first_response_time
    avg_resolution_time
    resolutions_count
    reply_time
  ].freeze

  BOT_SUMMARY_METRICS = %i[
    bot_resolutions_count
    bot_handoffs_count
  ].freeze

  AGGREGATOR_CLASSES = [
    V2::Reports::Conversations::ConversationsAggregator,
    V2::Reports::Conversations::MessagesAggregator,
    V2::Reports::Conversations::ReportingEventsAggregator
  ].freeze

  def summary
    result = SUMMARY_METRICS.index_with { |metric| fetch_metric(metric) }
    result[:incoming_messages_count] = fetch_metric(:incoming_messages_count) unless params[:type] == :agent
    result
  end

  def bot_summary
    BOT_SUMMARY_METRICS.index_with { |metric| fetch_metric(metric) }
  end

  private

  def fetch_metric(key)
    aggregated_metrics.fetch(key, default_for(key))
  end

  def aggregated_metrics
    @aggregated_metrics ||= AGGREGATOR_CLASSES.each_with_object({}) do |aggregator_class, memo|
      memo.merge!(aggregator_class.new(account, params).metrics) do |_metric, existing_value, new_value|
        new_value.nil? ? existing_value : new_value
      end
    end
  end

  def default_for(metric)
    return 0 if COUNT_METRICS.include?(metric)
    return nil if AVERAGE_METRICS.include?(metric)

    nil
  end
end
