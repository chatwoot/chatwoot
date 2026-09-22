class ConversationMonitors::Backfill < ApplicationRecord
  self.table_name = 'conversation_monitor_backfills'

  belongs_to :monitor, class_name: 'ConversationMonitors::Monitor', inverse_of: :backfill

  def population
    monitor.account.conversations.where(created_at: monitor.history_since...monitor.created_at)
  end
end
