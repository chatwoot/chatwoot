class DateDrop < Liquid::Drop
  def today
    Time.current.to_date
  end

  def now
    Time.current
  end

  def tomorrow
    (Time.current + 1.day).to_date
  end

  def yesterday
    (Time.current - 1.day).to_date
  end

  # Returns a date N days from today. Usage: {{ date.days_from_now | days: 7 }}
  def days_from_now(days = 0)
    return Time.current.to_date unless days.present?

    (Time.current + days.to_i.days).to_date
  end

  # Returns a date N days before today. Usage: {{ date.days_ago | days: 30 }}
  def days_ago(days = 0)
    return Time.current.to_date unless days.present?

    (Time.current - days.to_i.days).to_date
  end

  # Returns the current year/month/day as integers
  def current_year
    Time.current.year
  end

  def current_month
    Time.current.month
  end

  def current_day
    Time.current.day
  end
end
