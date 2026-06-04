class RecurringScheduledMessages::RecurrenceCalculatorService
  def initialize(recurrence_rule:, last_date:)
    @rule = recurrence_rule.with_indifferent_access
    @last_date = last_date
    @frequency = @rule[:frequency]
    @interval = @rule[:interval] || 1
  end

  def next_date
    date = calculate_next_date
    return nil if date.nil?

    preserve_time(date)
  end

  private

  def calculate_next_date
    case @frequency
    when 'daily' then calculate_daily
    when 'weekly' then calculate_weekly
    when 'monthly' then calculate_monthly
    when 'yearly' then calculate_yearly
    end
  end

  def calculate_daily
    @last_date + @interval.days
  end

  def calculate_weekly
    return nil if @rule[:week_days].blank?

    week_days = @rule[:week_days].sort
    current_wday = @last_date.wday
    next_day = week_days.find { |d| d > current_wday }

    if next_day
      @last_date + (next_day - current_wday).days
    else
      days_until_first = (7 - current_wday + week_days.first) + ((@interval - 1) * 7)
      @last_date + days_until_first.days
    end
  end

  def calculate_monthly
    if @rule[:monthly_type] == 'day_of_week'
      calculate_monthly_day_of_week
    else
      calculate_monthly_day_of_month
    end
  end

  def calculate_monthly_day_of_month
    target = @last_date.advance(months: @interval)
    day = @rule[:month_day] || @last_date.day
    last_day = Time.days_in_month(target.month, target.year)
    target.change(day: [day, last_day].min)
  end

  def calculate_monthly_day_of_week
    monthly_week = @rule[:monthly_week]
    monthly_weekday = @rule[:monthly_weekday]

    target_month = @last_date.advance(months: @interval)
    find_nth_weekday_in_month(target_month.year, target_month.month, monthly_weekday, monthly_week)
  end

  def find_nth_weekday_in_month(year, month, weekday, week_number)
    if week_number == -1
      find_last_weekday_in_month(year, month, weekday)
    else
      first_day = Date.new(year, month, 1)
      first_occurrence = first_day + ((weekday - first_day.wday + 7) % 7)
      result = first_occurrence + ((week_number - 1) * 7)

      # If nth occurrence doesn't exist in month, use last occurrence
      if result.month == month
        result.to_time(:utc)
      else
        find_last_weekday_in_month(year, month, weekday)
      end
    end
  end

  def find_last_weekday_in_month(year, month, weekday)
    last_day = Date.new(year, month, -1)
    offset = (last_day.wday - weekday + 7) % 7
    (last_day - offset).to_time(:utc)
  end

  def calculate_yearly
    year_month = @rule[:year_month] || @last_date.month
    year_day = @rule[:year_day] || @last_date.day

    target = @last_date.advance(years: @interval)

    if year_month == 2 && year_day == 29
      target.change(day: Date.leap?(target.year) ? 29 : 28)
    else
      last_day = Time.days_in_month(target.month, target.year)
      target.change(day: [year_day, last_day].min)
    end
  end

  def preserve_time(date)
    date.change(hour: @last_date.hour, min: @last_date.min, sec: @last_date.sec)
  end
end
