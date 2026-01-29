class Sla::BusinessHoursService
  pattr_initialize [:inbox!, :start_time!, :threshold_seconds!]

  def deadline
    return start_time + threshold_seconds.seconds unless should_apply_business_hours?

    calculate_deadline_with_business_hours
  end

  private

  def should_apply_business_hours?
    inbox.working_hours_enabled? && open_days?
  end

  def open_days?
    inbox.working_hours.exists?(closed_all_day: false)
  end

  def calculate_deadline_with_business_hours
    @remaining_seconds = threshold_seconds.to_i
    @current_time = start_time.in_time_zone(timezone)

    process_remaining_seconds while @remaining_seconds.positive?

    @current_time
  end

  def process_remaining_seconds
    working_hour = working_hour_for(@current_time)

    if closed_day?(working_hour)
      @current_time = next_business_day_start(@current_time)
      return
    end

    adjust_current_time_to_business_hours(working_hour)
    consume_available_seconds(working_hour)
  end

  def closed_day?(working_hour)
    working_hour.nil? || working_hour.closed_all_day?
  end

  def adjust_current_time_to_business_hours(working_hour)
    day_open_time = time_on_date(@current_time, working_hour.open_hour, working_hour.open_minutes)
    day_close_time = time_on_date(@current_time, working_hour.close_hour, working_hour.close_minutes)

    if @current_time < day_open_time
      @current_time = day_open_time
    elsif @current_time >= day_close_time
      @current_time = next_business_day_start(@current_time)
    end
  end

  def consume_available_seconds(working_hour)
    day_close_time = time_on_date(@current_time, working_hour.close_hour, working_hour.close_minutes)
    available_seconds = (day_close_time - @current_time).to_i

    if @remaining_seconds <= available_seconds
      @current_time += @remaining_seconds.seconds
      @remaining_seconds = 0
    else
      @remaining_seconds -= available_seconds
      @current_time = next_business_day_start(@current_time)
    end
  end

  def working_hour_for(time)
    inbox.working_hours.find_by(day_of_week: time.wday)
  end

  def next_business_day_start(current_time)
    next_day = (current_time + 1.day).beginning_of_day
    7.times do
      working_hour = working_hour_for(next_day)
      return time_on_date(next_day, working_hour.open_hour, working_hour.open_minutes) if working_hour && !working_hour.closed_all_day?

      next_day += 1.day
    end
    next_day
  end

  def time_on_date(date, hour, minutes)
    date.change(hour: hour, min: minutes, sec: 0)
  end

  def timezone
    inbox.timezone || 'UTC'
  end
end
