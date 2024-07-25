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

  def periods_in_range_for_group_by(group_by, start_date, end_date)
    case group_by
    when 'day'
      (start_date..end_date).to_a
    when 'year'
      (start_date.year..end_date.year).map { |year| Date.new(year, 1, 1) }
    else # month
      (start_date..end_date).select { |d| d.day == 1 }
    end
  end

  def period_label_for_group_by(group_by, period_start)
    case group_by
    when 'day'
      period_start.strftime('%d %B %Y')
    when 'year'
      period_start.year.to_s
    else # month
      period_start.strftime('%B %Y')
    end
  end

  def period_end_for_group_by(group_by, period_start)
    case group_by
    when 'day'
      period_start.end_of_day
    when 'year'
      period_start.end_of_year
    else # month
      period_start.end_of_month
    end
  end
end
