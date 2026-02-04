class Captain::Tools::BusinessHoursLookupTool < Captain::Tools::BasePublicTool
  description 'Get business working hours and current open/closed status for the account'

  def perform(_tool_context)
    log_tool_usage('fetching_business_hours')

    account = Account.find(@assistant.account_id)

    unless account.business_hours_enabled
      log_tool_usage('business_hours_not_configured')
      return 'Business hours are not configured for this account.'
    end

    format_business_hours(account)
  end

  private

  def format_business_hours(account)
    timezone = account.business_hours_timezone || 'UTC'
    current_time = Time.current.in_time_zone(timezone)
    is_open = account.business_hours_open?
    schedule = account.business_hours_schedule

    log_tool_usage('business_hours_found', {
      timezone: timezone,
      is_open: is_open,
      schedule_days: schedule.size
    })

    result = []
    result << "Business Hours Information"
    result << "=========================="
    result << ""
    result << "Timezone: #{timezone}"
    result << "Current Time: #{current_time.strftime('%A, %B %d, %Y at %I:%M %p')}"
    result << "Status: #{is_open ? 'OPEN' : 'CLOSED'}"
    result << ""
    result << "Weekly Schedule:"
    result << format_schedule(schedule)

    result.join("\n")
  end

  def format_schedule(schedule)
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

    schedule.map do |day|
      day_name = day_names[day[:day_of_week]]
      hours = format_day_hours(day)
      "  #{day_name}: #{hours}"
    end.join("\n")
  end

  def format_day_hours(day)
    return 'Closed' if day[:closed_all_day]
    return 'Open 24 hours' if day[:open_all_day]

    open_time = format_time(day[:open_hour], day[:open_minutes])
    close_time = format_time(day[:close_hour], day[:close_minutes])

    "#{open_time} - #{close_time}"
  end

  def format_time(hour, minutes)
    return 'N/A' if hour.nil?

    period = hour >= 12 ? 'PM' : 'AM'
    display_hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
    format('%d:%02d %s', display_hour, minutes || 0, period)
  end
end
