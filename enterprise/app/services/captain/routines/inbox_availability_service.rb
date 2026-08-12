class Captain::Routines::InboxAvailabilityService
  pattr_initialize [:inbox!, :evaluated_at!]

  def perform
    local_time = evaluated_at.in_time_zone(inbox.timezone)

    {
      'working_hours_enabled' => inbox.working_hours_enabled?,
      'status' => availability_status(local_time),
      'timezone' => inbox.timezone,
      'evaluated_at' => evaluated_at.iso8601,
      'local_time' => local_time.iso8601,
      'schedule' => schedule(local_time)
    }
  end

  private

  def availability_status(local_time)
    return 'unrestricted' unless inbox.working_hours_enabled?

    available_at?(working_hour(local_time), local_time) ? 'within_business_hours' : 'outside_business_hours'
  end

  def schedule(local_time)
    return unless inbox.working_hours_enabled?

    working_hour = working_hour(local_time)
    {
      'day_of_week' => working_hour.day_of_week,
      'closed_all_day' => working_hour.closed_all_day?,
      'open_all_day' => working_hour.open_all_day?,
      'opens_at' => boundary_time(local_time, working_hour.open_hour, working_hour.open_minutes),
      'closes_at' => boundary_time(local_time, working_hour.close_hour, working_hour.close_minutes)
    }
  end

  def available_at?(working_hour, local_time)
    return false if working_hour.closed_all_day?
    return true if working_hour.open_all_day?

    local_time.between?(
      local_time.change(hour: working_hour.open_hour, min: working_hour.open_minutes, sec: 0),
      local_time.change(hour: working_hour.close_hour, min: working_hour.close_minutes, sec: 0)
    )
  end

  def boundary_time(local_time, hour, minutes)
    return if hour.nil? || minutes.nil?

    local_time.change(hour: hour, min: minutes, sec: 0).iso8601
  end

  def working_hour(local_time)
    @working_hour ||= inbox.working_hours.find_by!(day_of_week: local_time.wday)
  end
end
