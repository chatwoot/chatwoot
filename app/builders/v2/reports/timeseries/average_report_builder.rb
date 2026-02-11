class V2::Reports::Timeseries::AverageReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def timeseries
    use_rollup? ? rollup_timeseries : raw_timeseries
  end

  def aggregate_value
    use_rollup? ? rollup_aggregate_value : raw_aggregate_value
  end

  private

  def raw_timeseries
    grouped_average_time = reporting_events.average(average_value_key)
    grouped_event_count = reporting_events.count
    grouped_average_time.each_with_object([]) do |element, arr|
      event_date, average_time = element
      arr << {
        value: average_time,
        timestamp: event_date.in_time_zone(timezone).to_i,
        count: grouped_event_count[event_date]
      }
    end
  end

  def rollup_timeseries
    dimension_type = dimension_type_to_rollup
    dimension_id = dimension_id_for_rollup
    metric = metric_to_rollup_metric(params[:metric])

    rollup_rows = ReportingEventRollup.where(
      account_id: account.id,
      metric: metric,
      dimension_type: dimension_type,
      dimension_id: dimension_id,
      date: range.first..range.last
    )

    group_and_aggregate_rollup(rollup_rows)
  end

  def raw_aggregate_value
    object_scope.average(average_value_key)
  end

  def rollup_aggregate_value
    dimension_type = dimension_type_to_rollup
    dimension_id = dimension_id_for_rollup
    metric = metric_to_rollup_metric(params[:metric])

    result = ReportingEventRollup.where(
      account_id: account.id,
      metric: metric,
      dimension_type: dimension_type,
      dimension_id: dimension_id,
      date: range.first..range.last
    ).pluck(Arel.sql('SUM(count), SUM(sum_value)'))
                                 .first

    return nil if result.blank? || result[0].to_i.zero?

    result[1].to_f / result[0].to_i
  end

  def dimension_id_for_rollup
    case params[:type].to_s
    when 'account'
      account.id
    when 'agent'
      params[:id].to_i
    when 'inbox'
      params[:id].to_i
    when 'team'
      params[:id].to_i
    end
  end

  def group_and_aggregate_rollup(rollup_rows)
    grouped_data = {}

    rollup_rows.each do |row|
      date_key = case group_by
                 when 'day'
                   row.date
                 when 'week'
                   row.date.beginning_of_week(:monday)
                 when 'month'
                   row.date.beginning_of_month
                 when 'year'
                   row.date.beginning_of_year
                 else
                   row.date
                 end

      grouped_data[date_key] ||= { count: 0, sum_value: 0.0 }
      grouped_data[date_key][:count] += row.count
      grouped_data[date_key][:sum_value] += row.sum_value
    end

    grouped_data.each_with_object([]) do |(date_key, data), arr|
      next if data[:count].zero?

      arr << {
        value: data[:sum_value] / data[:count],
        timestamp: date_key.in_time_zone(timezone).to_i,
        count: data[:count]
      }
    end.sort_by { |h| h[:timestamp] }
  end

  def event_name
    metric_to_event_name = {
      avg_first_response_time: :first_response,
      avg_resolution_time: :conversation_resolved,
      reply_time: :reply_time
    }
    metric_to_event_name[params[:metric].to_sym]
  end

  def object_scope
    scope.reporting_events.where(name: event_name, created_at: range, account_id: account.id)
  end

  def reporting_events
    @grouped_values = object_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: timezone
    )
  end

  def average_value_key
    @average_value_key ||= params[:business_hours].present? ? :value_in_business_hours : :value
  end
end
