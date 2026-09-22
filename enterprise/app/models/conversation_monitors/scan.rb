class ConversationMonitors::Scan < ApplicationRecord
  self.table_name = 'conversation_monitor_scans'

  belongs_to :monitor, class_name: 'ConversationMonitors::Monitor', inverse_of: :scans
  validates :kind, inclusion: { in: %w[initial catch_up from_now] }
  validates :started_at, :ended_at, :collection_version, presence: true
  scope :pending, -> { where(enumerated_at: nil, cancelled_at: nil).where.not(kind: 'from_now') }

  def population
    conversations = monitor.account.conversations
    range = started_at...ended_at
    return conversations.where(created_at: range) if kind == 'initial'

    messages = monitor.account.messages.where(message_type: [:incoming, :outgoing], private: false, created_at: range).select(:conversation_id)
    conversations.where(created_at: range).or(conversations.where(id: messages))
  end

  def collecting?
    kind != 'from_now' && !cancelled_at && monitor.collecting? && collection_version == monitor.collection_version
  end

  def incomplete?
    kind == 'from_now' || cancelled_at.present? || enumerated_at.nil?
  end

  def affects_range?(range)
    ended_at > range.begin && (kind != 'initial' || started_at < range.end)
  end
end
