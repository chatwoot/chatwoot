# Liquid date helpers for automation CA updates and message templates.
#
# Relative dates (CRM): prefer filters in config/initializers/liquid_filters.rb —
#   {{ date.today }}                 → today (ISO YYYY-MM-DD via to_s)
#   {{ date.today | plus_days: 7 }}  → today + N
#   {{ date.today | minus_days: 30 }} → today - N
# ActionService renders these through MessageRendererService before parsing date CAs.
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

  # Bare {{ date.days_from_now }} → today. Liquid cannot pass Ruby args here;
  # use {{ date.today | plus_days: N }} instead (see class comment).
  def days_from_now
    Time.current.to_date
  end

  # Bare {{ date.days_ago }} → today. Use {{ date.today | minus_days: N }} instead.
  def days_ago
    Time.current.to_date
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
