module ReportingEventHelper
  def business_hours(inbox, from, to)
    return 0 unless inbox.working_hours_enabled?

    inbox_working_hours = configure_working_hours(inbox.working_hours)
    return 0 if inbox_working_hours.blank?

    # Configure working hours
    WorkingHours::Config.working_hours = inbox_working_hours

    # Configure timezone
    WorkingHours::Config.time_zone = inbox.timezone

    # Use inbox timezone to change from & to values.
    from_in_inbox_timezone = from.in_time_zone(inbox.timezone).to_time
    to_in_inbox_timezone = to.in_time_zone(inbox.timezone).to_time
    from_in_inbox_timezone.working_time_until(to_in_inbox_timezone)
  end

  def last_non_human_activity(conversation)
    # Try to get either a handoff or reopened event first
    # These will always take precedence over any other activity
    # Also, any of these events can happen at any time in the course of a conversation lifecycle.
    # So we pick the latest event
    event = ReportingEvent.where(
      conversation_id: conversation.id,
      name: %w[conversation_bot_handoff conversation_opened]
    ).order(event_end_time: :desc).first

    return event.event_end_time if event&.event_end_time

    # Fallback to bot resolved event
    # Because this will be closest to the most accurate activity instead of conversation.created_at
    bot_event = ReportingEvent.where(conversation_id: conversation.id, name: 'conversation_bot_resolved').last

    return bot_event.event_end_time if bot_event&.event_end_time

    # If no events found, return conversation creation time
    conversation.created_at
  end

  private

  def configure_working_hours(working_hours)
    working_hours.each_with_object({}) do |working_hour, object|
      object[day(working_hour.day_of_week)] = working_hour_range(working_hour) unless working_hour.closed_all_day?
    end
  end

  def day(day_of_week)
    week_days = {
      0 => :sun,
      1 => :mon,
      2 => :tue,
      3 => :wed,
      4 => :thu,
      5 => :fri,
      6 => :sat
    }
    week_days[day_of_week]
  end

  def working_hour_range(working_hour)
    { format_time(working_hour.open_hour, working_hour.open_minutes) => format_time(working_hour.close_hour, working_hour.close_minutes) }
  end

  def format_time(hour, minute)
    hour = hour < 10 ? "0#{hour}" : hour
    minute = minute < 10 ? "0#{minute}" : minute
    "#{hour}:#{minute}"
  end
end
