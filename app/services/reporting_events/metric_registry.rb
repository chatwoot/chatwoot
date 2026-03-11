# Raw reporting events and rollup rows do not share a single metric namespace.
# For example, the raw `conversation_resolved` event emits both the
# `resolutions_count` and `resolution_time` rollup metrics. This registry keeps
# that mapping in one place so the write path, rollup reads, and raw reads stay
# aligned.
module ReportingEvents::MetricRegistry
  EVENT_METRICS = {
    'conversation_resolved' => lambda do |event|
      {
        resolutions_count: count_metric,
        resolution_time: duration_metric(event)
      }
    end,
    'first_response' => ->(event) { { first_response: duration_metric(event) } },
    'reply_time' => ->(event) { { reply_time: duration_metric(event) } },
    'conversation_bot_resolved' => ->(_event) { { bot_resolutions_count: count_metric } },
    'conversation_bot_handoff' => ->(_event) { { bot_handoffs_count: count_metric } }
  }.freeze

  REPORT_METRICS = {
    conversations_count: {
      aggregate: :count
    }.freeze,
    incoming_messages_count: {
      aggregate: :count
    }.freeze,
    outgoing_messages_count: {
      aggregate: :count
    }.freeze,
    avg_first_response_time: {
      raw_event_name: :first_response,
      rollup_metric: :first_response,
      aggregate: :average
    }.freeze,
    avg_resolution_time: {
      raw_event_name: :conversation_resolved,
      rollup_metric: :resolution_time,
      aggregate: :average
    }.freeze,
    reply_time: {
      raw_event_name: :reply_time,
      rollup_metric: :reply_time,
      aggregate: :average
    }.freeze,
    resolutions_count: {
      raw_event_name: :conversation_resolved,
      rollup_metric: :resolutions_count,
      aggregate: :count
    }.freeze,
    bot_resolutions_count: {
      raw_event_name: :conversation_bot_resolved,
      rollup_metric: :bot_resolutions_count,
      aggregate: :count
    }.freeze,
    bot_handoffs_count: {
      raw_event_name: :conversation_bot_handoff,
      rollup_metric: :bot_handoffs_count,
      aggregate: :count,
      raw_count_strategy: :distinct_conversation
    }.freeze
  }.freeze

  module_function

  def event_metrics_for(event)
    return {} if event.blank?

    EVENT_METRICS[event.name.to_s]&.call(event) || {}
  end

  def report_metric(metric)
    return if metric.blank?

    REPORT_METRICS[metric.to_sym]
  end

  def supported_metric?(metric)
    report_metric(metric).present?
  end

  def aggregate_for(metric)
    report_metric(metric)&.dig(:aggregate)
  end

  def rollup_supported_metric?(metric)
    rollup_metric_for(metric).present?
  end

  def rollup_metric_for(metric)
    report_metric(metric)&.dig(:rollup_metric)
  end

  def raw_event_name_for(metric)
    report_metric(metric)&.dig(:raw_event_name)
  end

  def count_metric
    { count: 1, sum_value: 0, sum_value_business_hours: 0 }
  end
  private_class_method :count_metric

  def duration_metric(event)
    {
      count: 1,
      sum_value: event.value.to_f,
      sum_value_business_hours: event.value_in_business_hours.to_f
    }
  end
  private_class_method :duration_metric
end
