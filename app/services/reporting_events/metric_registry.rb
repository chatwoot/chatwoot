# Raw reporting events and rollup rows do not share a single metric namespace.
# This registry keeps the mapping aligned across write and read paths.
module ReportingEvents::MetricRegistry
  EVENT_METRICS = {
    'conversation_resolved' => lambda do |values|
      {
        resolutions_count: count_metric(values[:count]),
        resolution_time: duration_metric(values)
      }
    end,
    'first_response' => ->(values) { { first_response: duration_metric(values) } },
    'reply_time' => ->(values) { { reply_time: duration_metric(values) } },
    'conversation_bot_resolved' => ->(values) { { bot_resolutions_count: count_metric(values[:count]) } },
    'conversation_bot_handoff' => ->(values) { { bot_handoffs_count: count_metric(values[:count]) } }
  }.freeze

  REPORT_METRICS = {
    conversations_count: { aggregate: :count }.freeze,
    incoming_messages_count: { aggregate: :count }.freeze,
    outgoing_messages_count: { aggregate: :count }.freeze,
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
    return {} unless EVENT_METRICS.key?(event.name.to_s)

    event_metrics_for_aggregate(
      event.name,
      count: 1,
      sum_value: event.try(:value),
      sum_value_business_hours: event.try(:value_in_business_hours)
    )
  end

  def event_metrics_for_aggregate(event_name, count:, sum_value:, sum_value_business_hours:)
    values = {
      count: count.to_i,
      sum_value: sum_value.to_f,
      sum_value_business_hours: sum_value_business_hours.to_f
    }

    EVENT_METRICS[event_name.to_s]&.call(values) || {}
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

  def count_metric(count)
    { count: count, sum_value: 0, sum_value_business_hours: 0 }
  end
  private_class_method :count_metric

  def duration_metric(values)
    {
      count: values[:count],
      sum_value: values[:sum_value],
      sum_value_business_hours: values[:sum_value_business_hours]
    }
  end
  private_class_method :duration_metric
end
