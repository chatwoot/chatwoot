##############################################
# Helpers to implement date range filtering to APIs
# Include in your controller or service class where params is available
##############################################

module DateRangeHelper
  def range
    return if params[:since].blank? || params[:until].blank?

    parse_date_time(params[:since])...parse_date_time(params[:until])
  end

  def parse_date_time(datetime)
    return datetime if datetime.is_a?(DateTime)
    return datetime.to_datetime if datetime.is_a?(Time) || datetime.is_a?(Date)

    DateTime.strptime(datetime, '%s')
  end

  def process_custom_time_range(time_period)
    case time_period[:type]
    when 'dynamic'
      calculate_dynamic_range(time_period[:value], time_period[:unit])
    when 'custom'
      parse_date_time(time_period[:start_date].to_s)...parse_date_time(time_period[:end_date].to_s)
    end
  end

  def calculate_dynamic_time_range(value, unit)
    end_date = Time.current
    start_date = case unit
                 when 'day'
                   value.days.ago
                 when 'week'
                   value.weeks.ago
                 when 'month'
                   value.months.ago
                 when 'year'
                   value.years.ago
                 end

    start_date...end_date
  end
end
