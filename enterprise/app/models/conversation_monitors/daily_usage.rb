class ConversationMonitors::DailyUsage < ApplicationRecord
  self.table_name = 'conversation_monitor_daily_usages'

  belongs_to :account

  validates :usage_date, presence: true, uniqueness: { scope: :account_id }
  validates :calls_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
