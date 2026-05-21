module ReportingEvents::EventMetricRegistry
  # Describes one rollup metric emitted by a raw reporting event.
  # rollup_metric: metric name stored in reporting_events_rollups.
  # payload_kind: whether the emitted row carries only a count or a duration payload.
  Metric = Data.define(:rollup_metric, :payload_kind)

  EVENTS = {
    conversation_resolved: [
      Metric.new(rollup_metric: :resolutions_count, payload_kind: :count),
      Metric.new(rollup_metric: :resolution_time, payload_kind: :duration)
    ].freeze,
    first_response: [
      Metric.new(rollup_metric: :first_response, payload_kind: :duration)
    ].freeze,
    reply_time: [
      Metric.new(rollup_metric: :reply_time, payload_kind: :duration)
    ].freeze,
    conversation_bot_resolved: [
      Metric.new(rollup_metric: :bot_resolutions_count, payload_kind: :count)
    ].freeze,
    conversation_bot_handoff: [
      Metric.new(rollup_metric: :bot_handoffs_count, payload_kind: :count)
    ].freeze
  }.freeze

  module_function

  def event_names
    EVENTS.keys.map(&:to_s)
  end

  def metrics_for(event)
    return {} if event.blank?

    metrics_for_aggregate(
      event.name,
      count: 1,
      sum_value: event.try(:value),
      sum_value_business_hours: event.try(:value_in_business_hours)
    )
  end

  def metrics_for_aggregate(event_name, count:, sum_value:, sum_value_business_hours:)
    return {} if event_name.blank?

    values = {
      count: count.to_i,
      sum_value: sum_value.to_f,
      sum_value_business_hours: sum_value_business_hours.to_f
    }

    EVENTS.fetch(event_name.to_sym, []).to_h do |metric|
      [metric.rollup_metric, metric_values(metric.payload_kind, values)]
    end
  end

  private_class_method def metric_values(payload_kind, values)
    case payload_kind
    when :count
      count_values(values[:count])
    when :duration
      duration_values(values)
    else
      raise ArgumentError, "Unknown metric payload kind: #{payload_kind.inspect}"
    end
  end

  private_class_method def count_values(count)
    { count: count, sum_value: 0, sum_value_business_hours: 0 }
  end

  private_class_method def duration_values(values)
    {
      count: values[:count],
      sum_value: values[:sum_value],
      sum_value_business_hours: values[:sum_value_business_hours]
    }
  end
end
