# The reports pages count the last N days as today and the N - 1 days before it, in the account's reporting time zone,
# so "the last 7 days" in Copilot covers the same dates as the reports pages.
module Captain::Copilot::LastDays
  def self.dates(days, time_zone)
    today = Time.current.in_time_zone(time_zone).to_date
    [today - (days - 1), today]
  end
end
