class V2::Reports::Timeseries::AverageReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def build
    grouped_average_time = reporting_events.average(average_value_key)
    grouped_event_count = reporting_events.count
    grouped_average_time.each_with_object([]) do |element, arr|
      event_date, average_time = element
      arr << {
        value: average_time,
        timestamp: event_date.to_time.to_i,
        count: grouped_event_count[event_date]
      }
    end
  end

  private

  def event_name
    metric_to_event_name = {
      avg_first_response_time: :first_response,
      avg_resolution_time: :conversation_resolved,
      reply_time: :reply_time
    }
    metric_to_event_name[params[:metric].to_sym]
  end

  def reporting_events
    object_scope = scope.reporting_events.where(name: event_name)
    @grouped_values = object_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      permit: %w[day week month year hour],
      time_zone: timezone
    )
  end

  def average_value_key
    @average_value_key ||= params[:business_hours].present? ? :value_in_business_hours : :value
  end
end
