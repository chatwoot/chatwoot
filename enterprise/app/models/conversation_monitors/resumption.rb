class ConversationMonitors::Resumption < ApplicationRecord
  self.table_name = 'conversation_monitor_resumptions'

  belongs_to :monitor, class_name: 'ConversationMonitors::Monitor'
  validates :mode, inclusion: { in: %w[catch_up from_now] }
  validates :started_at, :ended_at, :collection_version, presence: true
  scope :pending, -> { where(mode: 'catch_up', enumerated_at: nil, cancelled_at: nil) }
  scope :incomplete, -> { where(mode: 'from_now').or(where.not(cancelled_at: nil)) }

  def population
    range = started_at...ended_at
    conversations = monitor.account.conversations
    messages = monitor.account.messages.where(message_type: :incoming, private: false, created_at: range).select(:conversation_id)
    conversations.where(created_at: range).or(conversations.where(id: messages))
  end

  def collecting?
    monitor.collecting? && collection_version == monitor.collection_version
  end
end
