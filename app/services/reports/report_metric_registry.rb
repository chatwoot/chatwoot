module Reports::ReportMetricRegistry
  # Describes one public report metric.
  # name: API-facing metric name requested by reports.
  # aggregate: whether the metric is a count or average.
  # raw_event_name: source reporting_events name for raw queries.
  # rollup_metric: source reporting_events_rollups metric for rollup queries.
  # summary_key: key used when this metric appears in grouped summary responses.
  # raw_count_strategy: optional raw-query counting rule, such as distinct conversations.
  Metric = Data.define(
    :name,
    :aggregate,
    :raw_event_name,
    :rollup_metric,
    :summary_key,
    :raw_count_strategy
  ) do
    def initialize(name:, aggregate:, raw_event_name: nil, rollup_metric: nil, summary_key: nil, raw_count_strategy: nil) # rubocop:disable Metrics/ParameterLists
      super
    end

    def average?
      aggregate == :average
    end

    def count?
      aggregate == :count
    end

    def rollup_supported?
      rollup_metric.present?
    end

    def summary?
      summary_key.present?
    end
  end

  METRICS = {
    conversations_count: Metric.new(
      name: :conversations_count,
      aggregate: :count
    ),
    incoming_messages_count: Metric.new(
      name: :incoming_messages_count,
      aggregate: :count
    ),
    outgoing_messages_count: Metric.new(
      name: :outgoing_messages_count,
      aggregate: :count
    ),
    avg_first_response_time: Metric.new(
      name: :avg_first_response_time,
      aggregate: :average,
      raw_event_name: :first_response,
      rollup_metric: :first_response,
      summary_key: :avg_first_response_time
    ),
    avg_resolution_time: Metric.new(
      name: :avg_resolution_time,
      aggregate: :average,
      raw_event_name: :conversation_resolved,
      rollup_metric: :resolution_time,
      summary_key: :avg_resolution_time
    ),
    reply_time: Metric.new(
      name: :reply_time,
      aggregate: :average,
      raw_event_name: :reply_time,
      rollup_metric: :reply_time,
      summary_key: :avg_reply_time
    ),
    resolutions_count: Metric.new(
      name: :resolutions_count,
      aggregate: :count,
      raw_event_name: :conversation_resolved,
      rollup_metric: :resolutions_count,
      summary_key: :resolved_conversations_count
    ),
    bot_resolutions_count: Metric.new(
      name: :bot_resolutions_count,
      aggregate: :count,
      raw_event_name: :conversation_bot_resolved,
      rollup_metric: :bot_resolutions_count
    ),
    bot_handoffs_count: Metric.new(
      name: :bot_handoffs_count,
      aggregate: :count,
      raw_event_name: :conversation_bot_handoff,
      rollup_metric: :bot_handoffs_count,
      raw_count_strategy: :distinct_conversation
    )
  }.freeze

  SUMMARY_METRIC_NAMES = %i[
    resolutions_count
    avg_resolution_time
    avg_first_response_time
    reply_time
  ].freeze

  module_function

  def fetch(name)
    return if name.blank?

    METRICS[name.to_sym]
  end

  def supported?(name)
    fetch(name).present?
  end

  def rollup_supported?(name)
    fetch(name)&.rollup_supported? || false
  end

  def summary_metrics
    SUMMARY_METRIC_NAMES.map { |metric_name| METRICS.fetch(metric_name) }
  end
end
