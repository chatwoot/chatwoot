module ReportingEventHelper
  def business_hours(inbox, from, to)
    return 0 unless inbox.working_hours_enabled?

    inbox_working_hours = configure_working_hours(inbox.working_hours)
    return 0 if inbox_working_hours.blank?

    BusinessTime::Config.work_hours = inbox_working_hours

    from_in_timezone = Time.zone.parse(from.to_s).to_time
    to_in_timezone = Time.zone.parse(to.to_s).to_time
    from_in_timezone.business_time_until(to_in_timezone)
  end

  private

  def configure_working_hours(working_hours)
    working_hours.each_with_object({}) do |working_hour, object|
      object[day(working_hour.day_of_week)] = working_hour_range(working_hour) unless working_hour.closed_all_day?
    end
  end

  def day(day_of_week)
    week_days = {
      0 => 'sun',
      1 => 'mon',
      2 => 'tue',
      3 => 'wed',
      4 => 'thu',
      5 => 'fri',
      6 => 'sat'
    }
    week_days[day_of_week]
  end

  def working_hour_range(working_hour)
    [format_time(working_hour.open_hour, working_hour.open_minutes), format_time(working_hour.close_hour, working_hour.close_minutes)]
  end

  def format_time(hour, minute)
    "#{hour}:#{minute}"
  end
end
