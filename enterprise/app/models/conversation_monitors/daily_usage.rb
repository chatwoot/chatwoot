class ConversationMonitors::DailyUsage < ApplicationRecord
  self.table_name = 'conversation_monitor_daily_usages'

  belongs_to :account

  validates :usage_date, presence: true, uniqueness: { scope: :account_id }
  validates :calls_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.monthly_snapshot(account_id, now = Time.current.utc)
    first_day = now.to_date.beginning_of_month
    resets_at = now.beginning_of_month.next_month
    records = where(account_id: account_id, usage_date: first_day...resets_at.to_date)
              .order(:usage_date).pluck(:usage_date, :calls_count, :limit_reached_at)
    used = records.sum { |(_, count, _)| count }
    limit = ConversationMonitors::Configuration::MONTHLY_CALL_LIMIT
    counts = records.to_h { |date, count, _| [date, count] }
    {
      limit: limit, used: used, remaining: [limit - used, 0].max, limit_reached: used >= limit,
      limit_reached_at: records.filter_map(&:last).min&.to_i, resets_at: resets_at.to_i,
      period_start: first_day.iso8601, timezone: 'UTC',
      daily: (first_day..now.to_date).map { |date| { date: date.iso8601, calls: counts.fetch(date, 0) } }
    }
  end

  # Usage#reserve! holds the account lock across the monthly check and this write.
  def self.record_call!(account_id, at:, limit_reached:)
    daily = find_or_initialize_by(account_id: account_id, usage_date: at.to_date)
    daily.calls_count += 1
    daily.limit_reached_at = at if limit_reached
    daily.save!
  end
end
